module Mittsu
  class LineBasicMaterial < Material
    def initialize(parameters = {})
      super()

      @type = 'LineBasicMaterial'

      @color = Color.new(0xffffff)

      @line_width = 1.0
      @line_cap = :round
      @line_join = :round


      @vertex_colors = NoColors

      @fog = true

      self.set_values(parameters)
    end

    def clone
      LineBasicMaterial.new.tap do |material|
        super(material)

        material.color.copy(@color)

        material.line_width = @line_width
        material.line_cap = @line_cap
        material.line_join = @line_join

        material.vertex_colors = @vertex_colors

        material.fog = @fog
      end
    end
  end
end
