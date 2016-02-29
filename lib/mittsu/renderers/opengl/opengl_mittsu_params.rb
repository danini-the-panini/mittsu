module Mittsu
  GL_MITTSU_PARAMS = {
    RepeatWrapping => GL_REPEAT,
    ClampToEdgeWrapping => GL_CLAMP_TO_EDGE,
    MirroredRepeatWrapping => GL_MIRRORED_REPEAT,

    NearestFilter => GL_NEAREST,
    NearestMipMapNearestFilter => GL_NEAREST_MIPMAP_NEAREST,
    NearestMipMapLinearFilter => GL_NEAREST_MIPMAP_LINEAR,

    LinearFilter => GL_LINEAR,
    LinearMipMapNearestFilter => GL_LINEAR_MIPMAP_NEAREST,
    LinearMipMapLinearFilter => GL_LINEAR_MIPMAP_LINEAR,

    UnsignedByteType => GL_UNSIGNED_BYTE,
    UnsignedShort4444Type => GL_UNSIGNED_SHORT_4_4_4_4,
    UnsignedShort5551Type => GL_UNSIGNED_SHORT_5_5_5_1,
    UnsignedShort565Type => GL_UNSIGNED_SHORT_5_6_5,

    ByteType => GL_BYTE,
    ShortType => GL_SHORT,
    UnsignedShortType => GL_UNSIGNED_SHORT,
    IntType => GL_INT,
    UnsignedIntType => GL_UNSIGNED_INT,
    FloatType => GL_FLOAT,

    AlphaFormat => GL_ALPHA,
    RGBFormat => GL_RGB,
    RGBAFormat => GL_RGBA,
    LuminanceFormat => GL_LUMINANCE,
    LuminanceAlphaFormat => GL_LUMINANCE_ALPHA,

    AddEquation => GL_FUNC_ADD,
    SubtractEquation => GL_FUNC_SUBTRACT,
    ReverseSubtractEquation => GL_FUNC_REVERSE_SUBTRACT,

    ZeroFactor => GL_ZERO,
    OneFactor => GL_ONE,
    SrcColorFactor => GL_SRC_COLOR,
    OneMinusSrcColorFactor => GL_ONE_MINUS_SRC_COLOR,
    SrcAlphaFactor => GL_SRC_ALPHA,
    OneMinusSrcAlphaFactor => GL_ONE_MINUS_SRC_ALPHA,
    DstAlphaFactor => GL_DST_ALPHA,
    OneMinusDstAlphaFactor => GL_ONE_MINUS_DST_ALPHA,

    DstColorFactor => GL_DST_COLOR,
    OneMinusDstColorFactor => GL_ONE_MINUS_DST_COLOR,
    SrcAlphaSaturateFactor => GL_SRC_ALPHA_SATURATE

    # TODO: populate with extension parameters?
  }
  GL_MITTSU_PARAMS.default = 0
end
