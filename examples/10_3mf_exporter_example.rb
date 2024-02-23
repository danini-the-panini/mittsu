require_relative './example_helper'

loader = Mittsu::OBJLoader.new
object = loader.load(File.expand_path('../male02.obj', __FILE__))

exporter = Mittsu::ThreeMFExporter.new
exporter.export(object, File.expand_path('../output.3mf', __FILE__))
