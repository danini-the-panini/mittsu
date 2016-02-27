module Mittsu
  module OpenGLHelper
    def glCreateBuffer
      @_b ||= ' '*8
      glGenBuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateTexture
      @_b ||= ' '*8
      glGenTextures(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateVertexArray
      @_b ||= ' '*8
      glGenVertexArrays(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateFramebuffer
      @_b ||= ' '*8
      glGenFramebuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateRenderbuffer
      @_b ||= ' '*8
      glGenRenderbuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def array_to_ptr_easy(data)
      if data.first.is_a?(Float)
        size_of_element = Fiddle::SIZEOF_FLOAT
        format_of_element = 'F'
        # data.map!{ |d| d.nil? ? 0.0 : d }
      else
        size_of_element = Fiddle::SIZEOF_INT
        format_of_element = 'L'
        # data.map!{ |d| d.nil? ? 0 : d }
      end
      size = data.length * size_of_element
      array_to_ptr(data, size, format_of_element)
    end

    def array_to_ptr(data, size, format)
      ptr = Fiddle::Pointer.malloc(size)
      ptr[0,size] = data.pack(format * data.length)
      ptr
    end

    def glBufferData_easy(target, data, usage)
      ptr = array_to_ptr_easy(data)
      glBufferData(target, ptr.size, ptr, usage)
    end

    def glGetParameter(pname)
      @_b ||= ' '*8
      glGetIntegerv(pname, @_b)
      @_b.unpack('L')[0]
    end
  end
end
