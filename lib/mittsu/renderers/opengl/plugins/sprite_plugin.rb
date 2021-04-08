module Mittsu
  class SpritePlugin
    include OpenGLHelper

    VERTICES = [
      -0.5, -0.5, 0.0, 0.0,
       0.5, -0.5, 1.0, 0.0,
       0.5,  0.5, 1.0, 1.0,
      -0.5,  0.5, 0.0, 1.0
    ] # Float32Array

    FACES = [
      0, 1, 2,
      0, 2, 3
    ] # Uint16Array

    def initialize(renderer, sprites)
      @renderer = renderer
      @sprites = sprites
      @program = nil

      # for decomposing matrixWorld
      @sprite_position = Vector3.new
      @sprite_rotation = Quaternion.new
      @sprite_scale = Vector3.new
    end

    def render(scene, camera)
      return if @sprites.empty?

      init if @program.nil?
      setup_gl_for_render(camera)
      setup_fog(scene)

      update_positions_and_sort(camera)

      render_all_sprites(scene)

      glEnable(GL_CULL_FACE)
      @renderer.reset_gl_state
    end

    private

    def init
      create_vertex_array_object
      create_program

      init_attributes
      init_uniforms

      # TODO: canvas texture??
    end

    def create_vertex_array_object
      @vertex_array_object = glCreateVertexArray
      glBindVertexArray(@vertex_array_object)

      @vertex_buffer = glCreateBuffer
      @element_buffer = glCreateBuffer

      glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)
      glBufferData_easy(GL_ARRAY_BUFFER, VERTICES, GL_STATIC_DRAW)

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @element_buffer)
      glBufferData_easy(GL_ELEMENT_ARRAY_BUFFER, FACES, GL_STATIC_DRAW)
    end

    def create_program
      @program = glCreateProgram

      vertex_shader = OpenGLShader.new(GL_VERTEX_SHADER, File.read(File.join(__dir__, 'sprite_vertex.glsl')))
      fragment_shader = OpenGLShader.new(GL_FRAGMENT_SHADER, File.read(File.join(__dir__, 'sprite_fragment.glsl')))

      glAttachShader(@program, vertex_shader.shader)
      glAttachShader(@program, fragment_shader.shader)

      glLinkProgram(@program)
    end

    def init_attributes
      @attributes = {
        position: glGetAttribLocation(@program, 'position'),
        uv: glGetAttribLocation(@program, 'uv')
      }
    end

    def init_uniforms
      @uniforms = {
        uvOffset: glGetUniformLocation(@program, 'uvOffset'),
        uvScale: glGetUniformLocation(@program, 'uvScale'),

        rotation: glGetUniformLocation(@program, 'rotation'),
        scale: glGetUniformLocation(@program, 'scale'),

        color: glGetUniformLocation(@program, 'color'),
        map: glGetUniformLocation(@program, 'map'),
        opacity: glGetUniformLocation(@program, 'opacity'),

        modelViewMatrix: glGetUniformLocation(@program, 'modelViewMatrix'),
        projectionMatrix: glGetUniformLocation(@program, 'projectionMatrix'),

        fogType: glGetUniformLocation(@program, 'fogType'),
        fogDensity: glGetUniformLocation(@program, 'fogDensity'),
        fogNear: glGetUniformLocation(@program, 'fogNear'),
        fogFar: glGetUniformLocation(@program, 'fogFar'),
        fogColor: glGetUniformLocation(@program, 'fogColor'),

        alphaTest: glGetUniformLocation(@program, 'alphaTest')
      }
    end

    def painter_sort_stable(a, b)
      if a.z != b.z
        b.z - a.z
      else
        b.id - a.id
      end
    end

    def setup_gl_for_render(camera)
      glUseProgram(@program)

      glDisable(GL_CULL_FACE)
      glEnable(GL_BLEND)

      glBindVertexArray(@vertex_array_object)

      glEnableVertexAttribArray(@attributes[:position])
      glEnableVertexAttribArray(@attributes[:uv])

      glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)

      glVertexAttribPointer(@attributes[:position], 2, GL_FLOAT, GL_FALSE, 2 * 8, Fiddle::Pointer[0])
      glVertexAttribPointer(@attributes[:uv], 2, GL_FLOAT, GL_FALSE, 2 * 8, Fiddle::Pointer[8])

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @element_buffer)

      glUniformMatrix4fv(@uniforms[:projectionMatrix], 1, GL_FALSE, array_to_ptr_easy(camera.projection_matrix.elements))

      glActiveTexture(GL_TEXTURE0)
      glUniform1i(@uniforms[:map], 0)
    end

    def setup_fog(scene)
      @old_fog_type = 0
      @scene_fog_type = 0
      fog = scene.fog

      if fog
        glUniform3f(@uniforms[:fogColor], fog.color.r, fog.color.g, fog.color.b)

        if fog.is_a?(Fog)
          glUniform1f(@uniforms[:fogNear], fog.near)
          glUniform1f(@uniforms[:fogFar], fog.far)

          glUniform1i(@uniforms[:fogType], 1)
          @old_fog_type = 1
          @scene_fog_type = 1
        elsif fog.is_a?(FogExp2)
          glUniform1f(@uniforms[:fogDensity], fog.density)

          glUniform1i(@uniforms[:fogType], 2)
          @old_fog_type = 2
          @scene_fog_type = 2
        end
      else
        glUniform1i(@uniforms[:fogType], 0)
        @old_fog_type = 0
        @scene_fog_type = 0
      end
    end

    def update_positions_and_sort(camera)
      @sprites.each do |sprite|
        sprite.model_view_matrix.multiply_matrices(camera.matrix_world_inverse, sprite.matrix_world)
        sprite.z = -sprite.model_view_matrix.elements[14]
      end

      @sprites.sort!(&self.method(:painter_sort_stable))
    end

    def render_all_sprites(scene)
      @sprites.each do |sprite|
        material = sprite.material

        set_fog_uniforms(material, scene)
        set_uv_uniforms(material)
        set_color_uniforms(material)
        set_transform_uniforms(sprite)
        set_blend_mode(material)

        # set texture
        if material.map && material.map.image && material.map.image.width
          material.map.set(0, @renderer)
        else
          # TODO: canvas texture?
          # texture.set(0, @renderer)
        end

        # draw elements
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0) # GL_UNSIGNED_SHORT
      end
    end

    def set_fog_uniforms(material, scene)
      fog_type = 0

      if scene.fog && material.fog
        fog_type = @scene_fog_type
      end

      if @old_fog_type != fog_type
        glUniform1(@uniforms[:fogType], fog_type)
        @old_fog_type = fog_type
      end
    end

    def set_uv_uniforms(material)
      if !material.map.nil?
        glUniform2f(@uniforms[:uvOffset], material.map.offset.x, material.map.offset.y)
        glUniform2f(@uniforms[:uvScale], material.map.repeat.x, material.map.repeat.y)
      else
        glUniform2f(@uniforms[:uvOffset], 0.0, 0.0)
        glUniform2f(@uniforms[:uvScale], 1.0, 1.0)
      end
    end

    def set_color_uniforms(material)
      glUniform1f(@uniforms[:opacity], material.opacity)
      glUniform3f(@uniforms[:color], material.color.r, material.color.g, material.color.b)
      glUniform1f(@uniforms[:alphaTest], material.alpha_test)
    end

    def set_transform_uniforms(sprite)
      glUniformMatrix4fv(@uniforms[:modelViewMatrix], 1, GL_FALSE, array_to_ptr_easy(sprite.model_view_matrix.elements))

      sprite.matrix_world.decompose(@sprite_position, @sprite_rotation, @sprite_scale)

      glUniform1f(@uniforms[:rotation], sprite.material.rotation)
      glUniform2fv(@uniforms[:scale], 1, array_to_ptr_easy([@sprite_scale.x, @sprite_scale.y]))
    end

    def set_blend_mode(material)
      @renderer.state.set_blending(material.blending, material.blend_equation, material.blend_src, material.blend_dst)
      @renderer.state.set_depth_test(material.depth_test)
      @renderer.state.set_depth_write(material.depth_write)
    end
  end
end
