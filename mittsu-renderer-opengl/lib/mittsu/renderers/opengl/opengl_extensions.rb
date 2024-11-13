module GL
  def self.CreateBuffer
    @_b ||= ' '*8
    ::GL.GenBuffers(1, @_b)
    @_b.unpack('L')[0]
  end

  def self.CreateTexture
    @_b ||= ' '*8
    ::GL.GenTextures(1, @_b)
    @_b.unpack('L')[0]
  end

  def self.CreateVertexArray
    @_b ||= ' '*8
    ::GL.GenVertexArrays(1, @_b)
    @_b.unpack('L')[0]
  end

  def self.CreateFramebuffer
    @_b ||= ' '*8
    ::GL.GenFramebuffers(1, @_b)
    @_b.unpack('L')[0]
  end

  def self.CreateRenderbuffer
    @_b ||= ' '*8
    ::GL.GenRenderbuffers(1, @_b)
    @_b.unpack('L')[0]
  end

  def self.BufferData_easy(target, data, usage)
    ptr = array_to_ptr_easy(data)
    ::GL.BufferData(target, ptr.size, ptr, usage)
  end

  def self.GetParameter(pname)
    @_b ||= ' '*8
    ::GL.GetIntegerv(pname, @_b)
    @_b.unpack('L')[0]
  end
end
