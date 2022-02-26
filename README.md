# Mittsu

[![Gem Version](https://badge.fury.io/rb/mittsu.svg)](https://badge.fury.io/rb/mittsu)
[![Test Coverage](https://api.codeclimate.com/v1/badges/22be300984d81fa10af8/test_coverage)](https://codeclimate.com/github/danini-the-panini/mittsu/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/22be300984d81fa10af8/maintainability)](https://codeclimate.com/github/danini-the-panini/mittsu/maintainability)
[![Build Status](https://github.com/danini-the-panini/mittsu/workflows/Build/badge.svg)](https://github.com/danini-the-panini/mittsu/actions?query=workflow%3A%22Build%22)

3D Graphics Library for Ruby

Mittsu makes 3D graphics easier by providing an abstraction over OpenGL, and is based heavily off of [THREE.js](http://threejs.org). No more weird pointers and wondering about the difference between a VAO and a VBO (besides the letter). Simply think of something awesome and make it!

## GIFs!

![Normal-mapped Earth](https://cloud.githubusercontent.com/assets/1171825/18411863/45328540-7781-11e6-986b-6e3f2551c719.gif)
![Point Light](https://cloud.githubusercontent.com/assets/1171825/18411861/4531bb4c-7781-11e6-92b4-b6ebda60e2c9.gif)
![Tank Demo](https://cloud.githubusercontent.com/assets/1171825/18411862/4531fe9a-7781-11e6-9665-b172df1a3645.gif)

(You can find the source for the Tank Demo [here](https://github.com/danini-the-panini/mittsu-tank-demo))

## Installation

Install the prerequisites:

Mittsu depends on Ruby 2.x, OpenGL 3.3+, and GLFW 3.1.x

```bash
# OSX
$ brew install glfw3

# Ubuntu
$ sudo apt-get install libglfw3
```

**NOTE:** On Windows, you will have to manually specify the glfw3.dll path in an environment variable
(you can download it [here](http://www.glfw.org/download.html))
```bash
# ex) set MITTSU_LIBGLFW_PATH=C:\Users\username\lib-mingw-w64
> set MITTSU_LIBGLFW_PATH=C:\path\to\glfw3.dll
> ruby your_awesome_mittsu_app.rb
```

Add this line to your application's Gemfile:

```ruby
gem 'mittsu'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mittsu

## Usage

### tl;dr

Copy-Paste and Run:

```ruby
require 'mittsu'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: 'Hello, World!'

scene = Mittsu::Scene.new

camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)
camera.position.z = 5.0

box = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
)

scene.add(box)

renderer.window.run do
  box.rotation.x += 0.1
  box.rotation.y += 0.1

  renderer.render(scene, camera)
end
```

### Step by Step

First, we need to require Mittsu in order to use it:
```ruby
require 'mittsu'
```

Then, we'll define some constants to help us with setting up our 3D environment:
```ruby
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f
```

The aspect ratio will be used for setting up the camera later.

Once we have all that we can create the canvas we will use to draw our graphics onto. In Mittsu this is called a renderer. It provides a window and an OpenGL context:

```ruby
renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: 'Hello, World!'
```
This will give us an 800x600 window with the title `Hello, World!`.

Now that we have our canvas, let's start setting up the scene we wish to draw onto it:

```ruby
scene = Mittsu::Scene.new
```

A scene is like a stage where all our 3D objects live and animate.

We can't draw a 3D scene without knowing where we're looking:

```ruby
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)
```

This camera has a 75° field-of-view (FOV), the aspect ratio of the window (which we defined earlier), and shows everything between a distance of 0.1 to 1000.0 away from the camera.

The camera starts off at the origin `[0,0,0]` and faces the negative Z-axis. We'll position it somewhere along the positive Z-axis so that it is looking at the center of the scene from a short distance:

```ruby
camera.position.z = 5.0
```

Our scene isn't going to be very exciting if there is nothing in it, so we'll create a box:

```ruby
box = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
)
```

A `Mesh` in Mittsu is the combination of a `Geometry` (the shape of the object) and a `Material` (the "look" of the object). Here we've created a 1x1x1 box that is colored green.

Box in hand, we make it part of our scene:

```ruby
scene.add(box)
```

Here comes the fun part... the render loop!

```ruby
renderer.window.run do
```

The given block is called every frame. This is where you can tell the renderer what scene to draw, and do any updates to the objects in your scene.

Just to make things a bit more interesting, we'll make the box rotate around its X and Y axes, so that it spins like crazy.

```ruby
box.rotation.x += 0.1
box.rotation.y += 0.1
```

Last but not least, we tell the renderer to draw our scene this frame, which will tell the graphics processor to draw our green box with its updated rotation.

```ruby
renderer.render(scene, camera)
```

Easy peasy! :)

```ruby
end
```


### More Resources

Mittsu follows a similar structure to THREE.js, so you can generally use [the same documentation](http://threejs.org/docs/) for a description of the various classes and how they work.

If you just want to see what Mittsu can do and how to do it, take a peek inside the `examples` folder.

## Where you can help

1. Testing!

    Currently the only unit tests are for most of the maths library, otherwise the library is tested by running the examples and checking that they look correct.

2. Refactoring!

    The code is unfortunately still a mess. Mittsu started out as a direct port of THREE.js, and JavaScript to Ruby is not an exact science.

3. Find Bugs!

    Mittsu is still very young, and there are plenty of small bugs and glitches that need to be ironed out. If you find a bug, create an issue so we can track it and squash it.

4. Add all the features!

    Some of the things I'd like to see ported from THREE.js include:

    * Picking (clicking on 3D objects in a scene)
    * Bone structure/animation (e.g. for character movements)
    * Lens Flares! (for JJ Abrams)
    * All the Extras and Helpers (who doesn't need extra help?)

5. Write documentation!

    You can use the same docs as THREE.js for now, but I would like to provide Mittsu-specific documentation so devs don't have to keep replacing `new THREE.Thing()` with `Mittsu::Thing.new`.

## Contributing

1. Fork it ( https://github.com/danini-the-panini/mittsu/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Thank you for helping me help you help us all. ;)
