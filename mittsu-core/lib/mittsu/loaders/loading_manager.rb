module Mittsu
  class LoadingManager
    def initialize
      @loaded, @total = 0, 0
    end

    def item_start(url)
      @total += 1
    end

    def item_end(url)
      @loaded += 1
    end
  end

  DefaultLoadingManager = LoadingManager.new
end
