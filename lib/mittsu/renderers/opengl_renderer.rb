require 'mittsu'

require 'opengl'
require 'glfw'
require 'mittsu/renderers/glfw_window'

OpenGL.load_lib

include OpenGL
include GLFW

module Mittsu
  class OpenGLRenderer
    attr_accessor :context, :auto_clear, :auto_clear_color, :auto_clear_depth, :auto_clear_stencil, :sort_objects, :gamma_factor, :gamma_input, :gamma_output, :shadow_map_enabled, :shadow_map_type, :shadow_map_cull_face, :shadow_map_debug, :shadow_map_cascade, :max_morph_targets, :max_morph_normals, :info, :pixel_ratio, :window, :width, :height

    attr_reader :prevision

    def initialize(parameters = {})
      puts "OpenGLRenderer #{REVISION}"

      @pixel_ratio = 1.0

      @precision = parameters.fetch(:precision, 'highp') # not sure if OpenGL works with the whole 'highp' thing...
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
      @context = nil

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
      @_viewport_width = 0 # TODO: _canvas.width???
      @_viewport_height = 0 # TODO: ...height???
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

        # TODO: create a window...???
        @window = GLFW::Window.new(@width, @height, @title)
        # TODO: handle losing opengl context??
      rescue => error
        puts "ERROR: Mittsu::OpenGLRenderer: #{error.inspect}"
      end

      # TODO: get shader precision format???
      # TODO: load extensions??

      # glfwWindowHint GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE
      # glfwWindowHint GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE
      # glfwWindowHint GLFW_CONTEXT_VERSION_MAJOR, 3
      # glfwWindowHint GLFW_CONTEXT_VERSION_MINOR, 3
      # glfwWindowHint GLFW_CONTEXT_REVISION, 0

      set_default_gl_state

      # @context = _gl ???
      # @state = state .... ???

      # GPU capabilities

      @_max_textures = get_gl_parameter(GL_MAX_TEXTURE_IMAGE_UNITS)
      @_max_vertex_textures = get_gl_parameter(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS)
      @_max_texture_size = get_gl_parameter(GL_MAX_TEXTURE_SIZE)
      @_max_cubemap_size = get_gl_parameter(GL_MAX_CUBE_MAP_TEXTURE_SIZE)

      @_supports_vertex_textures = @_max_vertex_textures > 0
      @_supports_bone_textures = @_supports_vertex_textures && false # TODO: extensions.get('OES_texture_float') ????

      #

      # TODO: get more shader precision formats ???

      # TODO: clear precision to maximum available ???

      # Plugins

      # TODO: when plugins are ready
      # @shadow_map_plugin = ShadowMapPlugin(self, @lights, @_opengl_objects, @_opengl_objects_immediate)
      #
      # @sprite_plugin = SpritePlugin(self, @sprites)
      # @lens_flare_plugin = LensFlarePlugin(self, @lens_flares)
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

      # state.reset # TODO: ???
    end

    def set_render_target(render_taget = nil)
      # TODO: LOOONG-ASS METHOD!!
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
      # TODO: when plugins are ready
      # @shadow_map_plugin.render(scene, camera)

      #

      @info[:render][:calls] = 0
      @info[:render][:vertices] = 0
      @info[:render][:faces] = 0
      @info[:render][:points] = 0

      set_render_target(render_target)

      if auto_clear || force_clear
        clear(auto_clear_color, auto_clear_depth, auto_clear_stencil)
      end

      # set matrices for immediate objects

      @_opengl_objects_immediate.each do |opengl_object|
        object = opengl_object.object

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

        # state.set_blending(NoBlending) # TODO: what is this "State?"

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

      # TODO: state object again ????
      # state.set_depth_test(true)
      # state.set_depth_write(true)
      # state.set_color_write(true)

      #glFinish ??????
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
      if a.object.render_order != b.object.render_order
        a.object.render_order - b.object.render_order
      elsif a.material.id != b.material.id
        a.material.id - b.material.id
      elsif a.z != b.z
        a.z - b.z
      else
        a.id - b.id
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
        # if object.is_a? Light
        # if object.is_a? Sprite
        # if object.is_a? LensFlare
        # else
          opengl_objects = @_opengl_objects[object.id]
          if opengl_objects && (!object.frustum_culled || _frustum.intersectsObject(object))
            opengl_objects.each do |opengl_object|
              unroll_buffer_material(opengl_object)
              opengl_object.render = true
              if @sort_objects
                @_vector3.set_from_matrix_position(object.matrix_world)
                @_vector3.apply_projection(@_proj_screen_matrix)

                opengl_object.z = @_vector.z
              end
            end
          end
        #end
      end

      object.children.each do |child|
        render_object(child)
      end
    end

    def render_objects(render_list, camera, lights, fog, override_material)
      material = nil
      render_list.each do |opengl_object|
        object = opengl_object.object
        buffer = opengl_object.buffer

        setup_matrices(object, camera)

        if override_material
          material = override_material
        else
          material = opengl_object.material
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
        object = opengl_object.object
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
  end
end
