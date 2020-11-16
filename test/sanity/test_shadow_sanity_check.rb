require 'minitest_helper'

class TestShadowSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestShadowSanityCheck'
    renderer.shadow_map_enabled = true
    renderer.shadow_map_type = Mittsu::PCFSoftShadowMap

    floor = Mittsu::Mesh.new(
      Mittsu::BoxGeometry.new(100.0, 1.0, 100.0),
      Mittsu::MeshPhongMaterial.new(color: 0x00ff00)
    )
    floor.position.y = -1.0
    floor.receive_shadow = true
    scene.add(floor)

    nb = 5
    nr = 1
    balls = nb.times.map do |index|
      nr.times.map do |r|
        ring = (3 + r)
        i = r * 0.1 + (index.to_f / nb.to_f) * ::Math::PI * 2
        Mittsu::Mesh.new(
          Mittsu::SphereGeometry.new(0.5, 16, 16),
          Mittsu::MeshLambertMaterial.new(color: r.even? ? 0x00ffff : 0xff00ff)
        ).tap do |b|
          b.cast_shadow = true
          b.receive_shadow = true
          b.position.z = ::Math.cos(i) * ring
          b.position.x = ::Math.sin(i) * ring
          scene.add(b)
        end
      end
    end.flatten

    ball = Mittsu::Mesh.new(
      Mittsu::SphereGeometry.new(1.0, 32, 32),
      Mittsu::MeshLambertMaterial.new(color: 0xffffff)
    )
    ball.cast_shadow = true
    ball.receive_shadow = true
    scene.add(ball)

    light = Mittsu::SpotLight.new(0xffffff, 1.0)
    light.position.set(20.0, 30.0, 0.0)

    light.cast_shadow = true
    light.shadow_darkness = 0.5

    light.shadow_map_width = 1024
    light.shadow_map_height = 1024

    light.shadow_camera_near = 1.0
    light.shadow_camera_far = 100.0
    light.shadow_camera_fov = 60.0

    light.shadow_camera_visible = true
    scene.add(light)

    camera.position.z = 10.0
    camera.position.y = 10.0
    camera.look_at(floor.position)

    renderer.window.on_resize do |width, height|
      renderer.set_viewport(0, 0, width, height)
      camera.aspect = width.to_f / height.to_f
      camera.update_projection_matrix
    end

    x = 0
    renderer.window.run do
      x += 1
      light.position.x = ::Math.sin(x * 0.01) * 20.0
      light.position.z = ::Math.cos(x * 0.01) * 20.0

      balls.each_with_index do |b, i|
        b.position.y = (1.0 + ::Math.sin(x * 0.05 + i)) * 2.0
      end

      renderer.render(scene, camera)
    end
  end
end
