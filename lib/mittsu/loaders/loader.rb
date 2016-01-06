module Mittsu
  class Loader
    def initialize(show_status = false)
      @image_loader = ImageLoader.new
    end

    def init_materials(materials, texture_path)
      materials.map do |m|
        create_material(m, texture_path)
      end
    end

    def needs_tangents(materials)
      materials.each do |m|
        return true if m.is_a?(ShareMaterial)
      end
      false
    end

    def create_material(m, texture_path)
      # defaults

      mtype = 'MeshLambertMaterial'
      mpars = {
        color: 0xeeeeee,
        opactity: 1.0,
        map: nil,
        light_map: nil,
        normal_map: nil,
        bump_map: nil,
        wireframe: false
      }

      # parameters from model file

      if m.shading
        shading = m.shading.downcase

        if shading == 'phong'
          mtype = 'MeshPhongMaterial'
        elsif shading == 'basic'
          mtype = 'MeshBasicMaterial'
        end
      end

      if m.blending && Mittsu.const_get(m.blending)
        mpars[:blending] = Mittsu.const_get(m.blending)
      end

      mpars[:transparent] = m.transparent if !m.transparent.nil?
      mpars[:transparent] = true if m.opacity && m.opacity < 1.0
      mpars[:depth_test] = m.depth_test if !m.depth_test.nil?
      mpars[:depth_write] = m.depth_write if !m.depth_write.nil?
      mpars[:visible] = m.visible if !m.visible.nil?
      mpars[:flip_sided] = BackSide if !m.flip_sided.nil?
      mpars[:double_sided] = DoubleSide if !m.double_sided.nil?
      mpars[:wireframe] = m.wireframe if !m.wireframe.nil?

      if !m.vertex_colors.nil?
        if m.vertex_colors == 'face'
          mpars[:vertex_colors] = FaceColors
        elsif !m.vertex_colors.empty?
          mpars[:vertex_colors] = VertexColors
        end
      end

      # colors

      if m.color_diffuse
        mpars[:color] = rgb2hex(m.color_diffuse)
      elsif m.dgb_color
        mpars[:color] = m.dgb_color
      end

      if m.color_specular
        mpars[:specular] = rgb2hex(m.color_specular)
      end

      if m.color_emissive
        mpars[:emissive] = rgb2hex(m.color_emissive)
      end

      # modifiers

      if !m.transparency.nil?
        puts "WARNING: Mitsu::Loader: transparency has been renamed to opacity"
        m.opacity = m.transparency
      end

      if !m.opacity.nil?
        mpars[:opacity] = m.opacity
      end

      # TODO ...
    end

    private

    def nearest_pow2(n)
      l = Math.log(n) / Math::LN2
      Math.pow(2, Math.round(l))
    end

    def create_texture(where, name, source_file, repeat, offset, wrap, anisotropy)
      full_path = File.join(texture_path, source_file)

      loader = Handlers.get(full_path)

      if !loader.nil?
        texture = loader.load full_path
      else
        texture = Texture.new

        loader = @image_loader
        image = loader.load full_path

        if !Math.power_of_two?(image.width) || !Math.power_of_two?(image.height)
          # TODO: resize image to power of two
        else
          texture.image = image
        end

        texture.needs_update = true
      end

      texture.source_file = source_file

      if repeat
        texture.repeat.set(repeat[0], repeat[1])

        texture.wrap_s = RepeatWrapping if repeat[0] != 1
        texture.wrap_t = RepeatWrapping if repeat[1] != 1
      end

      if offset
        texture.offset.set(offset[0], offset[1])
      end

      if wrap
        wrap_map = {
          repeat: RepeatWrapping,
          mirror: MirroredRepeatWrapping
        }

        texture.wrap_s = wrap_map[wrap[0]] unless wrap_map[wrap[0]].nil?
        texture.wrap_t = wrap_map[wrap[1]] unless wrap_map[wrap[1]].nil?
      end

      texture.anisotropy = anisotropy if anisotropy

      where[name] = texture
    end

    def rgb2hex(rgb)
      (rgb[0] * 255 << 16) + (rgb[1] * 255 << 8) + rgb[2] * 255
    end
  end
end
