module Mittsu
  GL::MITTSU_PARAMS = {
    RepeatWrapping => GL::REPEAT,
    ClampToEdgeWrapping => GL::CLAMP_TO_EDGE,
    MirroredRepeatWrapping => GL::MIRRORED_REPEAT,

    NearestFilter => GL::NEAREST,
    NearestMipMapNearestFilter => GL::NEAREST_MIPMAP_NEAREST,
    NearestMipMapLinearFilter => GL::NEAREST_MIPMAP_LINEAR,

    LinearFilter => GL::LINEAR,
    LinearMipMapNearestFilter => GL::LINEAR_MIPMAP_NEAREST,
    LinearMipMapLinearFilter => GL::LINEAR_MIPMAP_LINEAR,

    UnsignedByteType => GL::UNSIGNED_BYTE,
    UnsignedShort4444Type => GL::UNSIGNED_SHORT_4_4_4_4,
    UnsignedShort5551Type => GL::UNSIGNED_SHORT_5_5_5_1,
    UnsignedShort565Type => GL::UNSIGNED_SHORT_5_6_5,

    ByteType => GL::BYTE,
    ShortType => GL::SHORT,
    UnsignedShortType => GL::UNSIGNED_SHORT,
    IntType => GL::INT,
    UnsignedIntType => GL::UNSIGNED_INT,
    FloatType => GL::FLOAT,

    AlphaFormat => GL::ALPHA,
    RGBFormat => GL::RGB,
    RGBAFormat => GL::RGBA,
    LuminanceFormat => GL::LUMINANCE,
    LuminanceAlphaFormat => GL::LUMINANCE_ALPHA,

    AddEquation => GL::FUNC_ADD,
    SubtractEquation => GL::FUNC_SUBTRACT,
    ReverseSubtractEquation => GL::FUNC_REVERSE_SUBTRACT,

    ZeroFactor => GL::ZERO,
    OneFactor => GL::ONE,
    SrcColorFactor => GL::SRC_COLOR,
    OneMinusSrcColorFactor => GL::ONE_MINUS_SRC_COLOR,
    SrcAlphaFactor => GL::SRC_ALPHA,
    OneMinusSrcAlphaFactor => GL::ONE_MINUS_SRC_ALPHA,
    DstAlphaFactor => GL::DST_ALPHA,
    OneMinusDstAlphaFactor => GL::ONE_MINUS_DST_ALPHA,

    DstColorFactor => GL::DST_COLOR,
    OneMinusDstColorFactor => GL::ONE_MINUS_DST_COLOR,
    SrcAlphaSaturateFactor => GL::SRC_ALPHA_SATURATE

    # TODO: populate with extension parameters?
  }
  GL::MITTSU_PARAMS.default = 0
end
