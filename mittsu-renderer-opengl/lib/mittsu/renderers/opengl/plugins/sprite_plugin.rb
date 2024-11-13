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

      GL.Enable(GL::CULL_FACE)
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
      @vertex_array_object = GL.CreateVertexArray
      GL.BindVertexArray(@vertex_array_object)

      @vertex_buffer = GL.CreateBuffer
      @element_buffer = GL.CreateBuffer

      GL.BindBuffer(GL::ARRAY_BUFFER, @vertex_buffer)
      GL.BufferData_easy(GL::ARRAY_BUFFER, VERTICES, GL::STATIC_DRAW)

      GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, @element_buffer)
      GL.BufferData_easy(GL::ELEMENT_ARRAY_BUFFER, FACES, GL::STATIC_DRAW)
    end

    def create_program
      @program = GL.CreateProgram

      vertex_shader = OpenGLShader.new(GL::VERTEX_SHADER, File.read(File.join(__dir__, 'sprite_vertex.glsl')))
      fragment_shader = OpenGLShader.new(GL::FRAGMENT_SHADER, File.read(File.join(__dir__, 'sprite_fragment.glsl')))

      GL.AttachShader(@program, vertex_shader.shader)
      GL.AttachShader(@program, fragment_shader.shader)

      GL.LinkProgram(@program)
    end

    def init_attributes
      @attributes = {
        position: GL.GetAttribLocation(@program, 'position'),
        uv: GL.GetAttribLocation(@program, 'uv')
      }
    end

    def init_uniforms
      @uniforms = {
        uvOffset: GL.GetUniformLocation(@program, 'uvOffset'),
        uvScale: GL.GetUniformLocation(@program, 'uvScale'),

        rotation: GL.GetUniformLocation(@program, 'rotation'),
        scale: GL.GetUniformLocation(@program, 'scale'),

        color: GL.GetUniformLocation(@program, 'color'),
        map: GL.GetUniformLocation(@program, 'map'),
        opacity: GL.GetUniformLocation(@program, 'opacity'),

        modelViewMatrix: GL.GetUniformLocation(@program, 'modelViewMatrix'),
        projectionMatrix: GL.GetUniformLocation(@program, 'projectionMatrix'),

        fogType: GL.GetUniformLocation(@program, 'fogType'),
        fogDensity: GL.GetUniformLocation(@program, 'fogDensity'),
        fogNear: GL.GetUniformLocation(@program, 'fogNear'),
        fogFar: GL.GetUniformLocation(@program, 'fogFar'),
        fogColor: GL.GetUniformLocation(@program, 'fogColor'),

        alphaTest: GL.GetUniformLocation(@program, 'alphaTest')
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
      GL.UseProgram(@program)

      GL.Disable(GL::CULL_FACE)
      GL.Enable(GL::BLEND)

      GL.BindVertexArray(@vertex_array_object)

      GL.EnableVertexAttribArray(@attributes[:position])
      GL.EnableVertexAttribArray(@attributes[:uv])

      GL.BindBuffer(GL::ARRAY_BUFFER, @vertex_buffer)

      GL.VertexAttribPointer(@attributes[:position], 2, GL::FLOAT, GL::FALSE, 2 * 8, 0)
      GL.VertexAttribPointer(@attributes[:uv], 2, GL::FLOAT, GL::FALSE, 2 * 8, 8)

      GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, @element_buffer)

      GL.UniformMatrix4fv(@uniforms[:projectionMatrix], 1, GL::FALSE, array_to_ptr_easy(camera.projection_matrix.elements))

      GL.ActiveTexture(GL::TEXTURE0)
      GL.Uniform1i(@uniforms[:map], 0)
    end

    def setup_fog(scene)
      @old_fog_type = 0
      @scene_fog_type = 0
      fog = scene.fog

      if fog
        GL.Uniform3f(@uniforms[:fogColor], fog.color.r, fog.color.g, fog.color.b)

        if fog.is_a?(Fog)
          GL.Uniform1f(@uniforms[:fogNear], fog.near)
          GL.Uniform1f(@uniforms[:fogFar], fog.far)

          GL.Uniform1i(@uniforms[:fogType], 1)
          @old_fog_type = 1
          @scene_fog_type = 1
        elsif fog.is_a?(FogExp2)
          GL.Uniform1f(@uniforms[:fogDensity], fog.density)

          GL.Uniform1i(@uniforms[:fogType], 2)
          @old_fog_type = 2
          @scene_fog_type = 2
        end
      else
        GL.Uniform1i(@uniforms[:fogType], 0)
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
        GL.DrawElements(GL::TRIANGLES, 6, GL::UNSIGNED_INT, 0) # GL::UNSIGNED_SHORT
      end
    end

    def set_fog_uniforms(material, scene)
      fog_type = 0

      if scene.fog && material.fog
        fog_type = @scene_fog_type
      end

      if @old_fog_type != fog_type
        GL.Uniform1(@uniforms[:fogType], fog_type)
        @old_fog_type = fog_type
      end
    end

    def set_uv_uniforms(material)
      if !material.map.nil?
        GL.Uniform2f(@uniforms[:uvOffset], material.map.offset.x, material.map.offset.y)
        GL.Uniform2f(@uniforms[:uvScale], material.map.repeat.x, material.map.repeat.y)
      else
        GL.Uniform2f(@uniforms[:uvOffset], 0.0, 0.0)
        GL.Uniform2f(@uniforms[:uvScale], 1.0, 1.0)
      end
    end

    def set_color_uniforms(material)
      GL.Uniform1f(@uniforms[:opacity], material.opacity)
      GL.Uniform3f(@uniforms[:color], material.color.r, material.color.g, material.color.b)
      GL.Uniform1f(@uniforms[:alphaTest], material.alpha_test)
    end

    def set_transform_uniforms(sprite)
      GL.UniformMatrix4fv(@uniforms[:modelViewMatrix], 1, GL::FALSE, array_to_ptr_easy(sprite.model_view_matrix.elements))

      sprite.matrix_world.decompose(@sprite_position, @sprite_rotation, @sprite_scale)

      GL.Uniform1f(@uniforms[:rotation], sprite.material.rotation)
      GL.Uniform2fv(@uniforms[:scale], 1, array_to_ptr_easy([@sprite_scale.x, @sprite_scale.y]))
    end

    def set_blend_mode(material)
      @renderer.state.set_blending(material.blending, material.blend_equation, material.blend_src, material.blend_dst)
      @renderer.state.set_depth_test(material.depth_test)
      @renderer.state.set_depth_write(material.depth_write)
    end
  end
end
