module Mittsu
  module EventDispatcher
    Event = Struct.new(:type, :target)

    def add_event_listener(type, listener)
      @_listeners ||= {}
      @_listeners[type] ||= []
      if !@_listeners[type].include? listener
        @_listeners[type] << (listener)
      end
    end

    def has_event_listener(type, listener)
      return false if @_listeners.nil?
      return false if @_listeners[type].nil?
      @_listeners[type].include? listener
    end

    def remove_event_listener(type, listener)
      return if @_listeners.nil?
      listener_array = @_listeners[type]
      if listener_array
        listener_array.delete(listener)
      end
    end

    def dispatch_event(event = {})
      return if @_listeners.nil?
      listener_array = @_listeners[event[:type]]
      if listener_array
        evt = Event.new(event[:type], self)
        array = listener_array.dup
        array.each do |l|
          l.call(evt)
        end
      end
    end
  end
end
