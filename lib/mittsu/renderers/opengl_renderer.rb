require 'opengl'
require 'glfw'
require 'fiddle'

OpenGL.load_lib

require 'mittsu'
require 'mittsu/renderers/glfw_window'
require 'mittsu/renderers/opengl/opengl_debug'
require 'mittsu/renderers/opengl/opengl_helper'
require 'mittsu/renderers/opengl/opengl_program'
require 'mittsu/renderers/opengl/opengl_state'
require 'mittsu/renderers/opengl/opengl_geometry_group'
require 'mittsu/renderers/opengl/core/opengl_geometry'
require 'mittsu/renderers/opengl/core/opengl_object_3d'
require 'mittsu/renderers/opengl/objects/opengl_mesh'
require 'mittsu/renderers/opengl/objects/opengl_line'
require 'mittsu/renderers/opengl/materials/opengl_material'
require 'mittsu/renderers/opengl/textures/opengl_texture'
require 'mittsu/renderers/opengl/textures/opengl_cube_texture'
require 'mittsu/renderers/opengl/plugins/shadow_map_plugin'
require 'mittsu/renderers/shaders/shader_lib'
require 'mittsu/renderers/shaders/uniforms_utils'

include ENV['DEBUG'] ? OpenGLDebug : OpenGL
include Mittsu::OpenGLHelper

module Mittsu
  class OpenGLRenderer
    attr_accessor :auto_clear, :auto_clear_color, :auto_clear_depth, :auto_clear_stencil, :sort_objects, :gamma_factor, :gamma_input, :gamma_output, :shadow_map_enabled, :shadow_map_type, :shadow_map_cull_face, :shadow_map_debug, :shadow_map_cascade, :max_morph_targets, :max_morph_normals, :info, :pixel_ratio, :window, :width, :height, :state

    attr_reader :logarithmic_depth_buffer, :max_morph_targets, :max_morph_normals, :shadow_map_type, :shadow_map_debug, :shadow_map_cascade, :programs

    def initialize(parameters = {})
      puts "OpenGLRenderer (Revision #{REVISION})"

      @pixel_ratio = 1.0

      @_alpha = parameters.fetch(:alpha, false)
      @_depth = parameters.fetch(:depth, true)
      @_stencil = parameters.fetch(:stencil, true)
      @_antialias = parameters.fetch(:antialias, false)
      @_premultiplied_alpha = parameters.fetch(:premultiplied_alpha, true)
      @_preserve_drawing_buffer = parameters.fetch(:preserve_drawing_buffer, false)
      @logarithmic_depth_buffer = parameters.fetch(:logarithmic_depth_buffer, false)

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

      @programs = []

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

      @_max_textures = glGetParameter(GL_MAX_TEXTURE_IMAGE_UNITS)
      @_max_vertex_textures = glGetParameter(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS)
      @_max_texture_size = glGetParameter(GL_MAX_TEXTURE_SIZE)
      @_max_cubemap_size = glGetParameter(GL_MAX_CUBE_MAP_TEXTURE_SIZE)

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

    def supports_bone_textures?
      @_supports_bone_textures
    end

    def supports_vertex_textures?
      @_supports_vertex_textures
    end

    def shadow_map_enabled?
      @shadow_map_enabled
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

      if render_target
        render_target_impl = render_target.implementation(self)
        render_target_impl.set if render_target_impl.framebuffer.nil?

        if is_cube
          # TODO
        else
          framebuffer = render_target_impl.framebuffer
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
        material_impl = override_material.implementation(self)

        material_impl.set

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
      vertex_array = geometry_group.vertex_array_object
      if vertex_array
        glBindVertexArray(vertex_array)
      end

      update_object(object)

      program = set_program(camera, lights, fog, material, object)

      attributes = program.attributes

      update_buffers = false
      wireframe_bit = material.wireframe ? 1 : 0
      geometry_program = "#{geometry_group.id}_#{program.id}_#{wireframe_bit}"

      if geometry_program != @_current_geometry_program
        @_current_geometry_program = geometry_program
        update_buffers = true
      end

      @state.init_attributes if update_buffers

      # vertices
      if !material.morph_targets && attributes['position'] && attributes['position'] >= 0
        if update_buffers
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.vertex_buffer)

          @state.enable_attribute(attributes['position'])

          glVertexAttribPointer(attributes['position'], 3, GL_FLOAT, GL_FALSE, 0, 0)
        end
      elsif object.morph_target_base
        setup_morph_targets(material, geometry_group, object)
      end

      if update_buffers
        # custom attributes

        # use the per-geometry_group custom attribute arrays which are setup in init_mesh_buffers

        if geometry_group.custom_attributes_list
          geometry_group.custom_attributes_list.each do |attribute|
            if attributes[attribute.buffer.belongs_to_attribute] >= 0
              glBindBuffer(GL_ARRAY_BUFFER, attribute.buffer)

              @state.enable_attribute(attributes[attribute.buffer.belongs_to_attribute])

              glVertexAttribPointer(attributes[attribute.buffer.belongs_to_attribute], attribute.size, GL_FLOAT, GL_FALSE, 0, 0)
            end
          end
        end

        # colors

        if attributes['color'] && attributes['color'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.color_buffer)

          @state.enable_attribute(attributes['color'])

          glVertexAttribPointer(attributes['color'], 3, GL_FLOAT, GL_FALSE, 0, 0)
        elsif !material.default_attribute_values.nil?
          glVertexAttrib3fv(attributes['color'], material.default_attribute_values.color)
        end

        # normals

        if attributes['normal'] && attributes['normal'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.normal_buffer)

          @state.enable_attribute(attributes['normal'])

          glVertexAttribPointer(attributes['normal'], 3, GL_FLOAT, GL_FALSE, 0, 0)
        end

        # tangents

        if attributes['tangent'] && attributes['tangent'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.tangent_buffer)

          @state.enable_attribute(attributes['tangent'])

          glVertexAttribPointer(attributes['tangent'], 4, GL_FLOAT, GL_FALSE, 0, 0)
        end

        # uvs

        if attributes['uv'] && attributes['uv'] >= 0
          if object.geometry.face_vertex_uvs[0]
            glBindBuffer(GL_ARRAY_BUFFER, geometry_group.uv_buffer)

            @state.enable_attribute(attributes['uv'])

            glVertexAttribPointer(attributes['uv'], 2, GL_FLOAT, GL_FALSE, 0, 0)
          elsif !material.default_attribute_values.nil?
            glVertexAttrib2fv(attributes['uv'], material.default_attribute_values.uv)
          end
        end

        if attributes['uv2'] && attributes['uv2'] >= 0
          if object.geometry.face_vertex_uvs[1]
            glBindBuffer(GL_ARRAY_BUFFER, geometry_group.uv2_buffer)

            @state.enable_attribute(attributes['uv2'])

            glVertexAttribPointer(attributes['uv2'], 2, GL_FLOAT, GL_FALSE, 0, 0)
          elsif !material.default_attribute_values.nil?
            glVertexAttrib2fv(attributes['uv2'], material.default_attribute_values.uv2)
          end
        end

        if material.skinning && attributes['skin_index'] && attributes['skin_weight'] && attributes['skin_index'] >= 0 && attributes['skin_weight'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.skin_indices_buffer)

          @state.enable_attribute(attributes['skin_index'])

          glVertexAttribPointer(attributes['skin_index'], 4, GL_FLOAT, GL_FALSE, 0, 0)

          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.skin_weight_buffer)

          @state.enable_attribute(attributes['skin_weight'])

          glVertexAttribPointer(attributes['skin_weight'], 4, GL_FLOAT, GL_FALSE, 0, 0)
        end

        # line distances

        if attributes['line_distances'] && attributes['line_distances'] >= 0
          glBindBuffer(GL_ARRAY_BUFFER, geometry_group.line_distance_buffer)

          @state.enable_attribute(attributes['line_distance'])

          glVertexAttribPointer(attributes['line_distance'], 1, GL_FLOAT, GL_FALSE, 0, 0)
        end
      end

      @state.disable_unused_attributes

      object.implementation(self).render_buffer(camera, lights, fog, material, geometry_group, update_buffers)

      # TODO: render particles
      # when PointCloud
      #   glDrawArrays(GL_POINTS, 0, geometry_group.particle_count)
      #
      #   @info[:render][:calls] += 1
      #   @info[:render][:points] += geometry_group.particle_count
    end

    def set_texture(texture, slot)
      glActiveTexture(GL_TEXTURE0 + slot)
      texture_impl = texture.implementation(self)

      if texture.needs_update?
        texture_impl.update
      else
        glBindTexture(GL_TEXTURE_2D, texture_impl.opengl_texture)
      end
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

    def compressed_texture_formats
      # TODO: needs extensions.get ...

      @_compressed_texture_formats ||= []
    end

    # TODO: find a better way to do this
    def create_mesh_implementation(mesh)
      OpenGLMesh.new(mesh, self)
    end

    def create_line_implementation(line)
      OpenGLLine.new(line, self)
    end

    def create_geometry_implementation(geometry)
      OpenGLGeometry.new(geometry, self)
    end

    def create_object3d_implementation(object)
      OpenGLObject3D.new(object, self)
    end

    def create_material_implementation(material)
      OpenGLMaterial.new(material, self)
    end

    def create_texture_implementation(texture)
      OpenGLTexture.new(texture, self)
    end

    def create_cube_texture_implementation(cube_texture)
      OpenGLCubeTexture.new(cube_texture, self)
    end

    def clamp_to_max_size(image, max_size = @_max_texture_size)
      width, height = image.width, image.height
      if width > max_size || height > max_size
        # TODO: scale the image ...

        puts "WARNING: Mittsu::OpenGLRenderer: image is too big (#{width} x #{height}). Resized to ??? x ???"
      end
      image
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
          material_impl = material.implementation(self)
        else
          material = opengl_object[:material]
          next unless material
          material_impl = material.implementation(self)
          material_impl.set
        end

        set_material_faces(material)
        if buffer.is_a? BufferGeometry
          # TODO
          # render_buffer_direct(camera, lights, fog, material, buffer, object)
        else
          render_buffer(camera, lights, fog, material, buffer.implementation(self), object)
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
            material_impl = material.implementation(self)
            material_impl.set
          end
          render_immediate_object(camera, lights, fog, material, object)
        end
      end
    end

    def init_object(object)
      object_impl = object.implementation(self)
      object_impl.init
    end

    def add_buffer(objlist, buffer, object)
      id = object.id
      (objlist[id] ||= []) << {
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
      object.implementation(self).setup_matrices(camera)
    end

    def update_object(object)
      geometry = object.geometry
      object_impl = object.implementation(self)

      if geometry.is_a? BufferGeometry
        # TODO: geometry vertex array ?????
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
      else
        object_impl.update
      end
      # TODO: when PointCloud exists
      # elsif object.is_A? PointCloud
      #   # TODO: glBindVertexArray ???
      #   material = object_impl.buffer_material(geometry)
      #   custom_attributes_dirty = material.attributes && are_custom_attributes_dirty(material)
      #
      #   if geometry.vertices_need_update || geometry.colors_need_update || custom_attributes_dirty
      #     set_particle_buffers(geometry, GL_DYNAMIC_DRAW, object)
      #   end
      #
      #   geometry.vertices_need_update = false
      #   geometry.colors_need_update = false
      #
      #   material.attributes && clear_custom_attributes(material)
      # end
    end

    def set_program(camera, lights, fog, material, object)
      @_used_texture_units = 0
      material_impl = material.implementation(self)

      if material.needs_update?
        deallocate_material(material) if material.program

        material_impl.init(lights, fog, object)
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
      m_uniforms = material_impl.shader[:uniforms]

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

        if @logarithmic_depth_buffer
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

        load_uniforms_generic(material_impl.uniforms_list)
      end

      load_uniforms_matrices(p_uniforms, object)

      if !p_uniforms['modelMatrix'].nil?
        glUniformMatrix4fv(p_uniforms['modelMatrix'], 1, GL_FALSE, array_to_ptr_easy(object.matrix_world.elements))
      end

      program
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

          if texture.is_a?(CubeTexture) || (texture.image.is_a?(Array) && texture.image.length == 6)
            texture_impl = texture.implementation(self)
            texture_impl.set(texture_unit)

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
      object.implementation(self).load_uniforms_matrices(uniforms)
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
  end
end
