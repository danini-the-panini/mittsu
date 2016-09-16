require 'minitest_helper'

class TestOpenGLLib < Minitest::Test
  def test_linux_64_nvidia_1
    fake_loader = Struct.new(:libgl_paths, :kernel_module_in_use, :sixtyfour_bits?).new(
      [
        '/usr/lib/x86_64-linux-gnu/mesa/libGL.so',
        '/usr/lib/x86_64-linux-gnu/libGL.so',
      ],
      'nvidia',
      true
    )

    linux_lib = OpenGLLib::Linux.new(fake_loader)
    assert_equal 'libGL.so', linux_lib.file
    assert_equal '/usr/lib/x86_64-linux-gnu', linux_lib.path
  end

  # TODO: get real test data from my nvidia PC when I get home
  def test_linux_64_nvidia_2
    fake_loader = Struct.new(:libgl_paths, :kernel_module_in_use, :sixtyfour_bits?).new(
      [
        '/usr/lib/x86_64-linux-gnu/mesa/libGL.so',
        '/usr/lib/x86_64-linux-gnu/libGL.so',
        '/usr/lib/some-dir-with-nvidia-in-it/libGL.so'
      ],
      'nvidia',
      true
    )

    linux_lib = OpenGLLib::Linux.new(fake_loader)
    assert_equal 'libGL.so', linux_lib.file
    assert_equal '/usr/lib/some-dir-with-nvidia-in-it', linux_lib.path
  end

  def test_linux_64_vboxvideo
    fake_loader = Struct.new(:libgl_paths, :kernel_module_in_use, :sixtyfour_bits?).new(
      [
        '/usr/lib/x86_64-linux-gnu/mesa/libGL.so',
        '/usr/lib/x86_64-linux-gnu/libGL.so'
      ],
      'vboxvideo',
      true
    )

    linux_lib = OpenGLLib::Linux.new(fake_loader)
    assert_equal 'libGL.so', linux_lib.file
    assert_equal '/usr/lib/x86_64-linux-gnu', linux_lib.path
  end

  # TODO: get real-world data for 32-bit machines, as well as neuvaux, fglrx, radeon, and intel configs
end
