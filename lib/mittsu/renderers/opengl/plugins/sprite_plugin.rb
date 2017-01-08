module Mittsu
  class SpritePlugin
    include OpenGLHelper

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

      # setup gl

      init if @program.nil?

      glUseProgram(@program)

      glDisable(GL_CULL_FACE)
      glEnable(GL_BLEND)

      glBindVertexArray(@vertex_array_object)

      glEnableVertexAttribArray(@attributes[:position])
      glEnableVertexAttribArray(@attributes[:uv])

      glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)

      glVertexAttribPointer(@attributes[:position], 2, GL_FLOAT, GL_FALSE, 2 * 8, 0)
      glVertexAttribPointer(@attributes[:uv], 2, GL_FLOAT, GL_FALSE, 2 * 8, 8)

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @element_buffer)

      glUniformMatrix4fv(@uniforms[:projectionMatrix], 1, GL_FALSE, array_to_ptr_easy(camera.projection_matrix.elements))

      glActiveTexture(GL_TEXTURE0)
      glUniform1i(@uniforms[:map], 0)

      old_fog_type = 0
      scene_fog_type = 0
      fog = scene.fog

      if fog
        glUniform3f(@uniforms[:fogColor], fog.color.r, fog.color.g, fog.color.b)

        if fog.is_a?(Fog)
          glUniform1f(@uniforms[:fogNear], fog.near)
          glUniform1f(@uniforms[:fogFar], fog.far)

          glUniform1i(@uniforms[:fogType], 1)
          old_fog_type = 1
          scene_fog_type = 1
        elsif fog.is_a?(FogExp2)
          glUniform1f(@uniforms[:fogDensity], fog.density)

          glUniform1i(@uniforms[:fogType], 2)
          old_fog_type = 2
          scene_fog_type = 2
        end
      else
        glUniform1i(@uniforms[:fogType], 0)
        old_fog_type = 0
        scene_fog_type = 0
      end

      # update positions and sort

      @sprites.each do |sprite|
        sprite.model_view_matrix.multiply_matrices(camera.matrix_world_inverse, sprite.matrix_world)
        sprite.z = -sprite.model_view_matrix.elements[14]
      end

      @sprites.sort!(&self.method(:painter_sort_stable))

      # render all sprites

      scale = []

      @sprites.each do |sprite|
        material = sprite.material

        glUniform1f(@uniforms[:alphaTest], material.alpha_test)
        glUniformMatrix4fv(@uniforms[:modelViewMatrix], 1, GL_FALSE, array_to_ptr_easy(sprite.model_view_matrix.elements))

        sprite.matrix_world.decompose(@sprite_position, @sprite_rotation, @sprite_scale)

        scale[0] = @sprite_scale.x
        scale[1] = @sprite_scale.y

        fog_type = 0

        if scene.fog && material.fog
          fog_type = scene_fog_type
        end

        if old_fog_type != fog_type
          glUniform1(@uniforms[:fogType], fogType)
          old_fog_type = fog_type
        end

        if !material.map.nil?
          glUniform2f(@uniforms[:uvOffset], material.map.offset.x, material.map.offset.y)
          glUniform2f(@uniforms[:uvScale], material.map.repeat.x, material.map.repeat.y)
        else
          glUniform2f(@uniforms[:uvOffset], 0.0, 0.0)
          glUniform2f(@uniforms[:uvScale], 1.0, 1.0)
        end

        glUniform1f(@uniforms[:opacity], material.opacity)
        glUniform3f(@uniforms[:color], material.color.r, material.color.g, material.color.b)

        glUniform1f(@uniforms[:rotation], material.rotation)
        glUniform2fv(@uniforms[:scale], 1, array_to_ptr_easy(scale))

        @renderer.state.set_blending(material.blending, material.blend_equation, material.blend_src, material.blend_dst)
        @renderer.state.set_depth_test(material.depth_test)
        @renderer.state.set_depth_write(material.depth_write)

        if material.map && material.map.image && material.map.image.width
          material.map.set(0, @renderer)
        else
          # TODO: canvas texture?
          # texture.set(0, @renderer)
        end

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0) # GL_UNSIGNED_SHORT
      end

      glEnable(GL_CULL_FACE)
      @renderer.reset_gl_state
    end

    private

    def init
      vertices = [
        -0.5, -0.5, 0.0, 0.0,
         0.5, -0.5, 1.0, 0.0,
         0.5,  0.5, 1.0, 1.0,
        -0.5,  0.5, 0.0, 1.0
      ] # Float32Array

      faces = [
        0, 1, 2,
        0, 2, 3
      ] # Uint16Array

      @vertex_array_object = glCreateVertexArray
      glBindVertexArray(@vertex_array_object)

      @vertex_buffer = glCreateBuffer
      @element_buffer = glCreateBuffer

      glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)
      glBufferData_easy(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW)

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @element_buffer)
      glBufferData_easy(GL_ELEMENT_ARRAY_BUFFER, faces, GL_STATIC_DRAW)

      @program = create_program

      @attributes = {
        position: glGetAttribLocation(@program, 'position'),
        uv: glGetAttribLocation(@program, 'uv')
      }

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

      # TODO: canvas texture??
    end

    def create_program
      program = glCreateProgram

      vertex_shader = OpenGLShader.new(GL_VERTEX_SHADER, [
  			# "precision #{renderer.getPrecision()} float;",
        '#version 330',

  			'uniform mat4 modelViewMatrix;',
  			'uniform mat4 projectionMatrix;',
  			'uniform float rotation;',
  			'uniform vec2 scale;',
  			'uniform vec2 uvOffset;',
  			'uniform vec2 uvScale;',

  			'in vec2 position;',
  			'in vec2 uv;',

  			'out vec2 vUV;',

  			'void main() {',

  				'vUV = uvOffset + uv * uvScale;',

  				'vec2 alignedPosition = position * scale;',

  				'vec2 rotatedPosition;',
  				'rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;',
  				'rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;',

  				'vec4 finalPosition;',

  				'finalPosition = modelViewMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );',
  				'finalPosition.xy += rotatedPosition;',
  				'finalPosition = projectionMatrix * finalPosition;',

  				'gl_Position = finalPosition;',

  			'}'
      ].join("\n"))
      fragment_shader = OpenGLShader.new(GL_FRAGMENT_SHADER, [
  			# "precision #{renderer.getPrecision()} float;",
        '#version 330',

  			'uniform vec3 color;',
  			'uniform sampler2D map;',
  			'uniform float opacity;',

  			'uniform int fogType;',
  			'uniform vec3 fogColor;',
  			'uniform float fogDensity;',
  			'uniform float fogNear;',
  			'uniform float fogFar;',
  			'uniform float alphaTest;',

  			'in vec2 vUV;',
        'layout(location = 0) out vec4 fragColor;',

  			'void main() {',

  				'vec4 texture = texture( map, vUV );',

  				'if ( texture.a < alphaTest ) discard;',

  				'fragColor = vec4( color * texture.xyz, texture.a * opacity );',

  				'if ( fogType > 0 ) {',

  					'float depth = gl_FragCoord.z / gl_FragCoord.w;',
  					'float fogFactor = 0.0;',

  					'if ( fogType == 1 ) {',

  						'fogFactor = smoothstep( fogNear, fogFar, depth );',

  					'} else {',

  						'const float LOG2 = 1.442695;',
  						'float fogFactor = exp2( - fogDensity * fogDensity * depth * depth * LOG2 );',
  						'fogFactor = 1.0 - clamp( fogFactor, 0.0, 1.0 );',

  					'}',

  					'fragColor = mix( fragColor, vec4( fogColor, fragColor.w ), fogFactor );',

  				'}',

  			'}'
      ].join("\n"))

      glAttachShader(program, vertex_shader.shader)
      glAttachShader(program, fragment_shader.shader)

      glLinkProgram(program)

      program
    end

    def painter_sort_stable(a, b)
      if a.z != b.z
        b.z - a.z
      else
        b.id - a.id
      end
    end
  end
end
