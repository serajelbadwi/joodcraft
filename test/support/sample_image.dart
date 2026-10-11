import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

/// صورة PNG صغيرة صالحة (1×1 RGBA) تُبنى برمجياً بترميز صحيح (CRC + zlib)،
/// لأن محرّك الطباعة يفكّ ترميز الصور فعلياً ويرفض أي بايتة PNG تالفة.
Uint8List samplePngBytes() {
  final List<int> ihdr = <int>[
    ..._uint32(1), // width
    ..._uint32(1), // height
    8, // bit depth
    6, // color type: RGBA
    0, // compression
    0, // filter
    0, // interlace
  ];
  // سطر واحد: بايت المرشّح (0) + بكسل RGBA واحد.
  final List<int> raw = <int>[0, 0x1B, 0x25, 0x39, 0xFF];
  final List<int> idat = ZLibCodec().encode(raw);

  final List<int> png = <int>[
    ...<int>[137, 80, 78, 71, 13, 10, 26, 10], // PNG signature
    ..._chunk('IHDR', ihdr),
    ..._chunk('IDAT', idat),
    ..._chunk('IEND', <int>[]),
  ];
  return Uint8List.fromList(png);
}

/// التمثيل Base64 لنفس الصورة (كما يُخزَّن محلياً).
String samplePngBase64() => base64Encode(samplePngBytes());

/// PNG صالح 1×1 بلون ماجنتا صريح (‎#FF00FF‎) مع ترميز Base64.
///
/// لون لا تنتجه النصوص ولا الخلفيات ولا الحدود، فيهتدي اختبارات الرَستَرة
/// إلى بكسلات الصورة تحديداً (مثل الشعار/التوقيع الغائبين من الصفحة الأولى).
String magentaPngBase64() {
  final List<int> ihdr = <int>[
    ..._uint32(1), // width
    ..._uint32(1), // height
    8, // bit depth
    6, // color type: RGBA
    0, // compression
    0, // filter
    0, // interlace
  ];
  // سطر واحد: بايت المرشّح (0) + بكسل RGBA واحد (ماجنتا).
  final List<int> raw = <int>[0, 0xFF, 0x00, 0xFF, 0xFF];
  final List<int> idat = ZLibCodec().encode(raw);

  final List<int> png = <int>[
    ...<int>[137, 80, 78, 71, 13, 10, 26, 10], // PNG signature
    ..._chunk('IHDR', ihdr),
    ..._chunk('IDAT', idat),
    ..._chunk('IEND', <int>[]),
  ];
  return base64Encode(png);
}

/// بايتات ليست صورة (لاختبار الرفض).
Uint8List notAnImageBytes() =>
    Uint8List.fromList(<int>[0x00, 0x01, 0x02, 0x03, 0x04, 0x05]);

List<int> _uint32(int value) => <int>[
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];

List<int> _chunk(String type, List<int> data) {
  final List<int> body = <int>[...ascii.encode(type), ...data];
  return <int>[..._uint32(data.length), ...body, ..._uint32(_crc32(body))];
}

int _crc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (final int byte in bytes) {
    crc ^= byte & 0xFF;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (0xEDB88320 ^ (crc >> 1)) : (crc >> 1);
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
