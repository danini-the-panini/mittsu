require 'opengl'
require 'glfw'
require 'fiddle'

OpenGL.load_lib

require 'mittsu'
require 'mittsu/renderers/glfw_window'
require 'mittsu/renderers/opengl/opengl_debug'
require 'mittsu/renderers/opengl/opengl_program'
require 'mittsu/renderers/opengl/opengl_state'
require 'mittsu/renderers/opengl/plugins/shadow_map_plugin'
require 'mittsu/renderers/opengl/object_renderers/mesh_opengl_renderer'
require 'mittsu/renderers/opengl/object_renderers/line_opengl_renderer'
require 'mittsu/renderers/shaders/shader_lib'
require 'mittsu/renderers/shaders/uniforms_utils'

include ENV['DEBUG'] ? OpenGLDebug : OpenGL

module Mittsu
  class OpenGLRenderer
    attr_accessor :auto_clear, :auto_clear_color, :auto_clear_depth, :auto_clear_stencil, :sort_objects, :gamma_factor, :gamma_input, :gamma_output, :shadow_map_enabled, :shadow_map_type, :shadow_map_cull_face, :shadow_map_debug, :shadow_map_cascade, :max_morph_targets, :max_morph_normals, :info, :pixel_ratio, :window, :width, :height, :state

    def initialize(parameters = {})
      puts "OpenGLRenderer (Revision #{REVISION})"

      @pixel_ratio = 1.0

      @_alpha = parameters.fetch(:alpha, false)
      @_depth = parameters.fetch(:depth, true)
      @_stencil = parameters.fetch(:stencil, true)
      @_antialias = parameters.fetch(:antialias, false)
      @_premultiplied_alpha = parameters.fetch(:premultiplied_alpha, true)
      @_preserve_drawing_buffer = parameters.fetch(:preserve_drawing_buffer, false)
      @_logarithmic_depth_buffer = parameters.fetch(:logarithmic_depth_buffer, false)

      @_clear_color = Color.new(0x000000)
      @_clear_alpha = 0.0

      @width = parameters.fetch(:width, 800)
      @height = parameters.fetch(:height, 600)
      @title = parameters.fetch(:title, "Mittsu #{REVISION}")

      @lights = []

      @_opengl_objects = {}
      @_opengl_objects_immediate = []

      @opaque_objects = []
      @transparent_objects = []

      @sprites = []
      @lens_flares = []

      # public properties

      # @dom_element = _canvas
      # @context = nil

      # clearing

      @auto_clear = true
      @auto_clear_color = true
      @auto_clear_depth = true
      @auto_clear_stencil = true

      # scene graph

      @sort_objects = true

      # physically based shading

      @gamma_factor = 2.0 # backwards compat???
      @gamma_input = false
      @gamma_output = false

      # shadow map

      @shadow_map_enabled = false
      @shadow_map_type = PCFShadowMap
      @shadow_map_cull_face = CullFaceFront
      @shadow_map_debug = false
      @shadow_map_cascade = false

      # morphs

      @max_morph_targets = 8
      @max_morph_normals = 4

      # info

      @info = {
        memory: {
          programs: 0,
          geometries: 0,
          textures: 0
        },
        render: {
          calls: 0,
          vertices: 0,
          faces: 0,
          points: 0
        }
      }

      # internal properties

      @_programs = []

      # internal state cache

      @_current_program = nil
      @_current_framebuffer = nil
      @_current_material_id = -1
      @_current_geometry_program = ''
      @_current_camera = nil

      @_used_texture_units = 0
      @_viewport_x = 0
      @_viewport_y = 0
      @_current_width = 0
      @_current_height = 0

      # frustum

      @_frustum = Frustum.new

      # camera matrices cache

      @_proj_screen_matrix = Matrix4.new
      @_vector3 = Vector3.new

      # light arrays cache

      @_direction = Vector3.new
      @_lights_need_update = true
      # TODO: re-imagine this thing as a bunch of classes...
      @_lights = {
        ambient: [0, 0, 0],
        directional: { length: 0, colors: [], positions: [] },
        point: { length: 0, colors: [], positions: [], distances: [], decays: [] },
        spot: { length: 0, colors: [], positions: [], distances: [], directions: [], angles_cos: [], exponents: [], decays: [] },
        hemi: { length: 0, sky_colors: [], ground_colors: [], positions: []}
      }

      @geometry_groups = {}
      @geometry_group_counter = 0

      @shader_ids = {
        # MeshDepthMaterial => :depth, # TODO...
        # MeshNormalMaterial => :normal, # TODO...
        MeshBasicMaterial => :basic,
        MeshLambertMaterial => :lambert,
        MeshPhongMaterial => :phong,
        LineBasicMaterial => :basic,
        # LineDashedMaterial => :dashed, # TODO...
        # PointCloudMaterial => :particle_basic # TODO...
      }

      # initialize

      begin
        # attributes = {
        #   alpha: _alpha,
        #   depth: _depth,
        #   stencil: _stencil,
        #   antialias: _antialias,
        #   premultiplied_alpha: _premultiplied_alpha,
        #   preserve_drawing_buffer: _preserve_drawing_buffer
        # }

        @window = GLFW::Window.new(@width, @height, @title)

        @_viewport_width, @_viewport_height = *(@window.framebuffer_size)

        # TODO: handle losing opengl context??
      rescue => error
        puts "ERROR: Mittsu::OpenGLRenderer: #{error.inspect}"
      end

      @state = OpenGLState.new(self.method(:param_mittsu_to_gl))

      # TODO: load extensions??

      reset_gl_state
      set_default_gl_state

      # GPU capabilities

      @_max_textures = get_gl_parameter(GL_MAX_TEXTURE_IMAGE_UNITS)
      @_max_vertex_textures = get_gl_parameter(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS)
      @_max_texture_size = get_gl_parameter(GL_MAX_TEXTURE_SIZE)
      @_max_cubemap_size = get_gl_parameter(GL_MAX_CUBE_MAP_TEXTURE_SIZE)

      @_supports_vertex_textures = @_max_vertex_textures > 0
      @_supports_bone_textures = @_supports_vertex_textures && false # TODO: extensions.get('OES_texture_float') ????

      #

      # Plugins

      # TODO: when plugins are ready
      @shadow_map_plugin = ShadowMapPlugin.new(self, @lights, @_opengl_objects, @_opengl_objects_immediate)
      #
      # @sprite_plugin = SpritePlugin(self, @sprites)
      # @lens_flare_plugin = LensFlarePlugin(self, @lens_flares)

      # Events

      @on_object_removed = -> (event) {
        object = event.target
        object.traverse do |child|
          child.remove_event_listener(:remove, @on_object_removed)
          remove_child(child)
        end
      }

      @on_geometry_dispose = -> (event) {
        geometry = event.target
        geometry.remove_event_listener(:dispose, @on_geometry_dispose)
        deallocate_geometry(geometry)
      }

      @on_texture_dispose = -> (event) {
        texture = event.target
        texture.remove_event_listener(:dispose, @on_texture_dispose)
        deallocate_texture(texture)
        @info[:memory][:textures] -= 1
      }

      @on_render_target_dispose = -> (event) {
        render_target = event.target
        render_target.remove_event_listener(:dispose, @on_render_target_dispose)
        deallocate_render_target(render_target)
        @info[:memory][:textures] -= 1
      }

      @on_material_dispose = -> (event) {
        material = event.target
        material.remove_event_listener(:dispose, @on_material_dispose)
        deallocate_material(material)
      }
    end

    # TODO: get_context ???
    # TODO: force_context_loss ???

    def supports_vertex_textures?
      @_supports_vertex_textures
    end

    # TODO: supports_float_textures? ???
    # TODO: supports[half|standard|compressed|blend min max] ... ???

    def max_anisotropy
      @_max_anisotropy ||= nil
      # TODO: get max anisotropy ????
    end

    def set_size(width, height)
      @width, @height = width, height
      self.set_viewport(0, 0, width, height)
    end

    def set_viewport(x, y, width, height)
      @_viewport_x = x * pixel_ratio
      @_viewport_x = y * pixel_ratio

      @_viewport_width = width * pixel_ratio
      @_viewport_height = height * pixel_ratio

      glViewport(@_viewport_x, @_viewport_y, @_viewport_width, @_viewport_height)
    end

    def set_scissor(x, y, width, height)
      glScissor(
        x * pixel_ratio,
        y * pixel_ratio,
        width * pixel_ratio,
        height * pixel_ratio
      )
    end

    def enable_scissor_test(enable)
      enable ? glEnable(GL_SCISSOR_TEST) : glDisable(GL_SCISSOR_TEST)
    end

    # clearing

    def get_clear_color
      @_clear_color
    end

    def set_clear_color(color, alpha = 1.0)
      @_clear_color.set(color)
      @_clear_alpha = alpha
      clear_color(@_clear_color.r, @_clear_color.g, @_clear_color.b, @_clear_alpha)
    end

    def get_clear_alpha
      @_clear_alpha
    end

    def set_clear_alpha(alpha)
      @_clear_alpha = alpha
      clear_color(@_clear_color.r, @_clear_color.g, @_clear_color.b, @_clear_alpha)
    end

    def clear(color = true, depth = true, stencil = true)
      bits = 0

      bits |= GL_COLOR_BUFFER_BIT if color
      bits |= GL_DEPTH_BUFFER_BIT if depth
      bits |= GL_STENCIL_BUFFER_BIT if stencil

      glClear(bits)
    end

    def clear_depth
      glClear(GL_DEPTH_BUFFER_BIT)
    end

    def clear_stencil
      glClear(GL_STENCIL_BUFFER_BIT)
    end

    def clear_target(render_target, color, depth, stencil)
      set_render_target(render_target)
      clear(color, depth, stencil)
    end

    def reset_gl_state
      @_current_program = nil
      @_current_camera = nil

      @_current_geometry_program = ''
      @_current_material_id = -1

      @_lights_need_update = true

      @state.reset
    end

    def set_render_target(render_target = nil)
      # TODO: when OpenGLRenderTargetCube exists
      is_cube = false # render_target.is_a? OpenGLRenderTargetCube

      if render_target && render_target[:_opengl_framebuffer].nil?
        render_target.depth_buffer = true if render_target.depth_buffer.nil?
        render_target.stencil_buffer = true if render_target.stencil_buffer.nil?

        render_target.add_event_listener(:dispose, @on_render_target_dispose)

        render_target[:_opengl_texture] = glCreateTexture

        @info[:memory][:textures] += 1

        # Setup texture, create render and frame buffers

        is_target_power_of_two = Math.power_of_two?(render_target.width) && Math.power_of_two?(render_target.height)
        gl_format = param_mittsu_to_gl(render_target.format)
        gl_type = param_mittsu_to_gl(render_target.type)

        if is_cube
          # TODO
        else
          render_target[:_opengl_framebuffer] = glCreateFramebuffer

          if render_target.share_depth_from
            render_target[:_opengl_renderbuffer] = render_target.share_depth_from[:_opengl_renderbuffer]
          else
            render_target[:_opengl_renderbuffer] = glCreateRenderbuffer
          end

          glBindTexture(GL_TEXTURE_2D, render_target[:_opengl_texture])
          set_texture_parameters(GL_TEXTURE_2D, render_target, is_target_power_of_two)

          glTexImage2D(GL_TEXTURE_2D, 0, gl_format, render_target.width, render_target.height, 0, gl_format, gl_type, nil)

          setup_framebuffer(render_target[:_opengl_framebuffer], render_target, GL_TEXTURE_2D)

          if render_target.share_depth_from
            if render_target.depth_buffer && !render_target.stencil_buffer
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, render_target[:_opengl_renderbuffer])
            elsif render_target.depth_buffer && render_target.stencil_buffer
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, render_target[:_opengl_renderbuffer])
            end
          else
            setup_renderbuffer(render_target[:_opengl_renderbuffer], render_target)
          end

          glGenerateMipmap(GL_TEXTURE_2D) if is_target_power_of_two
        end

        # Release everything

        if is_cube
          # TODO
        else
          glBindTexture(GL_TEXTURE_2D, 0)
        end

        glBindRenderbuffer(GL_RENDERBUFFER, 0)
        glBindFramebuffer(GL_FRAMEBUFFER, 0)
      end

      if render_target
        if is_cube
          # TODO
        else
          framebuffer = render_target[:_opengl_framebuffer]
        end

        width = render_target.width
        height = render_target.height

        vx = 0
        vy = 0
      else
        framebuffer = nil

        width = @_viewport_width
        height = @_viewport_height

        vx = @_viewport_x
        vy = @_viewport_y
      end

      if framebuffer != @_current_framebuffer
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer || 0)
        glViewport(vx, vy, width, height)

        @_current_framebuffer = framebuffer
      end

      @_current_width = width
      @_current_height = height
    end

    def render(scene, camera, render_target = nil, force_clear = false)
      if !camera.is_a?(Camera)
        puts "ERROR: Mittsu::OpenGLRenderer#render: camera is not an instance of Mittsu::Camera"
        return
      end

      fog = scene.fog

      # reset caching for this frame

      @_current_geometry_program = ''
      @_current_material_id = -1
      @_current_camera = nil
      @_lights_need_update = true

      # update scene graph
      scene.update_matrix_world if scene.auto_update

      # update camera matrices and frustum
      camera.update_matrix_world if camera.parent.nil?

      # update skeleton objects
      # TODO: when SkinnedMesh is defined
      # scene.traverse do |object|
      #   if object.is_a? SkinnedMesh
      #     object.skeleton.update
      #   end
      # end

      camera.matrix_world_inverse.inverse(camera.matrix_world)

      @_proj_screen_matrix.multiply_matrices(camera.projection_matrix, camera.matrix_world_inverse)
      @_frustum.set_from_matrix(@_proj_screen_matrix)

      @lights.clear
      @opaque_objects.clear
      @transparent_objects.clear

      @sprites.clear
      @lens_flares.clear

      project_object(scene)

      if @sort_objects
        @opaque_objects.sort { |a,b| painter_sort_stable(a,b) }
        @transparent_objects.sort { |a,b| reverse_painter_sort_stable(a,b) }
      end

      # custom render plugins
      @shadow_map_plugin.render(scene, camera)

      #

      @info[:render][:calls] = 0
      @info[:render][:vertices] = 0
      @info[:render][:faces] = 0
      @info[:render][:points] = 0

      set_render_target(render_target)

      if @auto_clear || force_clear
        clear(@auto_clear_color, @auto_clear_depth, @auto_clear_stencil)
      end

      # set matrices for immediate objects

      @_opengl_objects_immediate.each do |opengl_object|
        object = opengl_object[:object]

        if object.visible
          setup_matrices(object, camera)
          unroll_immediate_buffer_material(opengl_object)
        end
      end

      if scene.override_material
        override_material = scene.override_material

        set_material(override_material)

        render_objects(opaque_object, camera, @lights, fog, override_material)
        render_objects(transparent_objects, camera, @lights, fog, override_material)
        render_objects_immediate(@_opengl_objects_immediate, nil, camera, @lights, fog, override_material)
      else
        # opaque pass (front-to-back order)

        @state.set_blending(NoBlending)

        render_objects(@opaque_objects, camera, @lights, fog, nil)
        render_objects_immediate(@_opengl_objects_immediate, :opaque, camera, @lights, fog, nil)

        # transparent pass (back-to-front-order)

        render_objects(@transparent_objects, camera, @lights, fog, nil)
        render_objects_immediate(@_opengl_objects_immediate, :transparent, camera, @lights, fog, nil)
      end

      # custom render plugins (post pass)

      # TODO: when plugins are ready
      # @sprite_plugin.render(scene, camera)
      # lens_flare_plugin.render(scene, camera, @_current_width, @_current_height)

      # generate mipmap if we're using any kind of mipmap filtering
      if render_target && render_target.generate_mipmaps && render_target.min_filter != NearestFilter && render_target.min_filter != LinearFilter
        update_render_target_mipmap(render_target)
      end

      # endure depth buffer writing is enabled so it can be cleared on next render
      @state.set_depth_test(true)
      @state.set_depth_write(true)
      @state.set_color_write(true)

      #glFinish ??????
    end

    def set_material_faces(material)
      @state.set_double_sided(material.side == DoubleSide)
      @state.set_flip_sided(material.side == BackSide)
    end

    def render_buffer(camera, lights, fog, material, geometry_group, object)
      return unless material.visible

      # TODO: place to put this ???
      vertex_array = geometry_group[:_opengl_vertex_array]
      if vertex_array
        glBindVertexArray(vertex_array)
      end

      update_object(object)

      program = set_program(camera, lights, fog, material, object)

      attributes = program.attributes

      update_buffers = false
      wireframe_bit = material.wireframe ? 1 : 0
      geometry_program = "#{geometry_group[:id]}_#{program.id}_#{wireframe_bit}"

      if geometry_program != @_current_geometry_program
        @_current_geometry_program = geometry_program
        update_buffers = true
      end

      @state.init_attributes if update_buffers

      # vertices
      if !material.morph_targets && attributes['position'] && attributes['position'] >= 0
        if update_buffers
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_vertex_buffer])

          @state.enable_attribute(attributes['position'])

          glVertexAttribPointer(attributes['position'], 3, GL_FLOAT, GL_FALSE, 0, 0)
        end
      elsif object.morph_target_base
        setup_morph_targets(material, geometry_group, object)
      end

      if update_buffers
        # custom attributes

        # use the per-geometry_group custom attribute arrays which are setup in init_mesh_buffers

        if geometry_group[:_opengl_custom_attributes_list]
          geometry_group[:_opengl_custom_attributes_list].each do |attribute|
            if attributes[attribute.buffer.belongs_to_attribute] >= 0
              glBindBuffer(GL_ARRAY_BUFFER, attribute.buffer)

              @state.enable_attribute(attributes[attribute.buffer.belongs_to_attribute])

              glVertexAttribPointer(attributes[attribute.buffer.belongs_to_attribute], attribute.size, GL_FLOAT, GL_FALSE, 0, 0)
            end
          end
        end

        # colors

        if attributes['color'] && attributes['color'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_color_buffer])

          @state.enable_attribute(attributes['color'])

          glVertexAttribPointer(attributes['color'], 3, GL_FLOAT, GL_FALSE, 0, 0)
        elsif !material.default_attribute_values.nil?
          glVertexAttrib3fv(attributes['color'], material.default_attribute_values.color)
        end

        # normals

        if attributes['normal'] && attributes['normal'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_normal_buffer])

          @state.enable_attribute(attributes['normal'])

          glVertexAttribPointer(attributes['normal'], 3, GL_FLOAT, GL_FALSE, 0, 0)
        end

        # tangents

        if attributes['tangent'] && attributes['tangent'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_tangent_buffer])

          @state.enable_attribute(attributes['tangent'])

          glVertexAttribPointer(attributes['tangent'], 4, GL_FLOAT, GL_FALSE, 0, 0)
        end

        # uvs

        if attributes['uv'] && attributes['uv'] >= 0
          if object.geometry.face_vertex_uvs[0]
            glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_uv_buffer])

            @state.enable_attribute(attributes['uv'])

            glVertexAttribPointer(attributes['uv'], 2, GL_FLOAT, GL_FALSE, 0, 0)
          elsif !material.default_attribute_values.nil?
            glVertexAttrib2fv(attributes['uv'], material.default_attribute_values.uv)
          end
        end

        if attributes['uv2'] && attributes['uv2'] >= 0
          if object.geometry.face_vertex_uvs[1]
            glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_uv2_buffer])

            @state.enable_attribute(attributes['uv2'])

            glVertexAttribPointer(attributes['uv2'], 2, GL_FLOAT, GL_FALSE, 0, 0)
          elsif !material.default_attribute_values.nil?
            glVertexAttrib2fv(attributes['uv2'], material.default_attribute_values.uv2)
          end
        end

        if material.skinning && attributes['skin_index'] && attributes['skin_weight'] && attributes['skin_index'] >= 0 && attributes['skin_weight'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_skin_indices_buffer])

          @state.enable_attribute(attributes['skin_index'])

          glVertexAttribPointer(attributes['skin_index'], 4, GL_FLOAT, GL_FALSE, 0, 0)

          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_skin_weight_buffer])

          @state.enable_attribute(attributes['skin_weight'])

          glVertexAttribPointer(attributes['skin_weight'], 4, GL_FLOAT, GL_FALSE, 0, 0)
        end

        # line distances

        if attributes['line_distances'] && attributes['line_distances'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_line_distance_buffer])

          @state.enable_attribute(attributes['line_distance'])

          glVertexAttribPointer(attributes['line_distance'], 1, GL_FLOAT, GL_FALSE, 0, 0)
        end
      end

      @state.disable_unused_attributes

      # render mesh
      object.renderer(self).render_buffer(camera, lights, fog, material, geometry_group, update_buffers)

      # TODO: render particles
      # when PointCloud
      #   glDrawArrays(GL_POINTS, 0, geometry_group[:_opengl_particle_count])
      #
      #   @info[:render][:calls] += 1
      #   @info[:render][:points] += geometry_group[:_opengl_particle_count]
    end

    def set_texture(texture, slot)
      glActiveTexture(GL_TEXTURE0 + slot)

      if texture.needs_update?
        upload_texture(texture)
      else
        glBindTexture(GL_TEXTURE_2D, texture[:_opengl_texture])
      end
    end

    def upload_texture(texture)
      if texture[:_opengl_init].nil?
        texture[:_opengl_init] = true
        texture.add_event_listener :dispose, @on_texture_dispose
        texture[:_opengl_texture] = glCreateTexture
        @info[:memory][:textures] += 1
      end

      glBindTexture(GL_TEXTURE_2D, texture[:_opengl_texture])

      # glPixelStorei(GL_UNPACK_FLIP_Y_WEBGL, texture.flip_y) ???
      # glPixelStorei(GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiply_alpha) ???
      glPixelStorei(GL_UNPACK_ALIGNMENT, texture.unpack_alignment)

      texture.image = clamp_to_max_size(texture.image, @_max_texture_size)

      image = texture.image
      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)
      gl_format = param_mittsu_to_gl(texture.format)
      gl_type = param_mittsu_to_gl(texture.type)

      set_texture_parameters(GL_TEXTURE_2D, texture, is_image_power_of_two)

      mipmaps = texture.mipmaps

      if texture.is_a?(DataTexture)
        # use manually created mipmaps if available
        # if there are no manual mipmaps
        # set 0 level mipmap and then use GL to generate other mipmap levels

        if !mipmaps.empty? && is_image_power_of_two
          mipmaps.each_with_index do |mipmap, i|
            glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
          end
        else
          glTexImage2D(GL_TEXTURE_2D, 0, gl_format, image.width, image.height, 0, gl_format, gl_type, image.data)
        end
      elsif texture.is_a?(CompressedTexture)
        mipmaps.each_with_index do |mipmap, i|
          if texture.format != RGBAFormat && texture.format != RGBFormat
            if get_compressed_texture_formats.index(gl_format)
              glCompressedTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
            else
              puts 'WARNING: Mittsu::OpenGLRenderer: Attempt to load unsupported compressed texture format in #upload_texture'
            end
          else
            glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
          end
        end
      else # regular texture (image, video, canvas)
        # use manually created mipmaps if available
        # if there are no manual mipmaps
        # set 0 level mipmap and then use GL to generate other mipmap levels

        if !mipmaps.empty? && is_image_power_of_two
          mipmaps.each_with_index do |mipmap, i|
            glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
          end

          texture.generate_mipmaps = false
        else
          glTexImage2D(GL_TEXTURE_2D, 0, gl_format, texture.image.width, texture.image.height, 0, gl_format, gl_type, texture.image.data)
        end
      end

      if texture.generate_mipmaps && is_image_power_of_two
        glGenerateMipmap(GL_TEXTURE_2D)
      end

      texture.needs_update = false

      if texture.on_update
        texture.on_update.()
      end
    end

    def create_mesh_renderer(mesh)
      MeshOpenGLRenderer.new(mesh, self)
    end

    def create_line_renderer(line)
      LineOpenGLRenderer.new(line, self)
    end

    private

    def clear_color(r, g, b, a)
      if (@_premultiplied_alpha)
        r *= a; g *= a; b *= a
      end

      glClearColor(r, g, b, a)
    end

    def set_default_gl_state
      glClearColor(0.0, 0.0, 0.0, 1.0)
      glClearDepth(1)
      glClearStencil(0)

      glEnable(GL_DEPTH_TEST)
      glDepthFunc(GL_LEQUAL)

      glFrontFace(GL_CCW)
      glCullFace(GL_BACK)
      glEnable(GL_CULL_FACE)

      glEnable(GL_BLEND)
      glBlendEquation(GL_FUNC_ADD)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

      glViewport(@_viewport_x, @_viewport_y, @_viewport_width, @_viewport_height)

      clear_color(@_clear_color.r, @_clear_color.g, @_clear_color.b, @_clear_alpha)
    end

    def get_compressed_texture_formats
      return @_compressed_texture_formats ||= []
      # TODO: needs extensions.get ...
    end

    def painter_sort_stable(a, b)
      if a[:object].render_order != b[:object].render_order
        a[:object].render_order - b[:object].render_order
      elsif a[:material].id != b[:material].id
        a[:material].id - b[:material].id
      elsif a[:z] != b[:z]
        a[:z] - b[:z]
      else
        a[:id] - b[:id]
      end
    end

    def reverse_painter_sort_stable(a, b)
      if a.object.render_order != b.object.render_order
        a.object.render_order - b.object.render_order
      elsif a.z != b.z
        b.z - a.z
      else
        a.id - b.id
      end
    end

    def get_gl_parameter(pname)
      data = '        '
      glGetIntegerv(pname, data)
      data.unpack('L')[0]
    end

    def project_object(object)
      return unless object.visible
      if object.is_a? Scene # || object.is_a? Group # TODO: when Group is defined
        # skip
      else
        init_object(object)
        if object.is_a? Light
          @lights << object
        # if object.is_a? Sprite # TODO
        #   @sprites << object
        # if object.is_a? LensFlare # TODO
        #   @lens_flares << object
        else
          opengl_objects = @_opengl_objects[object.id]
          if opengl_objects && (!object.frustum_culled || @_frustum.intersects_object?(object))
            opengl_objects.each do |opengl_object|
              unroll_buffer_material(opengl_object)
              opengl_object[:render] = true
              if @sort_objects
                @_vector3.set_from_matrix_position(object.matrix_world)
                @_vector3.apply_projection(@_proj_screen_matrix)

                opengl_object[:z] = @_vector3.z
              end
            end
          end
        end
      end

      object.children.each do |child|
        project_object(child)
      end
    end

    def render_objects(render_list, camera, lights, fog, override_material)
      material = nil
      render_list.each do |opengl_object|
        object = opengl_object[:object]
        buffer = opengl_object[:buffer]

        setup_matrices(object, camera)

        if override_material
          material = override_material
        else
          material = opengl_object[:material]
          next unless material
          set_material(material)
        end

        set_material_faces(material)
        if buffer.is_a? BufferGeometry
          render_buffer_direct(camera, lights, fog, material, buffer, object)
        else
          render_buffer(camera, lights, fog, material, buffer, object)
        end
      end
    end

    def render_objects_immediate(render_list, material_type, camera, lights, fog, override_material)
      material = nil
      render_list.each do |opengl_object|
        object = opengl_object[:object]
        if object.visible
          if override_material
            material = override_material
          else
            material = opengl_object[material_type]
            next unless material
            set_material(material)
          end
          render_immediate_object(camera, lights, fog, material, object)
        end
      end
    end

    def init_object(object)
      if object[:_opengl_init].nil?
        object[:_opengl_init] = true
        object[:_model_view_matrix] = Matrix4.new
        object[:_normal_matrix] = Matrix3.new

        object.add_event_listener(:removed, @on_object_removed)
      end

      geometry = object.geometry

      if geometry.nil?
        # ImmediateRenderObject
      elsif geometry[:_opengl_init].nil?
        geometry[:_opengl_init] = true
        geometry.add_event_listener(:dispose, @on_geometry_dispose)
        case object
        when BufferGeometry
          @info[:memory][:geometries] += 1
        when Mesh
          init_geometry_groups(object, geometry)
        when Line
          if geometry[:_opengl_vertex_buffer].nil?
            create_line_buffers(geometry)
            init_line_buffers(geometry, object)

            geometry.vertices_need_update = true
            geometry.colors_need_update = true
            geometry.line_distances_need_update
          end
        # TODO: when PointCloud exists
        # when PointCloud
        #   if geometry[:_opengl_vertex_buffer].nil?
        #     create_particle_buffers(geometry)
        #     init_particle_buffers(geometry, object)
        #
        #     geometry.vertices_need_update = true
        #     geometry.colors_need_update = true
        #   end
        end
      end

      if object[:_opengl_active].nil?
        object[:_opengl_active] = true
        case object
        when Mesh
          case geometry
          when BufferGeometry
            add_buffer(@_opengl_objects, geometry, object)
          when Geometry
            geometry_groups_list = @geometry_groups[geometry.id]
            geometry_groups_list.each do |group|
              add_buffer(@_opengl_objects, group, object)
            end
          end
        when Line #, PointCloud TODO
          add_buffer(@_opengl_objects, geometry, object)
        else
          # TODO: when ImmediateRenderObject exists
          # if object.is_a? ImmediateRenderObject || object.immediate_render_callback
          #   add_buffer_immediate(@_opengl_objects_immediate, object)
          # end
        end
      end
    end

    def make_groups(geometry, uses_face_material = false)
      max_vertices_in_group = 65535 # TODO: OES_element_index_uint ???

      hash_map = {}

      num_morph_targets = geometry.morph_targets.length
      num_morph_normals = geometry.morph_normals.length

      groups = {}
      groups_list = []

      geometry.faces.each_with_index do |face, f|
        material_index = uses_face_material ? face.material_index : 0

        if !hash_map.include? material_index
          hash_map[material_index] = { hash: material_index, counter: 0 }
        end

        group_hash = "#{hash_map[material_index][:hash]}_#{hash_map[material_index][:counter]}"

        if !groups.include? group_hash
          group = {
            id: @geometry_group_counter += 1,
            faces3: [],
            material_index: material_index,
            vertices: 0,
            num_morph_targets: num_morph_targets,
            num_morph_normals: num_morph_normals
          }

          groups[group_hash] = group
          groups_list << group
        end

        if groups[group_hash][:vertices] + 3 > max_vertices_in_group
          hash_map[material_index][:counter] += 1
          group_hash = "#{hash_map[material_index][:hash]}_#{hash_map[material_index][:counter]}"

          if !groups.include? group_hash
            group = {
              id: @geometry_group_counter += 1,
              faces3: [],
              material_index: material_index,
              vertices: 0,
              num_morph_targets: num_morph_targets,
              num_morph_normals: num_morph_normals
            }

            groups[group_hash] = group
            groups_list << group
          end
        end
        groups[group_hash][:faces3] << f
        groups[group_hash][:vertices] += 3
      end
      groups_list
    end

    def init_geometry_groups(object, geometry)
      # material = object.material
      add_buffers = false

      if @geometry_groups[geometry.id].nil? || geometry.groups_need_update
        @_opengl_objects.delete object.id

        @geometry_groups[geometry.id] = make_groups(geometry, false) # TODO: material.is_a?(MeshFaceMaterial))

        geometry.groups_need_update = false
      end

      geometry_groups_list = @geometry_groups[geometry.id]

      # create separate VBOs per geometry chunk

      geometry_groups_list.each do |geometry_group|
        # initialize VBO on the first access
        if geometry_group[:_opengl_vertex_buffer].nil?
          create_mesh_buffers(geometry_group)
          init_mesh_buffers(geometry_group, object)

          geometry.vertices_need_update = true
          geometry.morph_targets_need_update = true
          geometry.elements_need_update = true
          geometry.uvs_need_update = true
          geometry.normals_need_update = true
          geometry.tangents_need_update = true
          geometry.colors_need_update = true
        else
          add_buffers = false
        end

        if add_buffers || object[:_opengl_active].nil?
          add_buffer(@_opengl_objects, geometry_group, object)
        end
      end

      object[:_opengl_active] = true
    end

    def add_buffer(objlist, buffer, object)
      id = object.id
      objlist[id] ||= []
      objlist[id] << {
        id: id,
        buffer: buffer,
        object: object,
        material: nil,
        z: 0
      }
    end

    def unroll_buffer_material(globject)
      object = globject[:object]
      # buffer = globject[:buffer]

      # geometry = object.geometry
      material = object.material

      if material
        # TODO: when MeshFaceMaterial exists
        # if material.is_a? MeshFaceMaterial
        #   material_index = geometry.is_a? BufferGeometry ? 0 : buffer.material_index
        #
        #   material = material.materials[material_index]
        # end
        globject[:material] = material

        if material.transparent
          @transparent_objects << globject
        else
          @opaque_objects << globject
        end
      end
    end

    def setup_matrices(object, camera)
      object[:_model_view_matrix].tap do |model_view_matrix|
        model_view_matrix.multiply_matrices(camera.matrix_world_inverse, object.matrix_world)
        object[:_normal_matrix].normal_matrix(model_view_matrix)
      end
    end

    def set_material(material)
      if material.transparent
        @state.set_blending(material.blending, material.blend_equation, material.blend_src, material.blend_dst, material.blend_equation_alpha, material.blend_src_alpha, material.blend_dst_alpha)
      else
        @state.set_blending(NoBlending)
      end

      @state.set_depth_test(material.depth_test)
      @state.set_depth_write(material.depth_write)
      @state.set_color_write(material.color_write)
      @state.set_polygon_offset(material.polygon_offset, material.polygon_offset_factor, material.polygon_offset_units)
    end

    def create_line_buffers(geometry)
      geometry[:_opengl_vertex_array] = glCreateVertexArray

      geometry[:_opengl_vertex_buffer] = glCreateBuffer
      geometry[:_opengl_color_buffer] = glCreateBuffer
      geometry[:_opengl_line_distance_buffer] = glCreateBuffer

      @info[:memory][:geometries] += 1
    end

    def create_mesh_buffers(geometry_group)
      geometry_group[:_opengl_vertex_array] = glCreateVertexArray

      geometry_group[:_opengl_vertex_buffer] = glCreateBuffer
      geometry_group[:_opengl_normal_buffer] = glCreateBuffer
      geometry_group[:_opengl_tangent_buffer] = glCreateBuffer
      geometry_group[:_opengl_color_buffer] = glCreateBuffer
      geometry_group[:_opengl_uv_buffer] = glCreateBuffer
      geometry_group[:_opengl_uv2_buffer] = glCreateBuffer

      geometry_group[:_opengl_skin_indices_buffer] = glCreateBuffer
      geometry_group[:_opengl_skin_weights_buffer] = glCreateBuffer

      geometry_group[:_opengl_face_buffer] = glCreateBuffer
      geometry_group[:_opengl_line_buffer] = glCreateBuffer

      num_morph_targets = geometry_group[:num_morph_targets]

      if num_morph_targets
        geometry_group[:_opengl_morph_targets_buffers] = []

        num_morph_targets.times do |m|
          geometry_group[:_opengl_morph_targets_buffers] << glCreateBuffer
        end
      end

      num_morph_normals = geometry_group[:num_morph_normals]

      if num_morph_normals
        geometry_group[:_opengl_morph_normals_buffers] = []

        num_morph_normals.times do |m|
          geometry_group[:_opengl_morph_normals_buffers] << glCreateBuffer
        end
      end

      @info[:memory][:geometries] += 1
    end

    def glCreateBuffer
      @_b ||= ' '*8
      glGenBuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateTexture
      @_b ||= ' '*8
      glGenTextures(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateVertexArray
      @_b ||= ' '*8
      glGenVertexArrays(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateFramebuffer
      @_b ||= ' '*8
      glGenFramebuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateRenderbuffer
      @_b ||= ' '*8
      glGenRenderbuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def array_to_ptr_easy(data)
      size_of_element = data.first.is_a?(Float) ? Fiddle::SIZEOF_FLOAT : Fiddle::SIZEOF_INT
      if data.first.is_a?(Float)
        size_of_element = Fiddle::SIZEOF_FLOAT
        format_of_element = 'F'
        # data.map!{ |d| d.nil? ? 0.0 : d }
      else
        size_of_element = Fiddle::SIZEOF_INT
        format_of_element = 'L'
        # data.map!{ |d| d.nil? ? 0 : d }
      end
      size = data.length * size_of_element
      array_to_ptr(data, size, format_of_element)
    end

    def array_to_ptr(data, size, format)
      ptr = Fiddle::Pointer.malloc(size)
      ptr[0,size] = data.pack(format * data.length)
      ptr
    end

    def glBufferData_easy(target, data, usage)
      ptr = array_to_ptr_easy(data)
      glBufferData(target, ptr.size, ptr, usage)
    end

    def init_custom_attributes(object)
      geometry = object.geometry
      material = object.material

      nvertices = geometry.vertices.length

      if material.attributes
        geometry[:_opengl_custom_attributes_list] ||= []

        material.attributes.each do |(name, attribute)|
          if !attribute[:_opengl_initialized] || attribute.create_unique_buffers
            attribute[:_opengl_initialized] = true

            size = case attribute.type
            when :v2 then 2
            when :v3 then 3
            when :v4 then 4
            when :c then 3
            else 1
            end

            attribute.size = size

            attribute.array = Array.new(nvertices * size) # Float32Array

            attribute.buffer = glCreateBuffer
            attribute.buffer.belongs_to_attribute = name

            attribute.needs_update = true
          end

          geometry[:_opengl_custom_attributes_list] << attribute
        end
      end
    end

    def init_line_buffers(geometry, object)
      nvertices = geometry.vertices.length

      geometry[:_vertex_array] = Array.new(nvertices * 3, 0.0) # Float32Array
      geometry[:_color_array] = Array.new(nvertices * 3, 0.0) # Float32Array
      geometry[:_line_distance_array] = Array.new(nvertices, 0.0) # Float32Array

      geometry[:_opengl_line_count] = nvertices

      init_custom_attributes(object)
    end

    def init_mesh_buffers(geometry_group, object)
      geometry = object.geometry
      faces3 = geometry_group[:faces3]

      nvertices = faces3.length * 3
      ntris = faces3.length * 1
      nlines = faces3.length * 3

      material = get_buffer_material(object, geometry_group)

      geometry_group[:_vertex_array] = Array.new(nvertices * 3) # Float32Array
      geometry_group[:_normal_array] = Array.new(nvertices * 3) # Float32Array
      geometry_group[:_color_array] = Array.new(nvertices * 3) # Float32Array
      geometry_group[:_uv_array] = Array.new(nvertices * 2) # Float32Array

      if geometry.face_vertex_uvs.length > 1
        geometry_group[:_uv2_array] = Array.new(nvertices * 2) # Float32Array
      end

      if geometry.has_tangents
        geometry_group[:_tangent_array] = Array.new(nvertices * 4) # Float32Array
      end

      if !object.geometry.skin_weights.empty? && !object.geometry.skin_indices.empty?
        geometry_group[:_skin_index_array] = Array.new(nvertices * 4) # Float32Array
        geometry_group[:_skin_weight_array] = Array.new(nvertices * 4)
      end

      # UintArray from OES_element_index_uint ???

      geometry_group[:_type_array] = Array # UintArray ???
      geometry_group[:_face_array] = Array.new(ntris * 3)
      geometry_group[:_line_array] = Array.new(nlines * 2)

      num_morph_targets = geometry_group[:num_morph_targets]

      if !num_morph_targets.zero?
        geometry_group[:_morph_targets_arrays] = []

        num_morph_targets.times do |m|
          geometry_group[:_morph_targets_arrays] << Array.new(nvertices * 3) # Float32Array ???
        end
      end

      num_morph_normals = geometry_group[:num_morph_normals]

      if !num_morph_targets.zero?
        geometry_group[:_morph_normals_arrays] = []

        num_morph_normals.times do |m|
          geometry_group[:_morph_normals_arrays] << Array.new(nvertices * 3) # Float32Array ???
        end
      end

      geometry_group[:_opengl_face_count] = ntris * 3
      geometry_group[:_opengl_line_count] = nlines * 2

      # custom attributes

      if material.attributes
        if geometry_group[:_opengl_custom_attributes_list].nil?
          geometry_group[:_opengl_custom_attributes_list] = []
        end

        material.attributes.each do |(name, original_attribute)|
          attribute = {}
          original_attribute.each do |(key, value)|
            attribute[key] = value
          end

          if !attribute[:_opengl_initialized] || attribute[:create_unique_buffers]
            attribute[:_opengl_initialized] = true

            size = case attribute[:type]
            when :v2 then 2
            when :v3, :c then 3
            when :v4 then 4
            else 1 # :f and :i
            end

            attribute[:size] = size
            attribute[:array] = Array.new(nvertices * size) # Float32Array

            attribute[:buffer] = glCreateBuffer
            attribute[:buffer_belongs_to_attribute] = name

            original_attribute[:needs_update] = true
            attribute[:_original] = original_attribute
          end

          geometry_group[:_opengl_custom_attributes_list] << attribute
        end
      end

      geometry_group[:_initted_arrays] = true
    end

    def update_object(object)
      geometry = object.geometry

      if geometry.is_a? BufferGeometry
        # TODO: geomertry vertex array ?????
        # glBindVertexArray geometry.vertex_array

        geometry.attributes.each do |(key, attribute)|
          buffer_type = (key == 'index') ? GL_ELEMENT_ARRAY_BUFFER : GL_ARRAY_BUFFER

          if attribute.buffer.nil?
            attribute.buffer = glCreateBuffer
            glBindBuffer(buffer_type, attribute.buffer)
            glBufferData_easy(buffer_type, attribute.array, (attribute.is_a? DynamicBufferAttribute) ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW)

            attribute.needs_update = false
          elsif attribute.needs_update
            glBindBuffer(buffer_type, attribute.buffer)
            if attribute.update_range.nil? || attribute.update_range.count == -1 # Not using update ranged
              glBufferSubData(buffer_type, 0, attribute.array)
            elsif attribute.udpate_range.count.zero?
              puts 'ERROR: Mittsu::OpenGLRenderer#update_object: using update_range for Mittsu::DynamicBufferAttribute and marked as needs_update but count is 0, ensure you are using set methods or updating manually.'
            else
              # TODO: make a glBufferSubData_easy method
              glBufferSubData(buffer_type, attribute.update_range.offset * attribute.array.BYTES_PER_ELEMENT, attribute.array.subarray(attribute.update_range.offset, attribute.update_range.offset + attribute.update_range.count))
              attribute.update_range.count = 0 # reset range
            end

            attribute.needs_update = false
          end
        end
      elsif object.is_a? Mesh
        # check all geometry groups
        if geometry.groups_need_update
          init_geometry_groups(object, geometry)
        end

        geometry_groups_list = @geometry_groups[geometry.id]

        material = nil
        geometry_groups_list.each do |geometry_group|
          # TODO: place to put this???
          # glBindVertexArray(geometry_group[:_opengl_vertex_array])
          material = get_buffer_material(object, geometry_group)

          custom_attributes_dirty = material.attributes && are_custom_attributes_dirty(material)

          if geometry.vertices_need_update || geometry.morph_targets_need_update || geometry.elements_need_update || geometry.uvs_need_update || geometry.normals_need_update || geometry.colors_need_update || geometry.tangents_need_update || custom_attributes_dirty
            set_mesh_buffers(geometry_group, object, GL_DYNAMIC_DRAW, !geometry.dynamic, material)
          end
        end

        geometry.vertices_need_update = false
        geometry.morph_targets_need_update = false
        geometry.elements_need_update = false
        geometry.uvs_need_update = false
        geometry.normals_need_update = false
        geometry.colors_need_update = false
        geometry.tangents_need_update = false

        material.attributes && clear_custom_attributes(material)
      elsif (object.is_a? Line)
        # TODO: glBindVertexArray ???
        material = get_buffer_material(object, geometry)
        custom_attributes_dirty = material.attributes && are_custom_attributes_dirty(material)

        if geometry.vertices_need_update || geometry.colors_need_update || geometry.line_distances_need_update || custom_attributes_dirty
          set_line_buffers(geometry, GL_DYNAMIC_DRAW)
        end

        geometry.vertices_need_update = false
        geometry.colors_need_update = false
        geometry.line_distances_need_update = false

        material.attributes && clear_custom_attributes(material)
      elsif object.is_A? PointCloud
        # TODO: glBindVertexArray ???
        material = get_buffer_material(object, geometry)
        custom_attributes_dirty = material.attributes && are_custom_attributes_dirty(material)

        if geometry.vertices_need_update || geometry.colors_need_update || custom_attributes_dirty
          set_particle_buffers(geometry, GL_DYNAMIC_DRAW, object)
        end

        geometry.vertices_need_update = false
        geometry.colors_need_update = false

        material.attributes && clear_custom_attributes(material)
      end
    end

    def get_buffer_material(object, geometry_group)
      # TODO: when MeshFaceMaterial exists
      # object.material.is_a?(MeshFaceMaterial) ? object.material.materials[geometry_group[:material_index]] : object.material

      object.material # for now...
    end

    def set_line_buffers(geometry, hint)
      vertices = geometry.vertices
      colors = geometry.colors
      line_distances = geometry.line_distances_need_update

      vertex_array = geometry[:_vertex_array]
      color_array = geometry[:_color_array]
      line_distance_array = geometry[:_line_distance_array]

      custom_attributes = geometry[:_opengl_custom_attributes_list]

      if geometry.vertices_need_update
        vertices.each_with_index do |vertex, v|
          offset = v * 3

          vertex_array[offset]     = vertex.x
          vertex_array[offset + 1] = vertex.y
          vertex_array[offset + 2] = vertex.z
        end

        glBindBuffer(GL_ARRAY_BUFFER, geometry[:_opengl_vertex_buffer])
        glBufferData_easy(GL_ARRAY_BUFFER, vertex_array, hint)
      end

      if geometry.colors_need_update
        colors.each_with_index do |color, c|
          offset = c * 3

          color_array[offset]     = color.r
          color_array[offset + 1] = color.g
          color_array[offset + 2] = color.b
        end

        glBindBuffer(GL_ARRAY_BUFFER, geometry[:_opengl_color_buffer])
        glBufferData_easy(GL_ARRAY_BUFFER, color_array, hint)
      end

      if geometry.line_distances_need_update
        line_distances.each_with_index do |l, d|
          line_distance_array[d] = l
        end

        glBindBuffer(GL_ARRAY_BUFFER, geometry[:_opengl_line_distance_buffer])
        glBufferData_easy(GL_ARRAY_BUFFER, line_distance_array, hint)
      end

      if custom_attributes
        custom_attribute.each do |custom_attribute|
          offset = 0

          values = custom_attribute.value

          case custom_attribute.size
          when 1
            value.each_with_index do |value, ca|
              custom_attribute.array[ca] = value
            end
          when 2
            values.each_with_index do |value, ca|
              custom_attribute[offset    ] = value.x
              custom_attribute[offset + 1] = value.y

              offset += 2
            end
          when 3
            if custom_attribute.type === :c
              values.each_with_index do |value, ca|
                custom_attribute[offset    ] = value.r
                custom_attribute[offset + 1] = value.g
                custom_attribute[offset + 2] = value.b

                offset += 3
              end
            else
              values.each_with_index do |value, ca|
                custom_attribute[offset    ] = value.x
                custom_attribute[offset + 1] = value.y
                custom_attribute[offset + 2] = value.z

                offset += 3
              end
            end
          when 4
            values.each_with_index do |value, ca|
              custom_attribute[offset    ] = value.x
              custom_attribute[offset + 1] = value.y
              custom_attribute[offset + 2] = value.z
              custom_attribute[offset + 3] = value.w

              offset += 4
            end
          end

          glBindBuffer(GL_ARRAY_BUFFER, custom_attribute.buffer)
          glBufferData_easy(GL_ARRAY_BUFFER, custom_attribute.array, hint)

          custom_attribute.needs_update = false
        end
      end
    end

    def set_mesh_buffers(geometry_group, object, hint, dispose, material)
      return unless geometry_group[:_initted_arrays]

      needs_face_normals = material_needs_face_normals(material)

      vertex_index = 0

      offset = 0
      offset_uv = 0
      offset_uv2 = 0
      offset_face = 0
      offset_normal = 0
      offset_tangent = 0
      offset_line = 0
      offset_color = 0
      offset_skin = 0
      offset_morph_target = 0
      offset_custom = 0

      vertex_array = geometry_group[:_vertex_array]
      uv_array = geometry_group[:_uv_array]
      uv2_array = geometry_group[:_uv2_array]
      normal_array = geometry_group[:_normal_array]
      tangent_array = geometry_group[:_tangent_array]
      color_array = geometry_group[:_color_array]

      skin_index_array = geometry_group[:_skin_index_array]
      skin_weight_array = geometry_group[:_skin_weight_array]

      morph_targets_arrays = geometry_group[:_morph_targets_arrays]
      morph_normals_arrays = geometry_group[:_morph_normals_arrays]

      custom_attributes = geometry_group[:_opengl_custom_attributes_list]

      face_array = geometry_group[:_face_array]
      line_array = geometry_group[:_line_array]

      geometry = object.geometry # this is shared for all chunks

      dirty_vertices = geometry.vertices_need_update
      dirty_elements = geometry.elements_need_update
      dirty_uvs = geometry.uvs_need_update
      dirty_normals = geometry.normals_need_update
      dirty_tangents = geometry.tangents_need_update
      dirty_colors = geometry.colors_need_update
      dirty_morph_targets = geometry.morph_targets_need_update

      vertices = geometry.vertices
      chunk_faces3 = geometry_group[:faces3]
      obj_faces = geometry.faces

      obj_uvs = geometry.face_vertex_uvs[0]
      obj_uvs2 = geometry.face_vertex_uvs[1]

      obj_skin_indices = geometry.skin_indices
      obj_skin_weights = geometry.skin_weights

      morph_targets = geometry.morph_targets
      morph_normals = geometry.morph_normals

      if dirty_vertices
        chunk_faces3.each do |chf|
          face = obj_faces[chf]

          v1 = vertices[face.a]
          v2 = vertices[face.b]
          v3 = vertices[face.c]

          vertex_array[offset]     = v1.x
          vertex_array[offset + 1] = v1.y
          vertex_array[offset + 2] = v1.z

          vertex_array[offset + 3] = v2.x
          vertex_array[offset + 4] = v2.y
          vertex_array[offset + 5] = v2.z

          vertex_array[offset + 6] = v3.x
          vertex_array[offset + 7] = v3.y
          vertex_array[offset + 8] = v3.z

          offset += 9
        end

        glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_vertex_buffer])
        glBufferData_easy(GL_ARRAY_BUFFER, vertex_array, hint)
      end

      if dirty_morph_targets
        morph_targets.each_index do |vk|
          chunk_faces.each do |chf|
            face = obj_faces[chf]

            # morph positions

            v1 = morph_targets[vk].vertices[face.a]
            v2 = morph_targets[vk].vertices[face.b]
            v3 = morph_targets[vk].vertices[face.c]

            vka = morph_targets_arrays[vk]

            vka[offset_morph_target]     = v1.x
            vka[offset_morph_target + 1] = v1.y
            vka[offset_morph_target + 2] = v1.z

            vka[offset_morph_target + 3] = v2.x
            vka[offset_morph_target + 4] = v2.y
            vka[offset_morph_target + 5] = v2.z

            vka[offset_morph_target + 6] = v3.x
            vka[offset_morph_target + 7] = v3.y
            vka[offset_morph_target + 8] = v3.z

            # morph normals

            if material.morph_normals
              if needs_face_normals
                n1 = morph_normals[vk].face_normals[chf]
                n2 = n1
                n3 = n1
              else
                face_vertex_normals = morph_normals[vk].vertex_normals[chf]

                n1 = face_vertex_normals.a
                n2 = face_vertex_normals.b
                n3 = face_vertex_normals.c
              end

              nka = morph_normals_arrays[vk]

              nka[offset_morph_target]     = n1.x
              nka[offset_morph_target + 1] = n1.y
              nka[offset_morph_target + 2] = n1.z

              nka[offset_morph_target + 3] = n2.x
              nka[offset_morph_target + 4] = n2.y
              nka[offset_morph_target + 5] = n2.z

              nka[offset_morph_target + 6] = n3.x
              nka[offset_morph_target + 7] = n3.y
              nka[offset_morph_target + 8] = n3.z
            end

            #

            offset_morph_target += 9
          end

          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_morph_targets_buffers][vk])
          glBufferData_easy(GL_ARRAY_BUFFER, morph_targets_arrays[vk], hint)

          if material.morph_normals
            glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_morph_normals_buffers][vk])
            glBufferData_easy(GL_ARRAY_BUFFER, morph_normals_arrays[vk], hint)
          end
        end
      end

      if !obj_skin_weights.empty?
        chunk_faces3.each do |chf|
          face = obj_faces[chf]

          # weights

          sw1 = obj_skin_weights[face.a]
          sw2 = obj_skin_weights[face.b]
          sw3 = obj_skin_weights[face.c]

          skin_weight_array[offset_skin]     = sw1.x
          skin_weight_array[offset_skin + 1] = sw1.y
          skin_weight_array[offset_skin + 2] = sw1.z
          skin_weight_array[offset_skin + 3] = sw1.w

          skin_weight_array[offset_skin + 4] = sw2.x
          skin_weight_array[offset_skin + 5] = sw2.y
          skin_weight_array[offset_skin + 6] = sw2.z
          skin_weight_array[offset_skin + 7] = sw2.w

          skin_weight_array[offset_skin + 8]  = sw3.x
          skin_weight_array[offset_skin + 9]  = sw3.y
          skin_weight_array[offset_skin + 10] = sw3.z
          skin_weight_array[offset_skin + 11] = sw3.w

          # indices

          si1 = obj_skin_indices[face.a]
          si2 = obj_skin_indices[face.b]
          si3 = obj_skin_indices[face.c]

          skin_indices_array[offset_skin]     = si1.x
          skin_indices_array[offset_skin + 1] = si1.y
          skin_indices_array[offset_skin + 2] = si1.z
          skin_indices_array[offset_skin + 3] = si1.w

          skin_indices_array[offset_skin + 4] = si2.x
          skin_indices_array[offset_skin + 5] = si2.y
          skin_indices_array[offset_skin + 6] = si2.z
          skin_indices_array[offset_skin + 7] = si2.w

          skin_indices_array[offset_skin + 8]  = si3.x
          skin_indices_array[offset_skin + 9]  = si3.y
          skin_indices_array[offset_skin + 10] = si3.z
          skin_indices_array[offset_skin + 11] = si3.w

          offset_skin += 12
        end

        if offset_skin > 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_skin_indices_buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, skin_index_array, hint)

          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_skin_weights_buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, skin_weight_array, hint)
        end
      end

      if dirty_colors
        chunk_faces3.each do |chf|
          face = obj_faces[chf]

          vertex_colors = face.vertex_colors
          face_color = face.color

          if vertex_colors.length == 3 && material.vertex_colors == VertexColors
            c1 = vertex_colors[0]
            c2 = vertex_colors[1]
            c3 = vertex_colors[2]
          else
            c1 = face_color
            c2 = face_color
            c3 = face_color
          end

          color_array[offset_color]     = c1.r
          color_array[offset_color + 1] = c1.g
          color_array[offset_color + 2] = c1.b

          color_array[offset_color + 3] = c2.r
          color_array[offset_color + 4] = c2.g
          color_array[offset_color + 5] = c2.b

          color_array[offset_color + 6] = c3.r
          color_array[offset_color + 7] = c3.g
          color_array[offset_color + 8] = c3.b

          offset_color += 9
        end

        if offset_color > 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_color_buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, color_array, hint)
        end
      end

      if dirty_tangents && geometry.has_tangents
        chunk_faces3.each do |chf|
          face = obj_faces[chf]

          vertex_tangents = face.vertex_tangents

          t1 = vertex_tangents[0]
          t2 = vertex_tangents[1]
          t3 = vertex_tangents[2]

          tangent_array[offset_tangent]     = t1.x
          tangent_array[offset_tangent + 1] = t1.y
          tangent_array[offset_tangent + 2] = t1.z
          tangent_array[offset_tangent + 3] = t1.w

          tangent_array[offset_tangent + 4] = t2.x
          tangent_array[offset_tangent + 5] = t2.y
          tangent_array[offset_tangent + 6] = t2.z
          tangent_array[offset_tangent + 7] = t2.w

          tangent_array[offset_tangent + 8]  = t3.x
          tangent_array[offset_tangent + 9]  = t3.y
          tangent_array[offset_tangent + 10] = t3.z
          tangent_array[offset_tangent + 11] = t3.w

          offset_tangent += 12
        end

        glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_tangent_buffer])
        glBufferData_easy(GL_ARRAY_BUFFER, tangent_array, hint)
      end

      if dirty_normals
        chunk_faces3.each do |chf|
          face = obj_faces[chf]

          vertex_normals = face.vertex_normals
          face_normal = face.normal

          if vertex_normals.length == 3 && !needs_face_normals
            3.times do |i|
              vn = vertex_normals[i]

              normal_array[offset_normal]     = vn.x
              normal_array[offset_normal + 1] = vn.y
              normal_array[offset_normal + 2] = vn.z

              offset_normal += 3
            end
          else
            3.times do |i|
              normal_array[offset_normal]     = face_normal.x
              normal_array[offset_normal + 1] = face_normal.y
              normal_array[offset_normal + 2] = face_normal.z

              offset_normal += 3
            end
          end
        end

        glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_normal_buffer])
        glBufferData_easy(GL_ARRAY_BUFFER, normal_array, hint)
      end

      if dirty_uvs && obj_uvs
        chunk_faces3.each do |fi|
          uv = obj_uvs[fi]

          next if uv.nil?

          3.times do |i|
            uvi = uv[i]

            uv_array[offset_uv]     = uvi.x
            uv_array[offset_uv + 1] = uvi.y

            offset_uv += 2
          end
        end

        if offset_uv > 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_uv_buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, uv_array, hint)
        end
      end

      if dirty_uvs && obj_uvs2
        chunk_faces3.each do |fi|
          uv2 = obj_uvs2[fi]

          next if uv2.nil?

          3.times do |i|
            uv2i = uv2[i]

            uv2_array[offset_uv2]     = uv2i.x
            uv2_array[offset_uv2 + 1] = uv2i.y

            offset_uv2 += 2
          end
        end

        if offset_uv2 > 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group[:_opengl_uv2_buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, uv2_array, hint)
        end
      end

      if dirty_elements
        chunk_faces3.each do |chf|
          face_array[offset_face]     = vertex_index
          face_array[offset_face + 1] = vertex_index + 1
          face_array[offset_face + 2] = vertex_index + 2

          offset_face += 3

          line_array[offset_line]     = vertex_index
          line_array[offset_line + 1] = vertex_index + 1

          line_array[offset_line + 2] = vertex_index
          line_array[offset_line + 3] = vertex_index + 2

          line_array[offset_line + 4] = vertex_index + 1
          line_array[offset_line + 5] = vertex_index + 2

          offset_line += 6

          vertex_index += 3
        end

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, geometry_group[:_opengl_face_buffer])
        glBufferData_easy(GL_ELEMENT_ARRAY_BUFFER, face_array, hint)

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, geometry_group[:_opengl_line_buffer])
        glBufferData_easy(GL_ELEMENT_ARRAY_BUFFER, line_array, hint)
      end

      if custom_attributes
        custom_attributes.each do |custom_attribute|
          next if !custom_attribute[:_original][:needs_update]

          offset_custom = 0

          if custom_attribute[:size] == 1
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              chunk_faces3.each do |chf|
                face = obj_faces[chf]

                custom_attribute[:array][offset_custom]     = custom_attribute[:value][face.a]
                custom_attribute[:array][offset_custom + 1] = custom_attribute[:value][face.b]
                custom_attribute[:array][offset_custom + 2] = custom_attribute[:value][face.c]

                offset_custom += 3
              end
            elsif custom_attribute[:bound_to] == :faces
              value = custom_attribute[:value][chf]

              custom_attribute[:array][offset_custom]     = value
              custom_attribute[:array][offset_custom + 1] = value
              custom_attribute[:array][offset_custom + 2] = value

              offset_custom += 3
            end
          elsif custom_attribute[:size] == 2
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              chunk_faces3.each do |chf|
                face = obj_faces[chf]

                v1 = custom_attribute[:value][face.a]
                v2 = custom_attribute[:value][face.b]
                v3 = custom_attribute[:value][face.c]

                custom_attribute[:array][offset_custom]     = v1.x
                custom_attribute[:array][offset_custom + 1] = v1.y

                custom_attribute[:array][offset_custom + 2] = v2.x
                custom_attribute[:array][offset_custom + 3] = v2.y

                custom_attribute[:array][offset_custom + 4] = v3.x
                custom_attribute[:array][offset_custom + 5] = v3.y

                offset_custom += 6
              end
            elsif custom_attribute[:bound_to] == :faces
              chunk_faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value
                v2 = value
                v3 = value

                custom_attribute[:array][offset_custom]     = v1.x
                custom_attribute[:array][offset_custom + 1] = v1.y

                custom_attribute[:array][offset_custom + 2] = v2.x
                custom_attribute[:array][offset_custom + 3] = v2.y

                custom_attribute[:array][offset_custom + 4] = v3.x
                custom_attribute[:array][offset_custom + 5] = v3.y

                offset_custom += 6
              end
            end
          elsif custom_attribute[:size] == 3
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              chunk_faces3.each do |chf|
                face = obj_faces[chf];

                v1 = custom_attribute[:value][face.a]
                v2 = custom_attribute[:value][face.b]
                v3 = custom_attribute[:value][face.c]

                custom_attribute[:array][offset_custom]     = v1[0]
                custom_attribute[:array][offset_custom + 1] = v1[1]
                custom_attribute[:array][offset_custom + 2] = v1[2]

                custom_attribute[:array][offset_custom + 3] = v2[0]
                custom_attribute[:array][offset_custom + 4] = v2[1]
                custom_attribute[:array][offset_custom + 5] = v2[2]

                custom_attribute[:array][offset_custom + 6] = v3[0]
                custom_attribute[:array][offset_custom + 7] = v3[1]
                custom_attribute[:array][offset_custom + 8] = v3[2]

                offset_custom += 9
              end
            elsif custom_attribute[:bound_to] == :faces
              chunk_faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value
                v2 = value
                v3 = value

                custom_attribute[:array][offset_custom]     = v1[0]
                custom_attribute[:array][offset_custom + 1] = v1[1]
                custom_attribute[:array][offset_custom + 2] = v1[2]

                custom_attribute[:array][offset_custom + 3] = v2[0]
                custom_attribute[:array][offset_custom + 4] = v2[1]
                custom_attribute[:array][offset_custom + 5] = v2[2]

                custom_attribute[:array][offset_custom + 6] = v3[0]
                custom_attribute[:array][offset_custom + 7] = v3[1]
                custom_attribute[:array][offset_custom + 8] = v3[2]

                offset_custom += 9
              end
            elsif custom_attribute[:bound_to] == :face_vertices
              chunk_faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value[0]
                v2 = value[1]
                v3 = value[2]

                custom_attribute[:array][offset_custom]     = v1[0]
                custom_attribute[:array][offset_custom + 1] = v1[1]
                custom_attribute[:array][offset_custom + 2] = v1[2]

                custom_attribute[:array][offset_custom + 3] = v2[0]
                custom_attribute[:array][offset_custom + 4] = v2[1]
                custom_attribute[:array][offset_custom + 5] = v2[2]

                custom_attribute[:array][offset_custom + 6] = v3[0]
                custom_attribute[:array][offset_custom + 7] = v3[1]
                custom_attribute[:array][offset_custom + 8] = v3[2]

                offset_custom += 9
              end
            end
          elsif custom_attribute[:size] == 4
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              chunk_faces3.each do |chf|
                face = obj_faces[chf]

                v1 = custom_attribute[:value][face.a]
                v2 = custom_attribute[:value][face.b]
                v3 = custom_attribute[:value][face.c]

                customAttribute.array[offset_custom]      = v1.x
                customAttribute.array[offset_custom + 1 ] = v1.y
                customAttribute.array[offset_custom + 2 ] = v1.z
                customAttribute.array[offset_custom + 3 ] = v1.w

                customAttribute.array[offset_custom + 4 ] = v2.x
                customAttribute.array[offset_custom + 5 ] = v2.y
                customAttribute.array[offset_custom + 6 ] = v2.z
                customAttribute.array[offset_custom + 7 ] = v2.w

                customAttribute.array[offset_custom + 8 ] = v3.x
                customAttribute.array[offset_custom + 9 ] = v3.y
                customAttribute.array[offset_custom + 10] = v3.z
                customAttribute.array[offset_custom + 11] = v3.w

                offset_custom += 12
              end
            elsif custom_attribute[:bound_to] == :faces
              chunk_faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value
                v2 = value
                v3 = value

                customAttribute.array[offset_custom]      = v1.x
                customAttribute.array[offset_custom + 1 ] = v1.y
                customAttribute.array[offset_custom + 2 ] = v1.z
                customAttribute.array[offset_custom + 3 ] = v1.w

                customAttribute.array[offset_custom + 4 ] = v2.x
                customAttribute.array[offset_custom + 5 ] = v2.y
                customAttribute.array[offset_custom + 6 ] = v2.z
                customAttribute.array[offset_custom + 7 ] = v2.w

                customAttribute.array[offset_custom + 8 ] = v3.x
                customAttribute.array[offset_custom + 9 ] = v3.y
                customAttribute.array[offset_custom + 10] = v3.z
                customAttribute.array[offset_custom + 11] = v3.w

                offset_custom += 12
              end
            elsif custom_attribute[:bound_to] == :face_vertices
              chunk_faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value[0]
                v2 = value[1]
                v3 = value[2]

                customAttribute.array[offset_custom]      = v1.x
                customAttribute.array[offset_custom + 1 ] = v1.y
                customAttribute.array[offset_custom + 2 ] = v1.z
                customAttribute.array[offset_custom + 3 ] = v1.w

                customAttribute.array[offset_custom + 4 ] = v2.x
                customAttribute.array[offset_custom + 5 ] = v2.y
                customAttribute.array[offset_custom + 6 ] = v2.z
                customAttribute.array[offset_custom + 7 ] = v2.w

                customAttribute.array[offset_custom + 8 ] = v3.x
                customAttribute.array[offset_custom + 9 ] = v3.y
                customAttribute.array[offset_custom + 10] = v3.z
                customAttribute.array[offset_custom + 11] = v3.w

                offset_custom += 12
              end
            end
          end

          glBindBuffer(GL_ARRAY_BUFFER, custom_attribute[:buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, custom_attribute[:array], hint)
        end
      end

      if dispose
        geometry_group.delete(:_initted_arrays)
        geometry_group.delete(:_color_array)
        geometry_group.delete(:_normal_array)
        geometry_group.delete(:_tangent_array)
        geometry_group.delete(:_uv_array)
        geometry_group.delete(:_uv2_array)
        geometry_group.delete(:_face_array)
        geometry_group.delete(:_vertex_array)
        geometry_group.delete(:_line_array)
        geometry_group.delete(:_skin_index_array)
        geometry_group.delete(:_skin_weight_array)
      end
    end

    def material_needs_face_normals(material)
      !material.is_a?(MeshPhongMaterial) && material.shading == FlatShading
    end

    def set_program(camera, lights, fog, material, object)
      @_used_texture_units = 0

      if material.needs_update?
        deallocate_material(material) if material.program

        init_material(material, lights, fog, object)
        material.needs_update = false
      end

      if material.morph_targets
        if !object[:_opengl_morph_target_influences]
          object[:_opengl_morph_target_influences] = Array.new(@max_morph_targets) # Float32Array
        end
      end

      refresh_program = false
      refresh_material = false
      refresh_lights = false

      program = material.program
      p_uniforms = program.uniforms
      m_uniforms = material[:_opengl_shader][:uniforms]

      if program.id != @_current_program
        glUseProgram(program.program)
        @_current_program = program.id

        refresh_program = true
        refresh_material = true
        refresh_lights = true
      end

      if material.id != @_current_material_id
        refresh_lights = true if @_current_material_id == -1
        @_current_material_id = material.id

        refresh_material = true
      end

      if refresh_program || camera != @_current_camera
        glUniformMatrix4fv(p_uniforms['projectionMatrix'], 1, GL_FALSE, array_to_ptr_easy(camera.projection_matrix.elements))

        if @_logarithmic_depth_buffer
          glUniform1f(p_uniforms['logDepthBuffFC'], 2.0 / Math.log(camera.far + 1.0) / Math::LN2)
        end

        @_current_camera = camera if camera != @_current_camera

        # load material specific uniforms
        # (shader material also gets them for the sake of genericity)

        if material.is_a?(ShaderMaterial) || material.is_a?(MeshPhongMaterial) || material.env_map
          if !p_uniforms['cameraPosition'].nil?
            @_vector3.set_from_matrix_position(camera.matrix_world)
            glUniform3f(p_uniforms['cameraPosition'], @_vector3.x, @_vector3.y, @_vector3.z)
          end
        end

        if material.is_a?(MeshPhongMaterial) || material.is_a?(MeshLambertMaterial) || material.is_a?(MeshBasicMaterial) || material.is_a?(ShaderMaterial) || material.skinning
          if !p_uniforms['viewMatrix'].nil?
            glUniformMatrix4fv(p_uniforms['viewMatrix'], 1, GL_FALSE, array_to_ptr_easy(camera.matrix_world_inverse.elements))
          end
        end
      end

      if material.skinning
        if object.bind_matrix && !p_uniforms.bind_matrix.nil?
          glUniformMatrix4fv(p_uniforms.bind_matrix, GL_FALSE, object.bind_matrix.elements)
        end

        if object.bind_matrix_inverse && !p_uniforms.bind_matrix_inverse.nil?
          glUniformMatrix4fv(p_uniforms.bind_matrix_inverse, GL_FALSE, object.bind_matrix_inverse.elements)
        end

        if _supports_bone_textures && object.skeleton && object.skeleton.use_vertex_texture
          if !p_uniforms.bone_texture.nil?
            texture_unit = get_texture_unit

            glUniform1i(p_uniforms.bone_texture, texture_unit)
            self.set_texture(object.skeleton.bone_texture, texture_unit)
          end

          if !p_uniforms.bone_texture_width.nil?
            glUniform1i(p_uniforms.bone_texture_width, object.skeleton.bone_texture_width)
          end

          if !p_uniforms.bone_texture_height.nil?
            glUniform1i(p_uniforms.bone_texture_height, object.skeleton.bone_texture_height)
          end
        elsif object.skeleton && object.skeleton.bone_matrices
          if !p_uniforms.bone_global_matrices.nil?
            glUniformMatrix4fv(p_uniforms.bone_global_matrices, GL_FALSE, object.skeleton.bone_matrices)
          end
        end
      end

      if refresh_material
        if fog && material.fog
        end

        if material.is_a?(MeshPhongMaterial) || material.is_a?(MeshLambertMaterial) || material.lights
          if @_lights_need_update
            refresh_lights = true
            setup_lights(lights)
            @_lights_need_update = false
          end

          if refresh_lights
            refresh_uniforms_lights(m_uniforms, @_lights)
            mark_uniforms_lights_needs_update(m_uniforms, true)
          else
            mark_uniforms_lights_needs_update(m_uniforms, false)
          end
        end

        if material.is_a?(MeshBasicMaterial) || material.is_a?(MeshLambertMaterial) || material.is_a?(MeshPhongMaterial)
          refresh_uniforms_common(m_uniforms, material)
        end

        # refresh single material specific uniforms

        # TODO: when all of these things exist
        case material
        when LineBasicMaterial
          refresh_uniforms_line(m_uniforms, material)
        # when LineDashedMaterial
        #   refresh_uniforms_line(m_uniforms, material)
        #   refresh_uniforms_dash(m_uniforms, material)
        # when PointCloudMaterial
        #   refresh_uniforms_particle(m_uniforms, material)
        when MeshPhongMaterial
          refresh_uniforms_phong(m_uniforms, material)
        when MeshLambertMaterial
          refresh_uniforms_lambert(m_uniforms, material)
        # when MeshDepthMaterial
        #   m_uniforms.m_near.value = camera.near
        #   m_uniforms.m_far.value = camera.far
        #   m_uniforms.opacity.value = material.opacity
        # when MeshNormalMaterial
        #   m_uniforms.opactity.value = material.opacity
        end

        if object.receive_shadow && !material[:_shadow_pass]
          refresh_uniforms_shadow(m_uniforms, lights)
        end

        # load common uniforms

        load_uniforms_generic(material[:uniforms_list])
      end

      load_uniforms_matrices(p_uniforms, object)

      if !p_uniforms['modelMatrix'].nil?
        glUniformMatrix4fv(p_uniforms['modelMatrix'], 1, GL_FALSE, array_to_ptr_easy(object.matrix_world.elements))
      end

      program
    end

    def init_material(material, lights, fog, object)
      material.add_event_listener(:dispose, @on_material_dispose)

      shader_id = @shader_ids[material.class]

      if shader_id
        shader = ShaderLib[shader_id]
        material[:_opengl_shader] = {
          uniforms: UniformsUtils.clone(shader.uniforms),
          vertex_shader: shader.vertex_shader,
          fragment_shader: shader.fragment_shader
        }
      else
        material[:_opengl_shader] = {
          uniforms: material.uniforms,
          vertex_shader: material.vertex_shader,
          fragment_shader: material.fragment_shader
        }
      end

      # heuristics to create shader paramaters ccording to lights in the scene
      # (not to blow over max_lights budget)

      max_light_count = allocate_lights(lights)
      max_shadows = allocate_shadows(lights)
      max_bones = allocate_bones(object)

      parameters = {
        supports_vertex_textures: @_supports_vertex_textures,

        map: !!material.map,
        env_map: !!material.env_map,
        env_map_mode: material.env_map && material.env_map.mapping,
        light_map: !!material.light_map,
        bump_map: !!material.light_map,
        normal_map: !!material.normal_map,
        specular_map: !!material.specular_map,
        alpha_map: !!material.alpha_map,

        combine: material.combine,

        vertex_colors: material.vertex_colors,

        fog: fog,
        use_fog: material.fog,
        # fog_exp: fog.is_a?(FogExp2), # TODO: when FogExp2 exists

        flat_shading: material.shading == FlatShading,

        size_attenuation: material.size_attenuation,
        logarithmic_depth_buffer: @_logarithmic_depth_buffer,

        skinning: material.skinning,
        max_bones: max_bones,
        use_vertex_texture: @_supports_bone_textures,

        morph_targets: material.morph_targets,
        morph_normals: material.morph_normals,
        max_morph_targets: @max_morph_targets,
        max_morph_normals: @max_morph_normals,

        max_dir_lights: max_light_count[:directional],
        max_point_lights: max_light_count[:point],
        max_spot_lights: max_light_count[:spot],
        max_hemi_lights: max_light_count[:hemi],

        max_shadows: max_shadows,
        shadow_map_enabled: @shadow_map_enabled && object.receive_shadow && max_shadows > 0,
        shadow_map_type: @shadow_map_type,
        shadow_map_debug: @shadow_map_debug,
        shadow_map_cascade: @shadow_map_cascade,

        alpha_test: material.alpha_test,
        metal: material.metal,
        wrap_around: material.wrap_around,
        double_sided: material.side == DoubleSide,
        flip_sided: material.side == BackSide
      }

      # generate code

      chunks = []

      if shader_id
        chunks << shader_id
      else
        chunks << material.fragment_shader
        chunks << material.vertex_shader
      end

      if !material.defines.nil?
        material.defines.each do |(name, define)|
          chunks << name
          chunks << define
        end
      end

      parameters.each do |(name, parameter)|
        chunks << name
        chunks << parameter
      end

      code = chunks.join

      program = nil

      # check if code has been already compiled

      @_programs.each do |program_info|
        if program_info.code == code
          program = program_info
          program.used_times += 1
          break
        end
      end

      if program.nil?
        program = OpenGLProgram.new(self, code, material, parameters)
        @_programs.push(program)

        @info[:memory][:programs] = @_programs.length
      end

      material.program = program

      attributes = program.attributes

      if material.morph_targets
        material.num_supported_morph_targets = 0
        base = 'morphTarget'

        @max_morph_targets.times do |i|
          id = base + i
          if attributes[id] >= 0
            material.num_supported_morph_targets += 1
          end
        end
      end

      if material.morph_normals
        material.num_supported_morph_normals = 0
        base = 'morphNormal'

        @max_morph_normals.times do |i|
          id = base + i
          if attributes[id] >= 0
            material.num_supported_morph_normals += 1
          end
        end
      end

      material[:uniforms_list] = []

      material[:_opengl_shader][:uniforms].each_key do |u|
        location = material.program.uniforms[u]

        if location
          material[:uniforms_list] << [material[:_opengl_shader][:uniforms][u], location]
        end
      end
    end

    def allocate_lights(lights)
      dir_lights = 0
      point_lights = 0
      spot_lights = 0
      hemi_lights = 0

      lights.each do |light|
        next if light.only_shadow || !light.visible

        dir_lights   += 1 if light.is_a? DirectionalLight
        point_lights += 1 if light.is_a? PointLight
        spot_lights  += 1 if light.is_a? SpotLight
        hemi_lights  += 1 if light.is_a? HemisphereLight
      end

      {
        directional: dir_lights,
        point: point_lights,
        spot: spot_lights,
        hemi: hemi_lights
      }
    end

    def allocate_shadows(lights)
      max_shadows = 0

      lights.each do |light|
        next unless light.cast_shadow

        max_shadows += 1 if light.is_a?(SpotLight)
        max_shadows += 1 if light.is_a?(DirectionalLight) && !light.shadow_cascade
      end

      max_shadows
    end

    def allocate_bones(object = nil)
      if @_supports_bone_textures && object && object.skeleton && object.skeleton.use_vertex_texture
        return 1024
      end

      # default for when object is not specified
      # ( for example when prebuilding shader
      #   to be used with multiple objects )
      #
      #  - leave some extra space for other uniforms
      #  - limit here is ANGLE's 254 max uniform vectors
      #    (up to 54 should be safe)

      n_vertex_uniforms = (get_gl_parameter(GL_MAX_VERTEX_UNIFORM_COMPONENTS) / 4.0).floor
      n_vertex_matrices = ((n_vertex_uniforms - 20) / 4.0).floor

      max_bones = n_vertex_matrices

      # TODO: when SkinnedMesh exists
      # if !object.nil? && object.is_a?(SkinnedMesh)
      #   max_bones = [object.skeleton.bones.length, max_bones].min
      #
      #   if max_bones < object.skeleton.bones.length
      #     puts "WARNING: OpenGLRenderer: too many bones - #{object.skeleton.bones.length}, this GPU supports just #{max_bones}"
      #   end
      # end

      max_bones
    end

    def refresh_uniforms_common(uniforms, material)

      uniforms['opacity'].value = material.opacity

      uniforms['diffuse'].value = material.color

      uniforms['map'].value = material.map
      uniforms['lightMap'].value = material.light_map
      uniforms['specularMap'].value = material.specular_map
      uniforms['alphaMap'].value = material.alpha_map

      if material.bump_map
        uniforms['bumpMap'].value = material.bump_map
        uniforms['bumpScale'].value = material.bump_scale
      end

      if material.normal_map
        uniforms['normalMap'].value = material.normal_map
        uniforms['normalScale'].value.copy( material.normal_scale )
      end

      # uv repeat and offset setting priorities
      #  1. color map
      #  2. specular map
      #  3. normal map
      #  4. bump map
      #  5. alpha map

      uv_scale_map = nil

      if material.map
        uv_scale_map = material.map
      elsif material.specular_map
        uv_scale_map = material.specular_map
      elsif material.normal_map
        uv_scale_map = material.normal_map
      elsif material.bump_map
        uv_scale_map = material.bump_map
      elsif material.alpha_map
        uv_scale_map = material.alpha_map
      end

      if !uv_scale_map.nil?
        offset = uv_scale_map.offset
        repeat = uv_scale_map.repeat

        uniforms['offsetRepeat'].value.set(offset.x, offset.y, repeat.x, repeat.y)
      end

      uniforms['envMap'].value = material.env_map
      # TODO: when OpenGLRenderTargetCube exists
      # uniforms['flipEnvMap'].value = material.envMap.is_a?(OpenGLRenderTargetCube) ? 1 : - 1

      uniforms['reflectivity'].value = material.reflectivity
      uniforms['refractionRatio'].value = material.refraction_ratio
    end

    def refresh_uniforms_phong(uniforms, material)
      uniforms['shininess'].value = material.shininess

      uniforms['emissive'].value = material.emissive
      uniforms['specular'].value = material.specular

      if material.wrap_around
        uniforms['wrapRGB'].value.copy(material.wrap_rgb)
      end
    end

    def refresh_uniforms_shadow(uniforms, lights)
      if uniforms['shadowMatrix']
        lights.select(&:cast_shadow).select { |light|
          light.is_a?(SpotLight) || (light.is_a?(DirectionalLight) && !light.shadow_cascade)
        }.each_with_index { |light, i|
          uniforms['shadowMap'].value[i] = light.shadow_map
          uniforms['shadowMapSize'].value[i] = light.shadow_map_size

          uniforms['shadowMatrix'].value[i] = light.shadow_matrix

          uniforms['shadowDarkness'].value[i] = light.shadow_darkness
          uniforms['shadowBias'].value[i] = light.shadow_bias
        }
      end
    end

    def refresh_uniforms_line(uniforms, material)
      uniforms['diffuse'].value = material.color
      uniforms['opacity'].value = material.opacity
    end

    def load_uniforms_generic(uniforms)
      uniforms.each do |(uniform, location)|
        # needs_update property is not added to all uniforms.
        next if uniform.needs_update == false || location == -1

        type = uniform.type
        value = uniform.value

        case type
        when :'1i'
          glUniform1i(location, value)
        when :'1f'
          glUniform1f(location, value)
        when :'2f'
          glUniform2f(location, value[0], value[1])
        when :'3f'
          glUniform2f(location, value[0], value[1], value[2])
        when :'4f'
          glUniform4f(location, value[0], value[1], value[2], value[3])
        when :'1iv'
          glUniform1iv(location, value.length, array_to_ptr_easy(value))
        when :'2iv'
          glUniform2iv(location, value.length / 2, array_to_ptr_easy(value))
        when :'3iv'
          glUniform3iv(location, value.length / 3, array_to_ptr_easy(value))
        when :'4iv'
          glUniform3iv(location, value.length / 4, array_to_ptr_easy(value))
        when :'1fv'
          glUniform1fv(location, value.length, array_to_ptr_easy(value))
        when :'2fv'
          glUniform2fv(location, value.length / 2, array_to_ptr_easy(value))
        when :'3fv'
          glUniform3fv(location, value.length / 3, array_to_ptr_easy(value))
        when :'4fv'
          glUniform3fv(location, value.length / 4, array_to_ptr_easy(value))
        when :Matrix3fv
          glUniformMatrix3fv(location, value / 9, GL_FALSE, array_to_ptr_easy(value))
        when :Matrix4fv
          glUniformMatrix4fv(location, value / 16, GL_FALSE, array_to_ptr_easy(value))

        #

        when :i
          # single integer
          glUniform1i(location, value)
        when :f
          # single float
          glUniform1f(location, value)
        when :v2
          # single Mittsu::Vector2
          glUniform2f(location, value.x, value.y)
        when :v3
          # single Mittsu::Vector3
          glUniform3f(location, value.x, value.y, value.z)
        when :v4
          # single Mittsu::Vector4
          glUniform4f(location, value.x, value.y, value.z, value.w)
        when :c
          # single Mittsu::Color
          glUniform3f(location, value.r, value.g, value.b)
        when :iv1
          # flat array of integers
          glUniform1iv(location, value.length, array_to_ptr_easy(value))
        when :iv
          # flat array of integers with 3 x N size
          glUniform3iv(location, value.length / 3, array_to_ptr_easy(value))
        when :fv1
          # flat array of floats
          glUniform1fv(location, value.length, array_to_ptr_easy(value))
        when :fv
          # flat array of float with 3 x N size
          glUniform3fv(location, value.length / 3, array_to_ptr_easy(value))
        when :v2v
          # array of Mittsu::Vector2
          uniform[:_array] ||= Array.new(2 * value.length) # Float32Array

          value.each_with_index do |v, i|
            offset = i * 2
            uniform[:_array][offset] = v.x
            uniform[:_array][offset + 1] = v.y
          end

          glUniform2fv(location, value.length * 2, array_to_ptr_easy(uniform[:_array]))
        when :v3v
          # array of Mittsu::Vector3
          uniform[:_array] ||= Array.new(3 * value.length) # Float32Array

          value.each_with_index do |v, i|
            offset = i * 3
            uniform[:_array][offset] = v.x
            uniform[:_array][offset + 1] = v.y
            uniform[:_array][offset + 2] = v.z
          end

          glUniform3fv(location, value.length * 3, array_to_ptr_easy(uniform[:_array]))
        when :v4v
          # array of Mittsu::Vector4
          uniform[:_array] ||= Array.new(4 * value.length) # Float32Array

          value.each_with_index do |v, i|
            offset = i * 4
            uniform[:_array][offset] = v.x
            uniform[:_array][offset + 1] = v.y
            uniform[:_array][offset + 2] = v.z
            uniform[:_array][offset + 3] = v.w
          end

          glUniform4fv(location, value.length * 4, array_to_ptr_easy(uniform[:_array]))
        when :m3
          # single Mittsu::Matrix3
          glUniformMatrix3fv(location, 1, GL_FALSE, array_to_ptr_easy(value.elements))
        when :m3v
          # array of Mittsu::Matrix3
          uniform[:_array] ||= Array.new(9 * value.length) # Float32Array

          value.each_with_index do |v, i|
            value[i].flatten_to_array_offset(uniform[:_array], i * 9)
          end

          glUniformMatrix3fv(location, value.length, GL_FALSE, array_to_ptr_easy(uniform[:_array]))
        when :m4
          # single Mittsu::Matrix4
          glUniformMatrix4vf(location, 1, GL_FALSE, array_to_ptr_easy(value.elements))
        when :m4v
          # array of Mittsu::Matrix4
          uniform[:_array] ||= Array.new(16 * value.length) # Float32Array

          value.each_with_index do |v, i|
            value[i].flatten_to_array_offset(uniform[:_array], i * 16)
          end

          glUniformMatrix4fv(location, value.length, GL_FALSE, array_to_ptr_easy(uniform[:_array]))
        when :t
          # single Mittsu::Texture (2d or cube)
          texture = value
          texture_unit = get_texture_unit

          glUniform1i(location, texture_unit)

          next unless texture

          if texture.is_a?(CubeTexture) || (texture.is_a?(Array) && texture.image.length == 6)
            set_cube_texture(texture, texture_unit)
          # TODO: when OpenGLRenderTargetCube is defined
          # elsif texture.is_a?(OpenGLRenderTargetCube)
            # set_cube_texture_dynamic(texture, texture_unit)
          else
            set_texture(texture, texture_unit)
          end
        when :tv
          # array of Mittsu::Texture (2d)
          uniform[:_array] ||= []

          uniform.value.each_index do |i|
            uniform[:_array][i] = get_texture_unit
          end

          glUniform1iv(location, uniform[:_array].length, array_to_ptr_easy(uniform[:_array]))

          uniform.value.each_with_index do |tex, i|
            tex_unit = uniform[:_array][i]

            next unless tex

            set_texture(tex, tex_unit)
          end
        else
          puts "WARNING: Mittsu::OpenGLRenderer: Unknown uniform type: #{type}"
        end
      end
    end

    def load_uniforms_matrices(uniforms, object)
      glUniformMatrix4fv(uniforms['modelViewMatrix'], 1, GL_FALSE, array_to_ptr_easy(object[:_model_view_matrix].elements))

      if uniforms['normalMatrix']
        glUniformMatrix3fv(uniforms['normalMatrix'], 1, GL_FALSE, array_to_ptr_easy(object[:_normal_matrix].elements))
      end
    end

    def setup_lights(lights)
      r, g, b = 0.0, 0.0, 0.0

      zlights = @_lights

      dir_colors = zlights[:directional][:colors]
      dir_positions = zlights[:directional][:positions]

      point_colors = zlights[:point][:colors]
      point_positions = zlights[:point][:positions]
      point_distances = zlights[:point][:distances]
      point_decays = zlights[:point][:decays]

      spot_colors = zlights[:spot][:colors]
      spot_positions = zlights[:spot][:positions]
      spot_distances = zlights[:spot][:distances]
      spot_directions = zlights[:spot][:directions]
      spot_angles_cos = zlights[:spot][:angles_cos]
      spot_exponents = zlights[:spot][:exponents]
      spot_decays = zlights[:spot][:decays]

      hemi_sky_colors = zlights[:hemi][:sky_colors]
      hemi_ground_colors = zlights[:hemi][:ground_colors]
      hemi_positions = zlights[:hemi][:positions]

      dir_length = 0
      point_length = 0
      spot_length = 0
      hemi_length = 0

      dir_count = 0
      point_count = 0
      spot_count = 0
      hemi_count = 0

      dir_offset = 0
      point_offset = 0
      spot_offset = 0
      hemi_offset = 0

      lights.each do |light|

        next if light.only_shadow

        color = light.color
        intensity = light.intensity
        distance = light.distance

        if light.is_a? AmbientLight

          next unless light.visible

          r += color.r
          g += color.g
          b += color.b

        elsif light.is_a? DirectionalLight

          dir_count += 1

          next unless light.visible

          @_direction.set_from_matrix_position(light.matrix_world)
          @_vector3.set_from_matrix_position(light.target.matrix_world)
          @_direction.sub(@_vector3)
          @_direction.normalize

          dir_offset = dir_length * 3

          dir_positions[dir_offset]     = @_direction.x
          dir_positions[dir_offset + 1] = @_direction.y
          dir_positions[dir_offset + 2] = @_direction.z

          set_color_linear(dir_colors, dir_offset, color, intensity)

          dir_length += 1

        elsif light.is_a? PointLight

          point_count += 1

          next unless light.visible

          point_offset = point_length * 3;

          set_color_linear(point_colors, point_offset, color, intensity)

          @_vector3.set_from_matrix_position(light.matrix_world)

          point_positions[point_offset]     = @_vector3.x
          point_positions[point_offset + 1] = @_vector3.y
          point_positions[point_offset + 2] = @_vector3.z

          # distance is 0 if decay is 0, because there is no attenuation at all.
          point_distances[point_length] = distance
          point_decays[point_length] = light.distance.zero? ? 0.0 : light.decay

          point_length += 1

        elsif light.is_a? SpotLight

          spot_count += 1

          next unless light.visible

          spot_offset = spot_length * 3

          set_color_linear(spot_colors, spot_offset, color, intensity)

          @_direction.set_from_matrix_position(light.matrix_world)

          spot_positions[spot_offset]     = @_direction.x
          spot_positions[spot_offset + 1] = @_direction.y
          spot_positions[spot_offset + 2] = @_direction.z

          spot_distances[spot_length] = distance

          @_vector3.set_from_matrix_position(light.target.matrix_world)
          @_direction.sub(@_vector3)
          @_direction.normalize

          spot_directions[spot_offset]     = @_direction.x
          spot_directions[spot_offset + 1] = @_direction.y
          spot_directions[spot_offset + 2] = @_direction.z

          spot_angles_cos[spot_length] = Math.cos(light.angle)
          spot_exponents[spot_length] = light.exponent;
          spot_decays[spot_length] = light.distance.zero? ? 0.0 : light.decay

          spot_length += 1;

        elsif light.is_a? HemisphereLight

          hemi_count += 1

          next unless light.visible

          @_direction.set_from_matrix_position(light.matrix_world)
          @_direction.normalize

          hemi_offset = hemi_length * 3

          hemi_positions[hemi_offset]     = @_direction.x
          hemi_positions[hemi_offset + 1] = @_direction.y
          hemi_positions[hemi_offset + 2] = @_direction.z

          sky_color = light.color
          ground_color = light.ground_color

          set_color_linear(hemi_sky_colors, hemi_offset, sky_color, intensity )
          set_color_linear(hemi_ground_colors, hemi_offset, ground_color, intensity)

          hemi_length += 1

        end

      end

      # null eventual remains from removed lights
      # (this is to avoid if in shader)

      (dir_length * 3).upto([dir_colors.length, dir_count * 3].max - 1).each { |i|
        dir_colors[i] = 0.0
      }
      (point_length * 3).upto([point_colors.length, point_count * 3].max - 1).each { |i|
        point_colors[i] = 0.0
      }
      (spot_length * 3).upto([spot_colors.length, spot_count * 3].max - 1).each { |i|
        spot_colors[i] = 0.0
      }
      (hemi_length * 3).upto([hemi_ground_colors.length, hemi_count * 3].max - 1).each { |i|
        hemi_ground_colors[i] = 0.0
      }
      (hemi_length * 3).upto([hemi_sky_colors.length, hemi_count * 3].max - 1).each { |i|
        hemi_sky_colors[i] = 0.0
      }

      zlights[:directional][:length] = dir_length
      zlights[:point][:length] = point_length
      zlights[:spot][:length] = spot_length
      zlights[:hemi][:length] = hemi_length

      zlights[:ambient][0] = r
      zlights[:ambient][1] = g
      zlights[:ambient][2] = b
    end

    def refresh_uniforms_lights(uniforms, lights)
      uniforms['ambientLightColor'].value = lights[:ambient]

      uniforms['directionalLightColor'].value = lights[:directional][:colors]
      uniforms['directionalLightDirection'].value = lights[:directional][:positions]

      uniforms['pointLightColor'].value = lights[:point][:colors]
      uniforms['pointLightPosition'].value = lights[:point][:positions]
      uniforms['pointLightDistance'].value = lights[:point][:distances]
      uniforms['pointLightDecay'].value = lights[:point][:decays]

      uniforms['spotLightColor'].value = lights[:spot][:colors]
      uniforms['spotLightPosition'].value = lights[:spot][:positions]
      uniforms['spotLightDistance'].value = lights[:spot][:distances]
      uniforms['spotLightDirection'].value = lights[:spot][:directions]
      uniforms['spotLightAngleCos'].value = lights[:spot][:angles_cos]
      uniforms['spotLightExponent'].value = lights[:spot][:exponents]
      uniforms['spotLightDecay'].value = lights[:spot][:decays]

      uniforms['hemisphereLightSkyColor'].value = lights[:hemi][:sky_colors]
      uniforms['hemisphereLightGroundColor'].value = lights[:hemi][:ground_colors]
      uniforms['hemisphereLightDirection'].value = lights[:hemi][:positions]
    end

    def mark_uniforms_lights_needs_update(uniforms, value)
      uniforms['ambientLightColor'].needs_update = value

      uniforms['directionalLightColor'].needs_update = value
      uniforms['directionalLightDirection'].needs_update = value

      uniforms['pointLightColor'].needs_update = value
      uniforms['pointLightPosition'].needs_update = value
      uniforms['pointLightDistance'].needs_update = value
      uniforms['pointLightDecay'].needs_update = value

      uniforms['spotLightColor'].needs_update = value
      uniforms['spotLightPosition'].needs_update = value
      uniforms['spotLightDistance'].needs_update = value
      uniforms['spotLightDirection'].needs_update = value
      uniforms['spotLightAngleCos'].needs_update = value
      uniforms['spotLightExponent'].needs_update = value
      uniforms['spotLightDecay'].needs_update = value

      uniforms['hemisphereLightSkyColor'].needs_update = value
      uniforms['hemisphereLightGroundColor'].needs_update = value
      uniforms['hemisphereLightDirection'].needs_update = value
    end

    def refresh_uniforms_lambert(uniforms, material)
      uniforms['emissive'].value = material.emissive

      if material.wrap_around
        uniforms['wrapRGB'].value.copy(material.wrap_rgb)
      end
    end

    def set_color_linear(array, offset, color, intensity)
      array[offset]     = color.r * intensity
      array[offset + 1] = color.g * intensity
      array[offset + 2] = color.b * intensity
    end

    def get_texture_unit
      texture_unit = @_used_texture_units

      if texture_unit >= @_max_textures
        puts "WARNING: OpenGLRenderer: trying to use #{texture_unit} texture units while this GPU supports only #{@_max_textures}"
      end

      @_used_texture_units += 1
      texture_unit
    end

    def clamp_to_max_size(image, max_size)
      if image.width > max_size || image.height > max_size
        # TODO: scale the image ...

        puts "WARNING: Mittsu::OpenGLRenderer: image is too big (#{image.width} x #{image.height}). Resized to ??? x ???"
      end
      image
    end

    def param_mittsu_to_gl(p)
      case p
      when RepeatWrapping then GL_REPEAT
      when ClampToEdgeWrapping then GL_CLAMP_TO_EDGE
      when MirroredRepeatWrapping then GL_MIRRORED_REPEAT

      when NearestFilter then GL_NEAREST
      when NearestMipMapNearestFilter then GL_NEAREST_MIPMAP_NEAREST
      when NearestMipMapLinearFilter then GL_NEAREST_MIPMAP_LINEAR

      when LinearFilter then GL_LINEAR
      when LinearMipMapNearestFilter then GL_LINEAR_MIPMAP_NEAREST
      when LinearMipMapLinearFilter then GL_LINEAR_MIPMAP_LINEAR

      when UnsignedByteType then GL_UNSIGNED_BYTE
      when UnsignedShort4444Type then GL_UNSIGNED_SHORT_4_4_4_4
      when UnsignedShort5551Type then GL_UNSIGNED_SHORT_5_5_5_1
      when UnsignedShort565Type then GL_UNSIGNED_SHORT_5_6_5

      when ByteType then GL_BYTE
      when ShortType then GL_SHORT
      when UnsignedShortType then GL_UNSIGNED_SHORT
      when IntType then GL_INT
      when UnsignedIntType then GL_UNSIGNED_INT
      when FloatType then GL_FLOAT

      when AlphaFormat then GL_ALPHA
      when RGBFormat then GL_RGB
      when RGBAFormat then GL_RGBA
      when LuminanceFormat then GL_LUMINANCE
      when LuminanceAlphaFormat then GL_LUMINANCE_ALPHA

      when AddEquation then GL_FUNC_ADD
      when SubtractEquation then GL_FUNC_SUBTRACT
      when ReverseSubtractEquation then GL_FUNC_REVERSE_SUBTRACT

      when ZeroFactor then GL_ZERO
      when OneFactor then GL_ONE
      when SrcColorFactor then GL_SRC_COLOR
      when OneMinusSrcColorFactor then GL_ONE_MINUS_SRC_COLOR
      when SrcAlphaFactor then GL_SRC_ALPHA
      when OneMinusSrcAlphaFactor then GL_ONE_MINUS_SRC_ALPHA
      when DstAlphaFactor then GL_DST_ALPHA
      when OneMinusDstAlphaFactor then GL_ONE_MINUS_DST_ALPHA

      when DstColorFactor then GL_DST_COLOR
      when OneMinusDstColorFactor then GL_ONE_MINUS_DST_COLOR
      when SrcAlphaSaturateFactor then GL_SRC_ALPHA_SATURATE
      else 0
      end
    end

    def set_texture_parameters(texture_type, texture, is_image_power_of_two)
      if is_image_power_of_two
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_S, param_mittsu_to_gl(texture.wrap_s))
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_T, param_mittsu_to_gl(texture.wrap_t))

        glTexParameteri(texture_type, GL_TEXTURE_MAG_FILTER, param_mittsu_to_gl(texture.mag_filter))
        glTexParameteri(texture_type, GL_TEXTURE_MIN_FILTER, param_mittsu_to_gl(texture.min_filter))
      else
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

        if texture.wrap_s != ClampToEdgeWrapping || texture.wrap_t != ClampToEdgeWrapping
          puts "WARNING: Mittsu::OpenGLRenderer: Texture is not power of two. Texture.wrap_s and Texture.wrap_t should be set to Mittsu::ClampToEdgeWrapping. (#{texture.source_file})"
        end

        glTexParameteri(texture_type, GL_TEXTURE_MAG_FILTER, filter_fallback(texture.mag_filter))
        glTexParameteri(texture_type, GL_TEXTURE_MIN_FILTER, filter_fallback(texture.min_filter))

        if texture.min_filter != NearestFilter && texture.min_filter != LinearFilter
          puts "WARNING: Mittsu::OpenGLRenderer: Texture is not a power of two. Texture.min_filter should be set to Mittsu::NearestFilter or Mittsu::LinearFilter. (#{texture.source_file})"
        end

        # TODO: anisotropic extension ???
      end
    end

    def set_cube_texture(texture, slot)
      if texture.image.length == 6
        if texture.needs_update?
          if !texture.image[:_opengl_texture_cube]
            texture.add_event_listener(:dispose, @on_texture_dispose)
            texture.image[:_opengl_texture_cube] = glCreateTexture
            @info[:memory][:textures] += 1
          end

          glActiveTexture(GL_TEXTURE0 + slot)
          glBindTexture(GL_TEXTURE_CUBE_MAP, texture.image[:_opengl_texture_cube])

          # glPixelStorei(GL_UNPACK_FLIP_Y_WEBGL, texture.flip_y)

          is_compressed = texture.is_a?(CompressedTexture)
          is_data_texture = texture.image[0].is_a?(DataTexture)

          cube_image = [];

          6.times do |i|
            if @auto_scale_cubemaps && !is_compressed && !is_data_texture
              cube_image[i] = clamp_to_max_size(texture.image[i], @_max_cubemap_size)
            else
              cube_image[i] = is_data_texture ? texture.image[i].image : texture.image[i];
            end
          end

          image = cube_image[0]
          is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)
          gl_format = param_mittsu_to_gl(texture.format)
          gl_type = param_mittsu_to_gl(texture.type)

          set_texture_parameters(GL_TEXTURE_CUBE_MAP, texture, is_image_power_of_two)

          6.times do |i|
            if !is_compressed
              if is_data_texture
                glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl_format, cube_image[i].width, cube_image[i].height, 0, gl_format, gl_type, cube_image[i].data)
              else
                glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl_format, cube_image[i].width, cube_image[i].height, 0, gl_format, gl_type, cube_image[i].data)
              end
            else
              mipmaps = cube_image[i].mipmaps

              mipmaps.each_with_index do |mipmap, j|
                if texture.format != RGBAFormat && texture.format != RGBFormat
                  if get_compressed_texture_formats.include?(gl_format)
                    glCompressedTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, j, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
                  else
                    puts "WARNING: Mittsu::OpenGLRenderer: Attempt to load unsupported compressed texture format in #set_cube_texture"
                  end
                else
                  glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, j, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
                end
              end
            end
          end

          if texture.generate_mipmaps && is_image_power_of_two
            glGenerateMipmap(GL_TEXTURE_CUBE_MAP)
          end

          texture.needs_update = false

          # TODO wat?
          # texture.on_update if texture.on_update
        else
          glActiveTexture(GL_TEXTURE0 + slot)
          glBindTexture(GL_TEXTURE_CUBE_MAP, texture.image[:_opengl_texture_cube])
        end
      end
    end

    def setup_framebuffer(framebuffer, render_target, texture_target)
      glBindFramebuffer(GL_FRAMEBUFFER, framebuffer)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, texture_target, render_target[:_opengl_texture], 0)
    end

    def setup_renderbuffer(renderbuffer, render_target)
      glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer)

      if render_target.depth_buffer && !render_target.stencil_buffer
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, render_target.width, render_target.height)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, renderbuffer)

        # TODO: investigate this (?):
    		# THREE.js - For some reason this is not working. Defaulting to RGBA4.
    		# } else if ( ! renderTarget.depthBuffer && renderTarget.stencilBuffer ) {
        #
    		# 	_gl.renderbufferStorage( _gl.RENDERBUFFER, _gl.STENCIL_INDEX8, renderTarget.width, renderTarget.height );
    		# 	_gl.framebufferRenderbuffer( _gl.FRAMEBUFFER, _gl.STENCIL_ATTACHMENT, _gl.RENDERBUFFER, renderbuffer );
      elsif render_target.depth_buffer && render_target.stencil_buffer
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_STENCIL, render_target.width, render_target.height)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, renderbuffer)
      else
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, render_target.width, render_target.height)
      end
    end
  end
end
