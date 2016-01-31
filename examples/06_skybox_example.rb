require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
skybox_scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)
skybox_camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 1.0, 100.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '06 Skybox Example'
renderer.auto_clear = false

geometry = Mittsu::SphereGeometry.new(2.0, 32, 16)
texture = Mittsu::ImageUtils.load_texture_cube(
  [ 'rt', 'lf', 'up', 'dn', 'bk', 'ft' ].map { |path|
    File.join File.dirname(__FILE__), 'cubemap', "tron_#{path}.png"
  }
)
material = Mittsu::MeshBasicMaterial.new(env_map: texture)
earth = Mittsu::Mesh.new(geometry, material)
scene.add(earth)

shader = Mittsu::ShaderLib[:cube]
shader.uniforms['tCube'].value = texture

skybox_material = Mittsu::ShaderMaterial.new({
  fragment_shader: shader.fragment_shader,
  vertex_shader: shader.vertex_shader,
  uniforms: shader.uniforms,
  depth_write: false,
  side: Mittsu::BackSide
})

skybox = Mittsu::Mesh.new(Mittsu::BoxGeometry.new(100, 100, 100), skybox_material)
skybox_scene.add(skybox)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

x = 0
renderer.window.run do
  camera.position.x = 5.0 * Math.sin(x * 0.01)
  camera.position.z = 5.0 * Math.cos(x * 0.01)
  camera.look_at(Mittsu::Vector3.new(0.0, 0.0, 0.0))
  skybox_camera.rotation.copy(camera.rotation)

  renderer.clear
	renderer.render(skybox_scene, skybox_camera);
  renderer.clear_depth
  renderer.render(scene, camera)
  x += 1
end
