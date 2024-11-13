module Mittsu
  class FileLoader
    def initialize(manager = nil)
      @manager = manager || DefaultLoadingManager
    end

    def load(url)
      cached = Cache.get(url)

      return cached unless cached.nil?

      @manager.item_start(url)

      text = File.read(url)
      Cache.add(url, text)

      @manager.item_end(url)

      text
    end
  end
end
