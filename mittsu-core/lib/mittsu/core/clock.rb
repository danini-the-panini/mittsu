module Mittsu
  class Clock
    attr_accessor :auto_start, :start_time, :old_time, :elapsed_time, :running

    def initialize(auto_start = true)
      @auto_start = auto_start
      @start_time = 0
      @old_time = 0
      @elapsed_time = 0
      @running = false
    end

    def start
      @start_time = Time.now
      @old_time = @start_time
      @running = true
    end

    def stop
      self.get_elapsed_time
      @running = false
    end

    def get_elapsed_time
      self.get_delta
      @elapsed_time
    end

    def get_delta
      diff = 0
      if @auto_start && ! @running
        self.start
      end
      if @running
        new_time = Time.now
        diff = 0.001 * (new_time - @old_time)
        @old_time = new_time
        @elapsed_time += diff
      end
      diff
    end

  end
end
