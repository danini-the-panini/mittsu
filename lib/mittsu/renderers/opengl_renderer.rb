require 'opengl'
require 'glfw'
require 'fiddle'

OpenGL.load_lib

require 'mittsu'
require 'mittsu/renderers/glfw_window'
require 'mittsu/renderers/opengl/opengl_implementations'
require 'mittsu/renderers/opengl/opengl_debug'
require 'mittsu/renderers/opengl/opengl_helper'
require 'mittsu/renderers/opengl/opengl_program'
require 'mittsu/renderers/opengl/opengl_state'
require 'mittsu/renderers/opengl/opengl_geometry_group'
require 'mittsu/renderers/opengl/opengl_light_renderer'
require 'mittsu/renderers/opengl/opengl_default_target'
require 'mittsu/renderers/opengl/opengl_buffer'
require 'mittsu/renderers/opengl/plugins/shadow_map_plugin'
require 'mittsu/renderers/shaders/shader_lib'
require 'mittsu/renderers/shaders/uniforms_utils'

include ENV['DEBUG'] ? OpenGLDebug : OpenGL
include Mittsu::OpenGLHelper

require 'mittsu/renderers/opengl/opengl_mittsu_params'

module Mittsu
  class OpenGLRenderer
    attr_accessor :auto_clear, :auto_clear_color, :auto_clear_depth, :auto_clear_stencil, :sort_objects, :gamma_factor, :gamma_input, :gamma_output, :shadow_map_enabled, :shadow_map_type, :shadow_map_cull_face, :shadow_map_debug, :shadow_map_cascade, :max_morph_targets, :max_morph_normals, :info, :pixel_ratio, :window, :width, :height, :state

    attr_reader :logarithmic_depth_buffer, :max_morph_targets, :max_morph_normals, :shadow_map_type, :shadow_map_debug, :shadow_map_cascade, :programs, :light_renderer, :proj_screen_matrix

    def initialize(parameters = {})
      puts "OpenGLRenderer (Revision #{REVISION})"

      fetch_parameters(parameters)

      @pixel_ratio = 1.0
      @sort_objects = true

      init_collections
      init_clearing
      init_gamma
      init_shadow_properties
      init_morphs
      init_info
      init_state_cache
      init_camera_matrix_cache

      @light_renderer = OpenGLLightRenderer.new(self)

      create_window

      @state = OpenGLState.new

      # TODO: load extensions??

      reset_gl_state
      set_default_gl_state

      get_gpu_capabilities

      init_plugins
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
      default_target.set_and_use_viewport(
        x * pixel_ratio,
        y * pixel_ratio,
        width * pixel_ratio,
        height * pixel_ratio
      )
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

    def object_in_frustum?(object)
      @_frustum.intersects_object?(object)
    end

    def sort_objects?
      @sort_objects
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

      @light_renderer.reset

      @state.reset
    end

    def set_render_target(render_target = default_target)
      # TODO: when OpenGLRenderTargetCube exists
      # is_cube = render_target.is_a? OpenGLRenderTargetCube

      render_target_impl = render_target.implementation(self)

      # TODO framebuffer logic for render target cube
      render_target_impl.setup_buffers

      if render_target != @_current_render_target
        render_target.use
        @_current_render_target = render_target
      end
    end

    def render(scene, camera, render_target = default_target, force_clear = false)
      raise "ERROR: Mittsu::OpenGLRenderer#render: camera is not an instance of Mittsu::Camera" unless camera.is_a?(Camera)

      reset_cache_for_this_frame

      scene.update_matrix_world if scene.auto_update
      camera.update_matrix_world if camera.parent.nil?

      update_skeleton_objects(scene)

      update_screen_projection(camera)
      scene.implementation(self).project
      sort_objects_for_render if @sort_objects

      render_custom_plugins_pre_pass(scene, camera)

      set_matrices_for_immediate_objects(camera)

      set_render_target(render_target)
      perform_auto_clear if @auto_clear || force_clear
      render_main_pass(scene, camera)

      render_custom_plugins_post_pass(scene, camera)

      render_target.implementation(self).update_mipmap

      ensure_depth_buffer_writing
    end

    def set_material_faces(material)
      @state.set_double_sided(material.side == DoubleSide)
      @state.set_flip_sided(material.side == BackSide)
    end

    def render_buffer(camera, lights, fog, material, geometry_group, object)
      return unless material.visible

      geometry_group.bind_vertex_array_object

      update_object(object)

      program = set_program(camera, lights, fog, material, object)
      attributes = program.attributes
      buffers_need_update = switch_geometry_program(program, material, geometry_group)

      @state.init_attributes if buffers_need_update

      if !material.morph_targets && attributes['position'] && attributes['position'] >= 0
        geometry_group.update_vertex_buffer(attributes['position']) if buffers_need_update
      elsif object.morph_target_base
        # TODO: when morphing is implemented
        # setup_morph_targets(material, geometry_group, object)
      end

      if buffers_need_update
        geometry_group.update_other_buffers(object, material, attributes)
      end

      @state.disable_unused_attributes

      object.implementation(self).render_buffer(camera, lights, fog, material, geometry_group, buffers_need_update)

      # TODO: render particles
      # when PointCloud
      #   glDrawArrays(GL_POINTS, 0, geometry_group.particle_count)
      #
      #   @info[:render][:calls] += 1
      #   @info[:render][:points] += geometry_group.particle_count
    end

    def compressed_texture_formats
      # TODO: needs extensions.get ...

      @_compressed_texture_formats ||= []
    end

    # Events

    def on_object_removed(event)
      object = event.target
      object.traverse do |child|
        child.remove_event_listener(:remove, method(:on_object_removed))
        remove_child(child)
      end
    end

    def on_geometry_dispose(event)
      geometry = event.target
      geometry.remove_event_listener(:dispose, method(:on_geometry_dispose))
      deallocate_geometry(geometry)
    end

    def on_texture_dispose(event)
      texture = event.target
      texture.remove_event_listener(:dispose, method(:on_texture_dispose))
      deallocate_texture(texture)
      @info[:memory][:textures] -= 1
    end

    def on_render_target_dispose(event)
      render_target = event.target
      render_target.remove_event_listener(:dispose, method(:on_render_target_dispose))
      deallocate_render_target(render_target)
      @info[:memory][:textures] -= 1
    end

    def on_material_dispose(event)
      material = event.target
      material.remove_event_listener(:dispose, method(:on_material_dispose))
      deallocate_material(material)
    end

    def create_implementation(thing)
      OPENGL_IMPLEMENTATIONS[thing.class].new(thing, self)
    end

    def clamp_to_max_size(image, max_size = @_max_texture_size)
      width, height = image.width, image.height
      if width > max_size || height > max_size
        # TODO: scale the image ...

        puts "WARNING: Mittsu::OpenGLRenderer: image is too big (#{width} x #{height}). Resized to ??? x ???"
      end
      image
    end

    def add_opengl_object(buffer, object)
      add_buffer(@_opengl_objects, buffer, object)
    end

    def remove_opengl_object(object)
      @_opengl_objects.delete(object.id)
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

      default_target.use_viewport

      clear_color(@_clear_color.r, @_clear_color.g, @_clear_color.b, @_clear_alpha)
    end

    def render_objects(render_list, camera, lights, fog, override_material)
      material = nil
      render_list.each do |opengl_object|
        object = opengl_object.object
        buffer = opengl_object.buffer

        object.implementation(self).setup_matrices(camera)

        if override_material
          material = override_material
          material_impl = material.implementation(self)
        else
          material = opengl_object.material
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
        object = opengl_object.object
        if object.visible
          if override_material
            material = override_material
          else
            material = case material_type
            when :transparent then opengl_object.transparent
            when :opaque then opengl_object.opaque
            else nil
            end
            next unless material
            material_impl = material.implementation(self)
            material_impl.set
          end
          render_immediate_object(camera, lights, fog, material, object)
        end
      end
    end

    def add_buffer(objlist, buffer, object)
      id = object.id
      (objlist[id] ||= []) << OpenGLBuffer.new(
        buffer, object, nil, 0
      )
    end

    def unroll_immediate_buffer_material(opengl_object)
  		object = opengl_object.object
  		material = object.material

  		if material.transparent
  			opengl_object.transparent
  			opengl_object.opaque = nil
  		else
  			opengl_object.opaque = material
  			opengl_object.transparent = nil
  		end
    end

    def unroll_buffer_material(opengl_object)
      object = opengl_object.object
      buffer = opengl_object.buffer

      geometry = object.geometry
      material = object.material

      if material
        if material.is_a? MeshFaceMaterial
          material_index = geometry.is_a?(BufferGeometry) ? 0 : buffer.material_index
          material = material.materials[material_index]
        end

        opengl_object.material = material

        if material.transparent
          @transparent_objects << opengl_object
        else
          @opaque_objects << opengl_object
        end
      end
    end

    # FIXME: refactor
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

    # FIXME: refactor
    def set_program(camera, lights, fog, material, object)
      @_used_texture_units = 0
      material_impl = material.implementation(self)
      object_impl = object.implementation(self)

      if material.needs_update?
        deallocate_material(material) if material.program

        material_impl.init(lights, fog, object)
        material.needs_update = false
      end

      if material.morph_targets
        if !object_impl.morph_target_influences
          object_impl.morph_target_influences = Array.new(@max_morph_targets) # Float32Array
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
            object.skeleton.bone_texture.implementation(self).set(texture_unit)
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
        # TODO: when fog is implemented
        # refresh_uniforms_fog(m_uniforms, fog) if fog && material.fog

        if material.is_a?(MeshPhongMaterial) || material.is_a?(MeshLambertMaterial) || material.lights
          if @light_renderer.lights_need_update
            refresh_lights = true
            @light_renderer.setup(lights)
          end

          if refresh_lights
            OpenGLHelper.refresh_uniforms_lights(m_uniforms, @light_renderer.cache)
            OpenGLHelper.mark_uniforms_lights_needs_update(m_uniforms, true)
          else
            OpenGLHelper.mark_uniforms_lights_needs_update(m_uniforms, false)
          end
        end

        if material.is_a?(MeshBasicMaterial) || material.is_a?(MeshLambertMaterial) || material.is_a?(MeshPhongMaterial)
          OpenGLHelper.refresh_uniforms_common(m_uniforms, material)
        end

        # refresh single material specific uniforms

        # TODO: when all of these things exist
        case material
        when LineBasicMaterial
          OpenGLHelper.refresh_uniforms_line(m_uniforms, material)
        # when LineDashedMaterial
        #   refresh_uniforms_line(m_uniforms, material)
        #   refresh_uniforms_dash(m_uniforms, material)
        # when PointCloudMaterial
        #   refresh_uniforms_particle(m_uniforms, material)
        when MeshPhongMaterial
          OpenGLHelper.refresh_uniforms_phong(m_uniforms, material)
        when MeshLambertMaterial
          OpenGLHelper.refresh_uniforms_lambert(m_uniforms, material)
        # when MeshDepthMaterial
        #   m_uniforms.m_near.value = camera.near
        #   m_uniforms.m_far.value = camera.far
        #   m_uniforms.opacity.value = material.opacity
        # when MeshNormalMaterial
        #   m_uniforms.opactity.value = material.opacity
        end

        if object.receive_shadow && !material_impl.shadow_pass
          OpenGLHelper.refresh_uniforms_shadow(m_uniforms, lights)
        end

        load_uniforms_generic(material_impl.uniforms_list)
      end

      object.implementation(self).load_uniforms_matrices(p_uniforms)

      if !p_uniforms['modelMatrix'].nil?
        glUniformMatrix4fv(p_uniforms['modelMatrix'], 1, GL_FALSE, array_to_ptr_easy(object.matrix_world.elements))
      end

      program
    end

    # FIXME: REFACTOR!?!?!?!?!???
    # MASSIVE CASE STATEMENT OMG!!!
    def load_uniforms_generic(uniforms)
      uniforms.each do |(uniform, location)|
        # needs_update property is not added to all uniforms.
        next if uniform.needs_update == false || location == -1

        type = uniform.type
        value = uniform.value

        # AAAAAHHHHH!!!!! \o/ *flips table*
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
          uniform.array ||= Array.new(2 * value.length) # Float32Array

          value.each_with_index do |v, i|
            offset = i * 2
            uniform.array[offset] = v.x
            uniform.array[offset + 1] = v.y
          end

          glUniform2fv(location, value.length * 2, array_to_ptr_easy(uniform.array))
        when :v3v
          # array of Mittsu::Vector3
          uniform.array ||= Array.new(3 * value.length) # Float32Array

          value.each_with_index do |v, i|
            offset = i * 3
            uniform.array[offset] = v.x
            uniform.array[offset + 1] = v.y
            uniform.array[offset + 2] = v.z
          end

          glUniform3fv(location, value.length * 3, array_to_ptr_easy(uniform.array))
        when :v4v
          # array of Mittsu::Vector4
          uniform.array ||= Array.new(4 * value.length) # Float32Array

          value.each_with_index do |v, i|
            offset = i * 4
            uniform.array[offset] = v.x
            uniform.array[offset + 1] = v.y
            uniform.array[offset + 2] = v.z
            uniform.array[offset + 3] = v.w
          end

          glUniform4fv(location, value.length * 4, array_to_ptr_easy(uniform.array))
        when :m3
          # single Mittsu::Matrix3
          glUniformMatrix3fv(location, 1, GL_FALSE, array_to_ptr_easy(value.elements))
        when :m3v
          # array of Mittsu::Matrix3
          uniform.array ||= Array.new(9 * value.length) # Float32Array

          value.each_with_index do |v, i|
            value[i].flatten_to_array_offset(uniform.array, i * 9)
          end

          glUniformMatrix3fv(location, value.length, GL_FALSE, array_to_ptr_easy(uniform.array))
        when :m4
          # single Mittsu::Matrix4
          glUniformMatrix4vf(location, 1, GL_FALSE, array_to_ptr_easy(value.elements))
        when :m4v
          # array of Mittsu::Matrix4
          uniform.array ||= Array.new(16 * value.length) # Float32Array

          value.each_with_index do |v, i|
            value[i].flatten_to_array_offset(uniform.array, i * 16)
          end

          glUniformMatrix4fv(location, value.length, GL_FALSE, array_to_ptr_easy(uniform.array))
        when :t
          # single Mittsu::Texture (2d or cube)
          texture = value
          texture_unit = get_texture_unit

          glUniform1i(location, texture_unit)

          next unless texture

          texture_impl = texture.implementation(self)
          texture_impl.set(texture_unit)
          # TODO: when OpenGLRenderTargetCube is defined
          # elsif texture.is_a?(OpenGLRenderTargetCube)
            # set_cube_texture_dynamic(texture, texture_unit)
        when :tv
          # array of Mittsu::Texture (2d)
          uniform.array ||= []

          uniform.value.each_index do |i|
            uniform.array[i] = get_texture_unit
          end

          glUniform1iv(location, uniform.array.length, array_to_ptr_easy(uniform.array))

          uniform.value.each_with_index do |tex, i|
            tex_unit = uniform.array[i]

            next unless tex

            tex.implementation(self).set(tex_unit)
          end
        else
          puts "WARNING: Mittsu::OpenGLRenderer: Unknown uniform type: #{type}"
        end
      end
    end

    def get_texture_unit
      texture_unit = @_used_texture_units

      if texture_unit >= @_max_textures
        puts "WARNING: OpenGLRenderer: trying to use #{texture_unit} texture units while this GPU supports only #{@_max_textures}"
      end

      @_used_texture_units += 1
      texture_unit
    end

    def ensure_depth_buffer_writing
      @state.set_depth_test(true)
      @state.set_depth_write(true)
      @state.set_color_write(true)
    end

    def reset_cache
      @_current_geometry_program = ''
      @_current_material_id = -1
      @_current_camera = nil
      @light_renderer.reset
    end

    def reset_objects_cache
      @lights.clear
      @opaque_objects.clear
      @transparent_objects.clear
      @sprites.clear
      @lens_flares.clear
    end

    def reset_info
      @info[:render][:calls] = 0
      @info[:render][:vertices] = 0
      @info[:render][:faces] = 0
      @info[:render][:points] = 0
    end

    def reset_cache_for_this_frame
      reset_cache
      reset_objects_cache
      reset_info
    end

    def update_screen_projection(camera)
      camera.matrix_world_inverse.inverse(camera.matrix_world)

      @proj_screen_matrix.multiply_matrices(camera.projection_matrix, camera.matrix_world_inverse)
      @_frustum.set_from_matrix(@proj_screen_matrix)
    end

    def sort_objects_for_render
      @opaque_objects.sort { |a,b| OpenGLHelper.painter_sort_stable(a,b) }
      @transparent_objects.sort { |a,b| OpenGLHelper.reverse_painter_sort_stable(a,b) }
    end

    def set_matrices_for_immediate_objects(camera)
      @_opengl_objects_immediate.each do |opengl_object|
        object = opengl_object.object

        if object.visible
          object.implementation(self).setup_matrices(camera)
          unroll_immediate_buffer_material(opengl_object)
        end
      end
    end

    def render_main_pass(scene, camera)
      if scene.override_material
        render_with_override_material(scene, camera)
      else
        render_with_default_materials(scene, camera)
      end
    end

    def render_with_override_material(scene, camera)
      override_material = scene.override_material
      material_impl = override_material.implementation(self)

      material_impl.set

      render_objects(@opaque_objects, camera, @lights, scene.fog, override_material)
      render_objects(@transparent_objects, camera, @lights, scene.fog, override_material)
      render_objects_immediate(@_opengl_objects_immediate, nil, camera, @lights, scene.fog, override_material)
    end

    def render_with_default_materials(scene, camera)
      render_opaque_pass(scene, camera)
      render_transparent_pass(scene, camera)
    end

    def render_opaque_pass(scene, camera)
      # front-to-back order
      @state.set_blending(NoBlending)

      render_objects(@opaque_objects, camera, @lights, scene.fog, nil)
      render_objects_immediate(@_opengl_objects_immediate, :opaque, camera, @lights, scene.fog, nil)
    end

    def render_transparent_pass(scene, camera)
      # back-to-front-order
      render_objects(@transparent_objects, camera, @lights, scene.fog, nil)
      render_objects_immediate(@_opengl_objects_immediate, :transparent, camera, @lights, scene.fog, nil)
    end

    def render_custom_plugins_pre_pass(scene, camera)
      @shadow_map_plugin.render(scene, camera)
    end

    def render_custom_plugins_post_pass(scene, camera)
      # TODO: when these custom plugins are implemented
      # @sprite_plugin.render(scene, camera)
      # lens_flare_plugin.render(scene, camera, @_current_render_target.width, @_current_render_target.height)
    end

    def update_skeleton_objects(scene)
      # TODO: when SkinnedMesh is defined
      # scene.traverse do |object|
      #   if object.is_a? SkinnedMesh
      #     object.skeleton.update
      #   end
      # end
    end

    def perform_auto_clear
      clear(@auto_clear_color, @auto_clear_depth, @auto_clear_stencil)
    end

    def init_clearing
      @_clear_color = Color.new(0x000000)
      @_clear_alpha = 0.0

      @auto_clear = true
      @auto_clear_color = true
      @auto_clear_depth = true
      @auto_clear_stencil = true
    end

    def init_gamma
      @gamma_factor = 2.0 # backwards compat???
      @gamma_input = false
      @gamma_output = false
    end

    def init_shadow_properties
      @shadow_map_enabled = false
      @shadow_map_type = PCFShadowMap
      @shadow_map_cull_face = CullFaceFront
      @shadow_map_debug = false
      @shadow_map_cascade = false
    end

    def init_morphs
      @max_morph_targets = 8
      @max_morph_normals = 4
    end

    def init_collections
      @lights = []

      @_opengl_objects = {}
      @_opengl_objects_immediate = []

      @opaque_objects = []
      @transparent_objects = []

      @sprites = []
      @lens_flares = []

      @programs = []
    end

    def init_info
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
    end

    def init_state_cache
      @_current_program = nil
      @_current_render_target = default_target
      @_current_material_id = -1
      @_current_geometry_program = ''
      @_current_camera = nil

      @_used_texture_units = 0
    end

    def init_camera_matrix_cache
      @_frustum = Frustum.new
      @proj_screen_matrix = Matrix4.new
      @_vector3 = Vector3.new
    end

    def fetch_parameters(parameters)
      @_alpha = parameters.fetch(:alpha, false)
      @_depth = parameters.fetch(:depth, true)
      @_stencil = parameters.fetch(:stencil, true)
      @_antialias = parameters.fetch(:antialias, false)
      @_premultiplied_alpha = parameters.fetch(:premultiplied_alpha, true)
      @_preserve_drawing_buffer = parameters.fetch(:preserve_drawing_buffer, false)
      @logarithmic_depth_buffer = parameters.fetch(:logarithmic_depth_buffer, false)

      @width = parameters.fetch(:width, 800)
      @height = parameters.fetch(:height, 600)
      @title = parameters.fetch(:title, "Mittsu #{REVISION}")
    end

    def get_gpu_capabilities
      @_max_textures = glGetParameter(GL_MAX_TEXTURE_IMAGE_UNITS)
      @_max_vertex_textures = glGetParameter(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS)
      @_max_texture_size = glGetParameter(GL_MAX_TEXTURE_SIZE)
      @_max_cubemap_size = glGetParameter(GL_MAX_CUBE_MAP_TEXTURE_SIZE)

      @_supports_vertex_textures = @_max_vertex_textures > 0
      @_supports_bone_textures = @_supports_vertex_textures && false # TODO: extensions.get('OES_texture_float') ????
    end

    def init_plugins
      @shadow_map_plugin = ShadowMapPlugin.new(self, @lights, @_opengl_objects, @_opengl_objects_immediate)

      # TODO: when these custom plugins are implemented
      # @sprite_plugin = SpritePlugin.new(self, @sprites)
      # @lens_flare_plugin = LensFlarePlugin.new(self, @lens_flares)
    end

    def create_window
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

        default_target.set_viewport_size(*(@window.framebuffer_size))

        # TODO: handle losing opengl context??
      rescue => error
        puts "ERROR: Mittsu::OpenGLRenderer: #{error.inspect}"
      end
    end

    def switch_geometry_program(program, material, geometry_group)
      wireframe_bit = material.wireframe ? 1 : 0
      geometry_program = "#{geometry_group.id}_#{program.id}_#{wireframe_bit}"

      if geometry_program != @_current_geometry_program
        @_current_geometry_program = geometry_program
        true
      else
        false
      end
    end

    def default_target
      @_defualt_target ||= OpenGLDefaultTarget.new(self)
    end
  end
end
