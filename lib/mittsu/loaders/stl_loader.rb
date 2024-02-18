module Mittsu
  class STLLoader
    include EventDispatcher

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
      @_listeners = {}
    end

    def load(url)
      loader = FileLoader.new(@manager)

      text = loader.load(url)
      parse(text)
    end

    def parse(data)
      # TODO
      @group
    end

  end
end
