require 'minitest_helper'

class TestOpenGLLib < Minitest::Test
  def test_linux_64_nvidia_1
    fake_loader = Struct.new(:lib_paths, :kernel_module_in_use, :sixtyfour_bits?, :ldconfig).new(
      [
        '/usr/lib/x86_64-linux-gnu/mesa/libGL.so',
        '/usr/lib/x86_64-linux-gnu/libGL.so',
      ],
      'nvidia',
      true,
      []
    )

    linux_lib = Mittsu::OpenGLLib::Linux.new(fake_loader)
    assert_equal '/usr/lib/x86_64-linux-gnu/libGL.so', linux_lib.path
  end

  # TODO: get real test data from my nvidia PC when I get home
  def test_linux_64_nvidia_2
    fake_loader = Struct.new(:lib_paths, :kernel_module_in_use, :sixtyfour_bits?, :ldconfig).new(
      [
        '/usr/lib/x86_64-linux-gnu/libGL.so',
        '/usr/lib/x86_64-linux-gnu/mesa/libGL.so',
        '/usr/lib/nvidia-367/libGL.so',
        '/usr/lib32/nvidia-367/libGL.so'
      ],
      'nvidia',
      true,
      []
    )

    linux_lib = Mittsu::OpenGLLib::Linux.new(fake_loader)
    assert_equal '/usr/lib/nvidia-367/libGL.so', linux_lib.path
  end

  def test_linux_64_vboxvideo
    fake_loader = Struct.new(:lib_paths, :kernel_module_in_use, :sixtyfour_bits?, :ldconfig).new(
      [
        '/usr/lib/x86_64-linux-gnu/mesa/libGL.so',
        '/usr/lib/x86_64-linux-gnu/libGL.so'
      ],
      'vboxvideo',
      true,
      []
    )

    linux_lib = Mittsu::OpenGLLib::Linux.new(fake_loader)
    assert_equal '/usr/lib/x86_64-linux-gnu/libGL.so', linux_lib.path
  end

  def test_linux_64_ldconfig
    fake_loader = Struct.new(:lib_paths, :kernel_module_in_use, :sixtyfour_bits?, :ldconfig).new(
      [],
      '',
      true,
      [
        "\tlibGL.so.1 (libc6,x86-64) => /usr/lib/nvidia-367/libGL.so.1\n",
        "\tlibGL.so.1 (libc6) => /usr/lib32/nvidia-367/libGL.so.1\n",
        "\tlibGL.so (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libGL.so\n",
        "\tlibGL.so (libc6,x86-64) => /usr/lib/nvidia-367/libGL.so\n",
        "\tlibGL.so (libc6) => /usr/lib32/nvidia-367/libGL.so\n"
      ]
    )

    linux_lib = Mittsu::OpenGLLib::Linux.new(fake_loader)
    assert_equal '/usr/lib/nvidia-367/libGL.so.1', linux_lib.path
  end

  def test_linux_32_ldconfig
    fake_loader = Struct.new(:lib_paths, :kernel_module_in_use, :sixtyfour_bits?, :ldconfig).new(
      [],
      '',
      false,
      [
        "\tlibGL.so.1 (libc6,x86-64) => /usr/lib/nvidia-367/libGL.so.1\n",
        "\tlibGL.so.1 (libc6) => /usr/lib32/nvidia-367/libGL.so.1\n",
        "\tlibGL.so (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libGL.so\n",
        "\tlibGL.so (libc6,x86-64) => /usr/lib/nvidia-367/libGL.so\n",
        "\tlibGL.so (libc6) => /usr/lib32/nvidia-367/libGL.so\n"
      ]
    )

    linux_lib = Mittsu::OpenGLLib::Linux.new(fake_loader)
    assert_equal '/usr/lib32/nvidia-367/libGL.so.1', linux_lib.path
  end

  # TODO: get real-world data for 32-bit machines, as well as neuvaux, fglrx, radeon, and intel configs
end
