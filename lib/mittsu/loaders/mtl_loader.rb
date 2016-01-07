module Mittsu
  class MTLLoader
    include EventDispatcher

    def initialize(base_url, options = {}) # TODO: cross_origin?
      @base_url = base_url
      @options = options
      # @cross_origin = cross_origin
    end

    def load(url)
      loader = FileLoader.new
      # loader.cross_origin = @cross_origin

      text = loader.load File.join(@base_url, url)
      parse(text)
    end

    def parse(text)
      lines = text.split("\n")
      info = {}
      delimiter_pattern = /\s+/
      materials_info = {}

      lines.each do |line|
  			line = line.strip

  			next if line.empty? || line.start_with?('#')

  			pos = line.index(' ')

  			key = ( pos >= 0 ) ? line[0...pos] : line
  			key = key.downcase

  			value = ( pos >= 0 ) ? line[pos + 1..-1] : ""
  			value = value.strip

  			if key == "newmtl"
  				# New material

  				info = { name: value };
  				materials_info[value] = info
  			elsif info
  				if key == "ka" || key == "kd" || key == "ks"
  					ss = value.split(delimiter_pattern).take(3)
  					info[key] = [ss[0].to_f, ss[1].to_f, ss[2].to_f]
  				else
  					info[key] = value
  				end
  			end
      end

      MaterialCreator.new(@base_url, @options).tap do |material_creator|
        material_creator.set_materials(materials_info)
      end
    end

    class MaterialCreator
      def initialize(base_url, options = nil)
        @base_url = base_url
        @options = options
        @material_info = {}
        @materials = {}
        @materials_array = []
        @name_lookup = {}

        @side = (@options || {}).fetch(:side, FrontSide)
        @wrap = (@options || {}).fetch(:wrap, RepeatWrapping)
      end

      def set_materials(materials_info)
        @materials_info = convert materials_info
        @materials = {}
        @materials_array = []
        @name_lookup = {}
      end

      def convert(materials_info)
        return materials_info if !@options

        converted = {}

        materials_info.each do |mn, mat|
          covmat = {}
          converted[mn] = covmat

          mat.each do |prop, value|
            save = true
            lprop = prop.to_s.downcase

            case lprop
            when 'kd', 'ka', 'ks'
              # Diffuse color, (color under white light) using RGB values

              if @options && @options[:normalize_rgb]
                value = [value[0] / 255.0, value[1] / 255.0, value[2] / 255.0]
              end

              if @options && @options[:ignore_zero_rgbs]
                if value.take(3).any?(&:zero?)
                  # ignore
                  save = false
                end
              end
            when 'd'
  						# According to MTL format (http://paulbourke.net/dataformats/mtl/):
  						#   d is dissolve for current material
  						#   factor of 1.0 is fully opaque, a factor of 0 is fully dissolved (completely transparent)

              if @options && @options[:invert_transparency]
                value = 1.0 - value
              end
            end

            covmat[lprop] = value if save
          end
        end

        converted
      end

      def preload
        @materials_info.each_key do |mn|
          create mn
        end
      end

      def get_index(material_name)
        @name_lookup[material_name]
      end

      def get_as_array
        @materials_info.keys.each_with_index do |mn, index|
          @materials_array[index] = create mn
          @name_lookup[mn] = index
        end

        @materials_array
      end

      def create(material_name)
        if @materials[material_name].nil?
          create_material(material_name)
        end

        @materials[material_name]
      end

      def load_texture(url, mapping = nil)
        loader = Loader::Handlers.get(url)

        if !loader.nil?
          texture = loader.load url
        else
          texture = Texture.new

          loader = ImageLoader.new
          # loader.cross_origin = @cross_origin # TODO: ???
          image = loader.load url

          texture.image = ensure_power_of_two(image)
          texture.needs_update = true
        end

        texture.mapping = mapping unless mapping.nil?

        texture
      end

      private

      def create_material(material_name)
        mat = @materials_info[material_name]
        params = {
          name: material_name,
          side: @side
        }

        mat.each do |prop, value|
          case prop.downcase
          when 'kd'
            # Diffuse color (color under white light) using RGB values
            params[:diffuse] = Color.new.from_array(value)
          when 'ka'
            # Ambient color (color under shadow) using RGB value
          when 'ks'
            # Specular color (color when light is reflected from shiny surface) using RGB values
            params[:specular] = Color.new.from_array(value)
          when 'map_kd'
            # Diffuse texture map
            params[:map] = load_texture File.join(@base_url, value)
            params[:map].wrap_s = @wrap
            params[:map].wrap_t = @wrap
          when 'ns'
            # The specular exponent (defines the focus of the specular highlight)
            # A high exponent results in a tight, concentrated highlight. Ns values normally range from 0 to 1000.
            params[:shininess] = value.to_f
          when 'd'
  					# According to MTL format (http://paulbourke.net/dataformats/mtl/):
  					#   d is dissolve for current material
  					#   factor of 1.0 is fully opaque, a factor of 0 is fully dissolved (completely transparent)

            if value.to_f < 1
              params[:transparent] = true
              params[:opacity] = value.to_f
            end
          when 'map_bump', 'bump'
            # Bump texture map
            if !params[:bump_map]
              params[:bump_map] = load_texture File.join(@base_url, value)
              params[:bump_map].wrap_s = @wrap
              params[:bump_map].wrap_t = @wrap
            end
          end
        end

        if params[:diffuse]
          params[:color] = params[:diffuse]
        end

        @materials[material_name] = MeshPhongMaterial.new(params)
      end

      def ensure_power_of_two(image)
        if !Math.power_of_two?(image.width) || !Math.power_of_two?(image.height)
          # TODO: resize image ???
        end
        image
      end

      def next_highest_power_of_two(x)
        x -= 1
        i = 1
        while i < 32
          x = x | x >> i
          i <<= 1
        end
        x + 1
      end
    end
  end
end
