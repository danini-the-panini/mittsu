require 'mittsu/math'
require 'mittsu/renderers/opengl_render_target'

module Mittsu
  class ShadowMapPlugin
    def initialize(renderer, lights, opengl_objects, opengl_objects_immediate)
      @renderer, @lights = renderer, lights
      @opengl_objects = opengl_objects
      @opengl_objects_immediate = opengl_objects_immediate

      @frustum = Frustum.new
      @proj_screen_matrix = Matrix4.new

      @min = Vector3.new
      @max = Vector3.new

      @matrix_position = Vector3.new

      @render_list = []

      depth_shader = ShaderLib[:depth_rgba]
      depth_uniforms = UniformsUtils.clone(depth_shader.uniforms)

      @depth_material = ShaderMaterial.new(
        uniforms: depth_uniforms,
        vertex_shader: depth_shader.vertex_shader,
        fragment_shader: depth_shader.fragment_shader
      )

      @depth_material_morph = ShaderMaterial.new(
        uniforms: depth_uniforms,
        vertex_shader: depth_shader.vertex_shader,
        fragment_shader: depth_shader.fragment_shader,
        morph_targets: true
      )

      @depth_material_skin = ShaderMaterial.new(
        uniforms: depth_uniforms,
        vertex_shader: depth_shader.vertex_shader,
        fragment_shader: depth_shader.fragment_shader,
        skinning: true
      )

      @depth_material_morph_skin = ShaderMaterial.new(
        uniforms: depth_uniforms,
        vertex_shader: depth_shader.vertex_shader,
        fragment_shader: depth_shader.fragment_shader,
        morph_targets: true,
        skinning: true
      )

      @depth_material.implementation(renderer).shadow_pass = true
      @depth_material_morph.implementation(renderer).shadow_pass = true
      @depth_material_skin.implementation(renderer).shadow_pass = true
      @depth_material_morph_skin.implementation(renderer).shadow_pass = true
    end

    def render(scene, camera)
      return unless @renderer.shadow_map_enabled

      lights = []
      fog = nil

      # set GL state for depth map

      glClearColor(1.0, 1.0, 1.0, 1.0)
      glDisable(GL_BLEND)

      glEnable(GL_CULL_FACE)
      glFrontFace(GL_CCW)

      if @renderer.shadow_map_cull_face = CullFaceFront
        glCullFace(GL_FRONT)
      else
        glCullFace(GL_BACK)
      end

      @renderer.state.set_depth_test(true)

      # process lights
      #  - skip lights that are not casting shadows
      #  - create virtual lights for cascaded shadow maps

      @lights.select(&:cast_shadow).each do |light|
        if light.is_a?(DirectionalLight) && light.shadow_cascade
          light.shadow_cascade_count.times do |n|
            if !light.shadow_cascade_array[n]
              virtual_light = create_virtual_light(light, n)
              virtual_light.original_camera = camera

              gyro = Gyroscope.new
              gyro.position.copy(light.shadow_cascade_offset)

              gyro.add(virtual_light)
              gyro.add(virtual_light.target)

              camera.add(gyro)

              light.shadow_cascade_array[n] = virtual_light
            else
              virtual_light = light.shadow_cascade_array[n]
            end

            update_virtual_light(light, n)

            lights << virtual_light
          end
        else
          lights << light
        end
      end

      # render depth map

      lights.each do |light|
        if !light.shadow_map
          shadow_filter = LinearFilter
          if @renderer.shadow_map_type == PCFSoftShadowMap
            shadow_filter = NearestFilter
          end

          pars = { min_filter: shadow_filter, mag_filter: shadow_filter, format: RGBAFormat }

          light.shadow_map = OpenGLRenderTarget.new(light.shadow_map_width, light.shadow_map_height, pars)
          light.shadow_map_size = Vector2.new(light.shadow_map_width, light.shadow_map_height)

          light.shadow_matrix = Matrix4.new
        end

        if !light.shadow_camera
          case light
          when SpotLight
            light.shadow_camera = PerspectiveCamera.new(light.shadow_camera_fov, light.shadow_map_width / light.shadow_map_height, light.shadow_camera_near, light.shadow_camera_far)
          when DirectionalLight
            light.shadow_camera = OrthographicCamera.new(light.shadow_camera_left, light.shadow_camera_right, light.shadow_camera_top, light.shadow_camera_bottom, light.shadow_camera_near, light.shadow_camera_far)
          else
            puts "ERROR: Mittsu::ShadowMapPlugin: Unsupported light type for shadow #{light.inspect}"
            next
          end

          scene.add(light.shadow_camera)
          scene.update_matrix_world if scene.auto_update
        end

        light_impl = light.implementation(@renderer)
        if light.shadow_camera_visible && !light_impl.camera_helper
          light_impl.camera_helper = CameraHelper.new(light.shadow_camera)
          scene.add(light_impl.camera_helper)
        end

        if light.virtual? && virtual_light.original_camera == camera
          update_shadow_camera(camera, light)
        end

        shadow_map = light.shadow_map
        shadow_matrix = light.shadow_matrix
        shadow_camera = light.shadow_camera

        #

        shadow_camera.position.set_from_matrix_position(light.matrix_world)
        @matrix_position.set_from_matrix_position(light.target.matrix_world)
        shadow_camera.look_at(@matrix_position)
        shadow_camera.update_matrix_world

        shadow_camera.matrix_world_inverse.inverse(shadow_camera.matrix_world)

        #


        light_impl.camera_helper.visible = light.shadow_camera_visible if light_impl.camera_helper
        light_impl.camera_helper.update if light.shadow_camera_visible

        # compute shadow matrix

        shadow_matrix.set(
          0.5, 0.0, 0.0, 0.5,
          0.0, 0.5, 0.0, 0.5,
          0.0, 0.0, 0.5, 0.5,
          0.0, 0.0, 0.0, 1.0
        )

        shadow_matrix.multiply(shadow_camera.projection_matrix)
        shadow_matrix.multiply(shadow_camera.matrix_world_inverse)

        # update camera matrices and frustum

        @proj_screen_matrix.multiply_matrices(shadow_camera.projection_matrix, shadow_camera.matrix_world_inverse)
        @frustum.set_from_matrix(@proj_screen_matrix)

        # render shadow map

        @renderer.set_render_target(shadow_map)
        @renderer.clear

        # set object matrices & frustum culling

        @render_list.clear

        project_object(scene, scene, shadow_camera)

        # render regular obejcts

        @render_list.each do |opengl_object|
          object = opengl_object[:object]
          buffer = opengl_object[:buffer]

          # culling is overridden globally for all objects
          # while rendering depth map

          # need to deal with MeshFaceMaterial somehow
          # in that case just use the first of material.materials for now
          # (proper solution would require to break objects by materials
          #  similarly to regular rendering and then set corresponding
          #  depth materials per each chunk instead of just once per object)

          object_material = get_object_material(object)

          # TODO: SkinnedMesh/morph_targets
          # use_morphing = !object.geometry.morph_targets.nil? && !object.geometry.morph_targets.empty?
          # use_skinning = object.is_a?(SkinnedMesh) && object_material.skinning

          # TODO: SkinnedMesh/morph_targets
          # if object.custom_depth_material
          #   material = object.custom_depth_material
          # elsif use_skinning
          #   material = use_morphing ? @depth_material_morph_skin : @depth_material_skin
          # elsif use_morphing
          #   material = @deptth_material_morph
          # else
            material = @depth_material
          # end

          @renderer.set_material_faces(object_material)

          if buffer.is_a?(BufferGeometry)
            @renderer.render_buffer_direct(shadow_camera, @lights, fog, material, buffer, object)
          else
            @renderer.render_buffer(shadow_camera, @lights, fog, material, buffer, object)
          end
        end

        # set materices and rendr immeidate objects

        @opengl_objects_immediate.each do |opengl_object_immediate|
          opengl_object = opengl_object_immediate
          object = opengl_object[:object]

          if object.visible && object.cast_shadow
            object[:_model_view_matrix].multiply_matrices(shadow_camera.matrix_womatrix_world_inverse, object.matrix_world)
            @renderer.render_immediate_object(shadow_camera, @lights, fog, @depth_material, object)
          end
        end
      end

      # restore GL state

      clear_color = @renderer.get_clear_color
      clear_alpha = @renderer.get_clear_alpha

      glClearColor(clear_color.r, clear_color.g, clear_color.b, clear_alpha)
      glEnable(GL_BLEND)

      if @renderer.shadow_map_cull_face == CullFaceFront
        glCullFace(GL_BACK)
      end

      @renderer.reset_gl_state
    end

    def project_object(scene, object, shadow_camera)
      if object.visible
        opengl_objects = @opengl_objects[object.id]

        if opengl_objects && object.cast_shadow && (object.frustum_culled == false || @frustum.intersects_object?(object) == true)
          opengl_objects.each do |opengl_object|
            object_impl = object.implementation(@renderer)
            object_impl.model_view_matrix.multiply_matrices(shadow_camera.matrix_world_inverse, object.matrix_world)
            @render_list << opengl_object
          end
        end

        object.children.each do |child|
          project_object(scene, child, shadow_camera)
        end
      end
    end

    def create_virtual_light(light, cascade)
      DirectionalLight.new.tap do |virtual_light|
        virtual_light.is_virtual = true

        virtual_light.only_shadow = true
        virtual_light.cast_shadow = true

        virtual_light.shadow_camera_near = light.shadow_camera_near
        virtual_light.shadow_camera_far = light.shadow_camera_far

        virtual_light.shadow_camera_left = light.shadow_camera_left
        virtual_light.shadow_camera_right = light.shadow_camera_right
        virtual_light.shadow_camera_bottom = light.shadow_camera_bottom
        virtual_light.shadow_camera_top = light.shadow_camera_top

        virtual_light.shadow_camera_visible = light.shadow_camera_visible

        virtual_light.shadow_darkness = light.shadow_darkness

        virtual_light.shadow_darkness = light.shadow_darkness

        virtual_light.shadow_bias = light.shadow_cascade_bias[cascade]
        virtual_light.shadow_map_width = light.shadow_cascade_width[cascade]
        virtual_light.shadow_map_height = light.shadow_cascade_height[cascade]

        points_world = virtual_light.points_world = []
        points_frustum = virtual_light.points_frustum = []

        8.times do
          points_world << Vector3.new
          points_frustum << Vector3.new
        end

        near_z = light.shadow_cascade_near_z[cascade]
        far_z = light.shadow_cascade_far_z[cascade]

        points_frustum[0].set(-1.0, -1.0, near_z)
        points_frustum[1].set( 1.0, -1.0, near_z)
        points_frustum[2].set(-1.0,  1.0, near_z)
        points_frustum[3].set( 1.0,  1.0, near_z)

        points_frustum[4].set(-1.0, -1.0, far_z)
        points_frustum[5].set( 1.0, -1.0, far_z)
        points_frustum[6].set(-1.0,  1.0, far_z)
        points_frustum[7].set( 1.0,  1.0, far_z)
      end
    end

    # synchronize virtual light with the original light

    def update_virtual_light(light, cascade)
      virtual_light = light.shadow_cascade_array[cascade]

      virtual_light.position.copy(light.position)
      virtual_light.target.position.copy(light.target.position)
      virtual_light.look_at(virtual_light.target)

      virtual_light.shadow_camera_visible = light.shadow_camera_visible
      virtual_light.shadow_darkness = light.shadow_darkness

      virtual_light.shadow_bias = light.shadow_cascade_bias[cascade]

      near_z = light.shadow_cascade_near_z[cascade]
      far_z = light.shadow_cascade_far_z[cascade]

      points_frustum = virtual_light.points_frustum

      points_frustum[0].z = near_z
      points_frustum[1].z = near_z
      points_frustum[2].z = near_z
      points_frustum[3].z = near_z

      points_frustum[4].z = far_z
      points_frustum[5].z = far_z
      points_frustum[6].z = far_z
      points_frustum[7].z = far_z
    end

    # fit shadow camera's ortho frustum to camera frustum

    def update_shadow_camera(camera, light)
      shadow_camera = light.shadow_camera
      points_frustum = light.pointa_frustum
      points_world = light.points_world

      @min.set(Float::INFINITY, Float::INFINITY, Float::INFINITY)
      @max.set(-Float::INFINITY, -Float::INFINITY, -Float::INFINITY)

      8.times do |i|
        p = points_world[i]

        p.copy(points_frustum[i])
        p.unproject(camera)

        p.apply_matrix4(shadow_camera.matrix_world_inverse)

        @min.x = p.x if (p.x < @min.x)
        @max.x = p.x if (p.x > @max.x)

        @min.y = p.y if (p.y < @min.y)
        @max.y = p.y if (p.y > @max.y)

        @min.z = p.z if (p.z < @min.z)
        @max.z = p.z if (p.z > @max.z)
      end

      shadow_camera.left = @min.x
      shadow_camera.right = @max.x
      shadow_camera.top = @max.y
      shadow_camera.bottom = @min.y

      # can't really fit near/far
      # shadow_camera.near = @min.x
      # shadow_camera.far = @max.z

      shadow_camera.update_projection_matrix
    end

    # For the moment just ignore objects that have multiple materials with different animation methods
    # Only the frst material will be taken into account for deciding which depth material to use for shadow maps

    def get_object_material(object)
      if object.material.is_a?(MeshFaceMaterial)
        object.material.materials[0]
      else
        object.material
      end
    end
  end
end
