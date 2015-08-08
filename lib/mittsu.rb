require "mittsu/version"
require "mittsu/math"
require "mittsu/core"
require "mittsu/cameras"
require "mittsu/scenes"

module Mittsu
  MOUSE_LEFT = 0
  MOUSE_MIDDLE = 1
  MOUSE_RIGHT = 2

  # GL STATE CONSTANTS

  CullFaceNone = 0
  CullFaceBack = 1
  CullFaceFront = 2
  CullFaceFrontBack = 3

  FrontFaceDirectionCW = 0
  FrontFaceDirectionCCW = 1

  # SHADOWING TYPES

  BasicShadowMap = 0
  PCFShadowMap = 1
  PCFSoftShadowMap = 2

  # MATERIAL CONSTANTS

  # side

  FrontSide = 0
  BackSide = 1
  DoubleSide = 2

  # colors

  NoColors = 0
  FaceColors = 1
  VertexColors = 2

  # blending modes

  NoBlending = 0
  NoprmalBlending = 1
  AdditiveBlending = 2
  SubtractiveBlending = 3
  MultiplyBlending = 4
  CustomBlending = 5

  # custom blending equations
  # (numbers start from 100 not to clash with other
  #  mappings to OpenGL constants defined in texture.rb)

  AddEquation = 100
  SubtractEquation = 101
  ReverseSubtractEquation = 102
  MinEquation = 103
  MaxEquation = 104

  # custom blending destination factors
  ZeroFactor = 200
  OneFactor = 201
  SrcColorFactor = 202
  OneMinusSrcColorFactor = 203
  SrcAlphaFactor = 204
  OneMinusSrcAlphaFactor = 205
  DstAlphaFactor = 206
  OneMinusDstAlphaFactor = 207

  # custom blending source factors

  #ZeroFactor = 200
  #OneFactor = 201
  #SrcAlphaFactor = 204
  #OneMinusSrcAlphaFactor = 205
  #DstAlphaFactor = 206
  #OneMinusDstAlphaFactor = 207
  DstColorFactor = 208
  OneMinusDstColorFactor = 209
  SrcAlphaSaturateFactor = 210

  # TEXTURE CONSTANTS

  MultiplyOperation = 0
  MixOperation = 1
  AddOperation = 2

  # Mapping modes

  UVMapping = 300

  CubeReflectionMapping = 301
  CubeRefractionMapping = 302

  EquirectangularReflectionMapping = 303
  EquirectangularRefractionMapping = 304

  SphericalReflectionMapping = 305

  # Wrapping modes

  RepeatWrapping = 1000
  ClampToEdgeWrapping = 1001
  MirroredRepeatWrapping = 1002

  # Filters

  NearestFilter = 1003
  NearestMipMapNearestFilter = 1004
  NearestMipMapLinearFilter = 1005
  LinearFilter = 1006
  LinearMipMapNearestFilter = 1007
  LinearMipMapLinearFilter = 1008

  # Data types

  UnsignedByteType = 1009
  ByteType = 1010
  ShortType = 1011
  UnsignedShortType = 1012
  IntType = 1013
  UnsignedIntType = 1014
  FloatType = 1015
  HalfFloatType = 1025

  # Pixel types

  #UnsignedByteType = 1009
  UnsignedShort4444Type = 1016
  UnsignedShort5551Type = 1017
  UnsignedShort565Type = 1018

  # Pixel formats

  AlphaFormat = 1019
  RGBFormat = 1020
  RGBAFormat = 1021
  LuminanceFormat = 1022
  LuminanceAlphaFormat = 1023
  # RGBEFormat handled as RGBAFormat in shaders
  RGBEFormat = RGBAFormat #1024

  # DDS / ST3C Compressed texture formats

  RGB_S3TC_DXT1_Format = 2001
  RGBA_S3TC_DXT1_Format = 2002
  RGBA_S3TC_DXT3_Format = 2003
  RGBA_S3TC_DXT5_Format = 2004

  # PVRTC compressed texture formats

  RGB_PVRTC_4BPPV1_Format = 2100
  RGB_PVRTC_2BPPV1_Format = 2101
  RGBA_PVRTC_4BPPV1_Format = 2102
  RGBA_PVRTC_2BPPV1_Format = 2103
end
