require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

camera = Mittsu::PerspectiveCamera.new(60.0, ASPECT, 1.0, 2100.0)
camera.position.z = 1500.0

camera_ortho = Mittsu::OrthographicCamera.new(-SCREEN_WIDTH / 2.0, SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0, -SCREEN_HEIGHT / 2.0, 1.0, 10.0)
camera_ortho.position.z = 10.0

scene = Mittsu::Scene.new
scene_ortho = Mittsu::Scene.new

amount = 200
radius = 500

map_a = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), 'sprite0.png')

material_a = Mittsu::SpriteMaterial.new(map: map_a)

hud_image_width = material_a.map.image.width
hud_image_height = material_a.map.image.height

sprite_top_left, sprite_top_right, sprite_bottom_left, sprite_bottom_right, sprite_center = 5.times.map do
  Mittsu::Sprite.new(material_a).tap do |sprite|
    sprite.scale.set(hud_image_width, hud_image_height, 1.0)
    scene_ortho.add(sprite)
  end
end

update_hud_sprites = -> (window_width, window_height) {
  half_window_width = window_width / 2.0
  half_window_height = window_height / 2.0

  half_image_width = hud_image_width / 2.0
  half_image_height = hud_image_height / 2.0

  sprite_top_left.position.set(half_image_width, window_height - half_image_height, 1.0)
  sprite_top_right.position.set(window_width - half_image_width, window_height - half_image_height, 1.0)
  sprite_bottom_left.position.set(half_image_width, half_image_height, 1.0)
  sprite_bottom_right.position.set(window_width - half_image_width, half_image_height, 1.0)
  sprite_center.position.set(half_window_width, half_window_height, 1.0)
}

update_hud_sprites.(SCREEN_WIDTH, SCREEN_HEIGHT)

map_b = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), 'sprite1.png')
map_c = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), 'sprite2.png')

group = Mittsu::Group.new

material_c = Mittsu::SpriteMaterial.new(map: map_c, color: 0xffffff)
material_b = Mittsu::SpriteMaterial.new(map: map_b, color: 0xffffff)

amount.times do
  x = rand - 0.5
  y = rand - 0.5
  z = rand - 0.5

  if z < 0
    material = material_b.clone
  else
    material = material_c.clone
    material.color.set_hsl(0.5 * rand, 0.75, 0.5)
    material.map.offset.set(-0.5, -0.5)
    material.map.repeat.set(2.0, 2.0)
  end

  sprite = Mittsu::Sprite.new(material)

  sprite.position.set(x, y, z)
  sprite.position.normalize
  sprite.position.multiply_scalar(radius)

  group.add(sprite)
end

scene.add(group)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '14 Sprite Example'
renderer.auto_clear = false

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix

  camera_ortho.left = -width / 2.0
  camera_ortho.right = width / 2.0
  camera_ortho.top = height / 2.0
  camera_ortho.bottom = -height / 2.0
  camera_ortho.update_projection_matrix

  update_hud_sprites.(width, height)
end

renderer.window.run do
  time = Time.now.to_f

  group.children.each_with_index do |sprite, i|
    material = sprite.material
    scale = Math.sin(time + sprite.position.x * 0.01) * 0.3 + 1.0

    image_width = material.map.image.width
    image_height = material.map.image.height

    sprite.material.rotation += 0.01 * i.to_f
    sprite.scale.set(scale * image_width, scale * image_height, 1.0)

    if material.map != material_c
      material.opacity = Math.sin(time + sprite.position.x * 0.01) * 0.4 + 0.6
    end

    group.rotation.x = time * 0.5
    group.rotation.y = time * 0.75
    group.rotation.z = time * 1.0
  end

  renderer.clear
  renderer.render(scene, camera)
  renderer.clear_depth
  renderer.render(scene_ortho, camera_ortho)
end
