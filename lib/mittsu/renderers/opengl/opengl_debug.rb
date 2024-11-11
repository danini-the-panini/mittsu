require 'opengl'

ERROR_STRINGS = {
  GL::NO_ERROR => 'NO_ERROR',
  GL::INVALID_ENUM => 'INVALID_ENUM',
  GL::INVALID_VALUE => 'INVALID_VALUE',
  GL::INVALID_OPERATION => 'INVALID_OPERATION',
  GL::STACK_OVERFLOW => 'STACK_OVERFLOW',
  GL::STACK_UNDERFLOW => 'STACK_UNDERFLOW',
  GL::OUT_OF_MEMORY => 'OUT_OF_MEMORY',
  # GL::TABLE_TOO_LARGE => 'TABLE_TOO_LARGE'
}

module OpenGLDebug
  class DebugShader
    def initialize(handle)
      @handle = handle
      @uniforms = {}
    end

    def set_uniform(handle, name)
      @uniforms[handle] = name
    end

    def get_uniform_name(handle)
      @uniforms[handle]
    end
  end

  def self.load_lib(*args)
    GL.load_lib(*args)
  end

  GL.constants.each do |c|
    const_set c, GL.const_get(c)
  end

  def call_debug_method m, called_from = caller[0], *args
    if m.to_s.start_with?('GL.Uniform')
      uniform_name = @@current_shader.get_uniform_name(args.first)
      call = "#{m}('#{uniform_name}',#{args[1..-1].map { |s| s.to_s[0..20] }.join(', ')})"
    else
      call = "#{m}(#{args.map { |s| s.to_s[0..20] }.join(', ')})"
    end
    print call
    r = GL.send(m, *args)
    ret = r.nil? ? '' : " => #{r}"
    puts "#{ret} (#{called_from})"
    e = GL.GetError
    raise "ERROR: #{m} => #{ERROR_STRINGS[e]}" unless e == GL::NO_ERROR
    r
  end

  GL.instance_methods.each do |m|
    define_method m do |*args|
      self.call_debug_method(m, caller[0], *args)
    end
  end

  def CreateProgram
    call_debug_method(:GL.CreateProgram, caller[0]).tap do |handle|
      @@shaders ||= {}
      @@shaders[handle] = DebugShader.new(handle)
    end
  end

  def UseProgram(handle)
    @@current_shader = @@shaders[handle]
    call_debug_method(:UseProgram, caller[0], handle)
  end

  def GetUniformLocation(program, name)
    call_debug_method(:GetUniformLocation, caller[0], program, name).tap do |handle|
      @@shaders[program].set_uniform(handle, name)
    end
  end
end
