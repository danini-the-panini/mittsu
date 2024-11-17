# Mittsu

[![Gem Version](https://badge.fury.io/rb/mittsu.svg)](https://badge.fury.io/rb/mittsu)
[![Test Coverage](https://api.codeclimate.com/v1/badges/339a016dc2e7fc51c82a/test_coverage)](https://codeclimate.com/github/danini-the-panini/mittsu/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/339a016dc2e7fc51c82a/maintainability)](https://codeclimate.com/github/danini-the-panini/mittsu/maintainability)
[![Build Status](https://github.com/danini-the-panini/mittsu/workflows/Build/badge.svg)](https://github.com/danini-the-panini/mittsu/actions?query=workflow%3A%22Build%22)

3D Graphics Library for Ruby

Mittsu is a 3D Graphics Library for Ruby, based heavily on Three.js

## GIFs!

![Normal-mapped Earth](https://cloud.githubusercontent.com/assets/1171825/18411863/45328540-7781-11e6-986b-6e3f2551c719.gif)
![Point Light](https://cloud.githubusercontent.com/assets/1171825/18411861/4531bb4c-7781-11e6-92b4-b6ebda60e2c9.gif)
![Tank Demo](https://cloud.githubusercontent.com/assets/1171825/18411862/4531fe9a-7781-11e6-9665-b172df1a3645.gif)

(You can find the source for the Tank Demo [here](https://github.com/danini-the-panini/mittsu-tank-demo))

## Installation

Install the prerequisites:

Mittsu depends on Ruby 2.x

Add this line to your application's Gemfile:

```ruby
gem 'mittsu'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mittsu

## Usage

Create a basic scene with a perspective camera and a green box:

```ruby
require 'mittsu'

scene = Mittsu::Scene.new

camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)
camera.position.z = 5.0

box = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
)

scene.add(box)
```

### More Resources

Mittsu follows a similar structure to THREE.js, so you can generally use [the same documentation](http://threejs.org/docs/) for a description of the various classes and how they work.

If you want to actually render scenes, you'll need a renderer. There is a reference opengl renderer [here](https://github.com/danini-the-panini/mittsu-renderer-opengl).

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
