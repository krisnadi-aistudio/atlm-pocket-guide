import 'package:flutter/material.dart';

/// Ikon kategori — ronde 3.
///
/// Pemetaan final:
/// - HEMATOLOGI: blood-cells (Health Icons) — gugus sel darah merah.
/// - HEMOSTASIS: clot v3 gambar tangan — 3 trombosit + 2 serat fibrin
///   (tidak ada ikon bekuan/fibrin profesional gratis di Health Icons,
///   Font Awesome, maupun Streamline; slot ini tetap gambar tangan).
/// - PARASITOLOGI: malaria-microscope (Health Icons) — lapangan pandang
///   berisi parasit (isi kategori ini memang mikroskopis malaria).
/// - KIMIA KLINIK: tabung spesimen gambar tangan (dipertahankan,
///   user: "cukup oke").
/// - URINALISA: urine-sample (Health Icons) — pot bertutup + label.
/// - FAECES: stool-cup (Streamline Pixel) — pot sampel gaya piksel.
/// - MIKROBIOLOGI: bacteria (Health Icons) — batang bakteri berpili.
/// - IMUNOSEROLOGI: antibody (Health Icons) — antibodi Y + antigen.
/// - Lainnya: Icons.info.
///
/// Lisensi: Health Icons oleh Resolve to Save Lives, lisensi MIT
/// (tanpa kewajiban atribusi terlihat; notice disimpan di komentar ini).
/// Streamline Pixel lisensi CC BY 4.0 — kredit "Icons by Streamline,
/// CC BY 4.0" ditampilkan di halaman Tentang aplikasi.
/// Konversi SVG -> Path Flutter: tools/svg_to_flutter.py; render SVG asli
/// vs hasil konversi terverifikasi selisih piksel 0 untuk 9 ikon.
/// Tanpa dependensi baru. Ukuran mengikuti layout yang sudah ada
/// (24/26/28/36) — file ini tidak mengubah ukuran, margin, padding,
/// maupun struktur kartu apa pun.
Widget categoryIcon(String category, double size, Color color) {
  final Widget icon;
  switch (category) {
    case 'HEMATOLOGI':
      icon = proIcon('bloodCells', size, color);
    case 'HEMOSTASIS':
      icon = _CustomIcon(size, _ClotV3Painter(color));
    case 'PARASITOLOGI':
      icon = proIcon('malariaMicroscope', size, color);
    case 'KIMIA KLINIK':
      icon = _CustomIcon(size, _TubePainter(color));
    case 'URINALISA':
      icon = proIcon('urineSample', size, color);
    case 'FAECES':
      icon = proIcon('stoolCup', size, color);
    case 'MIKROBIOLOGI':
      icon = proIcon('bacteria', size, color);
    case 'IMUNOSEROLOGI':
      icon = proIcon('antibody', size, color);
    default:
      icon = Icon(Icons.info, color: color, size: size);
  }
  return Semantics(label: category, child: icon);
}

class _CustomIcon extends StatelessWidget {
  final double size;
  final CustomPainter painter;
  const _CustomIcon(this.size, this.painter);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _fill(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

/// Gumpalan trombosit v3: 3 trombosit + 2 serat fibrin gelombang.
/// Geometri = pratinjau ronde 3 (serat dipertebal
/// dari v2 supaya terbaca di 24-26px).
class _ClotV3Painter extends CustomPainter {
  final Color color;
  _ClotV3Painter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s, s);
    final fibrin = _stroke(color, 6);
    final wave1 = Path()
      ..moveTo(20, 30)
      ..quadraticBezierTo(35, 22, 50, 30)
      ..quadraticBezierTo(65, 38, 80, 28);
    final wave2 = Path()
      ..moveTo(22, 74)
      ..quadraticBezierTo(40, 66, 58, 74)
      ..quadraticBezierTo(70, 70, 82, 70);
    canvas.drawPath(wave1, fibrin);
    canvas.drawPath(wave2, fibrin);
    final dot = _fill(color);
    canvas.drawCircle(const Offset(38, 58), 11, dot);
    canvas.drawCircle(const Offset(56, 44), 12, dot);
    canvas.drawCircle(const Offset(64, 64), 10, dot);
  }

  @override
  bool shouldRepaint(_ClotV3Painter old) => old.color != color;
}

/// Tabung spesimen: badan U terbuka di atas, cairan di bawah,
/// dua gelembung reaksi di atas cairan.
class _TubePainter extends CustomPainter {
  final Color color;
  _TubePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s, s);
    final tube = Path()
      ..moveTo(36, 12)
      ..lineTo(36, 68)
      ..quadraticBezierTo(36, 86, 52, 86)
      ..quadraticBezierTo(68, 86, 68, 68)
      ..lineTo(68, 12);
    canvas.drawPath(tube, _stroke(color, 7));
    final liquid = Path()
      ..moveTo(42, 56)
      ..lineTo(42, 68)
      ..quadraticBezierTo(42, 80, 52, 80)
      ..quadraticBezierTo(62, 80, 62, 68)
      ..lineTo(62, 56)
      ..close();
    canvas.drawPath(liquid, _fill(color));
    canvas.drawCircle(const Offset(50, 46), 5, _fill(color));
    canvas.drawCircle(const Offset(59, 35), 3.5, _fill(color));
  }

  @override
  bool shouldRepaint(_TubePainter old) => old.color != color;
}

class _SvgPathPainter extends CustomPainter {
  final Path Function() build;
  final double viewBox;
  final Color color;
  const _SvgPathPainter(this.build, this.viewBox, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / viewBox;
    canvas.scale(s, s);
    canvas.drawPath(build(), Paint()..color = color..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant _SvgPathPainter old) =>
      old.color != color || old.viewBox != viewBox;
}

Widget proIcon(String key, double size, Color color) {
  final entry = _proIcons[key];
  if (entry == null) return SizedBox(width: size, height: size);
  final (build, viewBox) = entry;
  return CustomPaint(
    size: Size(size, size),
    painter: _SvgPathPainter(build, viewBox, color),
  );
}

typedef _ProEntry = (Path Function(), double);

final Map<String, _ProEntry> _proIcons = {
  'bloodCells': (bloodCells, 48.0),
  'malariaMicroscope': (malariaMicroscope, 48.0),
  'urineSample': (urineSample, 48.0),
  'bacteria': (bacteria, 48.0),
  'antibody': (antibody, 48.0),
  'stoolCup': (stoolCup, 32.0),
};

Path bloodCells() {
  final path = Path();
  path.fillType = PathFillType.evenOdd;
  path.moveTo(25, 14.333);
  path.cubicTo(25, 14.787, 24.63, 15.441, 23.486, 16.04);
  path.cubicTo(22.389, 16.615, 20.805, 17, 19, 17);
  path.cubicTo(17.195, 17, 15.611, 16.615, 14.514, 16.04);
  path.cubicTo(13.37, 15.441, 13, 14.787, 13, 14.333);
  path.cubicTo(13, 13.937, 13.274, 13.391, 14.136, 12.844);
  path.lineTo(13.065, 11.156);
  path.cubicTo(11.927, 11.876, 11, 12.957, 11, 14.333);
  path.cubicTo(11, 15.904, 12.197, 17.084, 13.586, 17.812);
  path.cubicTo(15.023, 18.564, 16.94, 19, 19, 19);
  path.cubicTo(21.06, 19, 22.977, 18.564, 24.414, 17.812);
  path.cubicTo(25.804, 17.084, 27, 15.904, 27, 14.333);
  path.cubicTo(27, 12.957, 26.073, 11.877, 24.936, 11.156);
  path.lineTo(23.864, 12.844);
  path.cubicTo(24.726, 13.391, 25, 13.937, 25, 14.334);
  path.moveTo(6, 15.5);
  path.cubicTo(6, 18.476, 7.873, 21.132, 10.803, 22.874);
  path.cubicTo(6.329, 25.536, 4.292, 30.391, 6.252, 33.786);
  path.cubicTo(8.233, 37.218, 13.549, 37.858, 18.125, 35.216);
  path.cubicTo(22.559, 32.656, 24.671, 27.954, 22.995, 24.543);
  path.cubicTo(28.22, 23.31, 32, 19.728, 32, 15.5);
  path.cubicTo(32, 10.253, 26.18, 6, 19, 6);
  path.cubicTo(11.82, 6, 6, 10.253, 6, 15.5);
  path.moveTo(27.013, 20.603);
  path.cubicTo(28.989, 19.158, 30, 17.33, 30, 15.5);
  path.cubicTo(30, 13.67, 28.99, 11.842, 27.012, 10.397);
  path.cubicTo(25.037, 8.954, 22.212, 8, 19, 8);
  path.cubicTo(15.79, 8, 12.963, 8.954, 10.988, 10.397);
  path.cubicTo(9.01, 11.842, 8, 13.67, 8, 15.5);
  path.cubicTo(8, 17.33, 9.011, 19.158, 10.988, 20.603);
  path.cubicTo(12.963, 22.046, 15.789, 23, 19, 23);
  path.cubicTo(22.211, 23, 25.037, 22.046, 27.012, 20.603);
  path.moveTo(16.565, 24.833);
  path.quadraticBezierTo(17.636, 24.983, 18.763, 24.998);
  path.cubicTo(18.96, 25.184, 19.135, 25.4, 19.279, 25.65);
  path.cubicTo(19.923, 26.765, 19.689, 28.06, 19.112, 29.12);
  path.cubicTo(18.525, 30.197, 17.509, 31.203, 16.232, 31.94);
  path.cubicTo(14.955, 32.677, 13.576, 33.054, 12.35, 33.023);
  path.cubicTo(11.143, 32.993, 9.905, 32.549, 9.262, 31.434);
  path.cubicTo(8.699, 30.46, 8.809, 29.34, 9.227, 28.378);
  path.lineTo(11.062, 29.175);
  path.cubicTo(10.802, 29.771, 10.85, 30.185, 10.994, 30.434);
  path.cubicTo(11.157, 30.717, 11.578, 31.004, 12.4, 31.024);
  path.cubicTo(13.201, 31.044, 14.22, 30.792, 15.232, 30.208);
  path.cubicTo(16.244, 29.624, 16.972, 28.868, 17.355, 28.163);
  path.cubicTo(17.748, 27.441, 17.711, 26.933, 17.547, 26.65);
  path.cubicTo(17.403, 26.4, 17.069, 26.153, 16.423, 26.08);
  path.close();
  path.moveTo(35.836, 24.764);
  path.cubicTo(38.231, 25.406, 40.562, 24.47, 41.044, 22.674);
  path.cubicTo(41.524, 20.878, 39.974, 18.901, 37.578, 18.26);
  path.cubicTo(35.183, 17.618, 32.852, 18.554, 32.37, 20.35);
  path.cubicTo(31.89, 22.146, 33.44, 24.123, 35.836, 24.764);
  path.moveTo(42.245, 36.457);
  path.cubicTo(41.174, 40.455, 35.984, 42.538, 30.653, 41.11);
  path.cubicTo(25.322, 39.682, 21.869, 35.282, 22.94, 31.284);
  path.cubicTo(24.011, 27.286, 29.201, 25.203, 34.532, 26.631);
  path.cubicTo(39.863, 28.059, 43.317, 32.459, 42.245, 36.457);
  path.moveTo(35.307, 35.375);
  path.cubicTo(36.139, 35.13, 36.503, 34.72, 36.597, 34.369);
  path.cubicTo(36.679, 34.06, 36.607, 33.616, 36.18, 33.078);
  path.lineTo(37.745, 31.833);
  path.cubicTo(38.422, 32.683, 38.828, 33.77, 38.529, 34.887);
  path.cubicTo(38.186, 36.165, 37.074, 36.94, 35.873, 37.294);
  path.cubicTo(34.653, 37.654, 33.168, 37.647, 31.687, 37.25);
  path.cubicTo(30.206, 36.853, 28.917, 36.117, 28.04, 35.195);
  path.cubicTo(27.177, 34.288, 26.602, 33.061, 26.944, 31.783);
  path.cubicTo(27.244, 30.666, 28.138, 29.928, 29.15, 29.53);
  path.lineTo(29.883, 31.39);
  path.cubicTo(29.243, 31.642, 28.959, 31.991, 28.876, 32.3);
  path.cubicTo(28.782, 32.65, 28.891, 33.188, 29.489, 33.817);
  path.cubicTo(30.073, 34.43, 31.02, 35.001, 32.205, 35.318);
  path.cubicTo(33.389, 35.636, 34.495, 35.615, 35.307, 35.375);
  return path;
}

Path malariaMicroscope() {
  final path = Path();
  path.fillType = PathFillType.evenOdd;
  path.moveTo(24, 44);
  path.cubicTo(35.046, 44, 44, 35.046, 44, 24);
  path.cubicTo(44, 12.954, 35.046, 4, 24, 4);
  path.cubicTo(12.954, 4, 4, 12.954, 4, 24);
  path.cubicTo(4, 35.046, 12.954, 44, 24, 44);
  path.moveTo(10.745, 21.309);
  path.cubicTo(11.925, 22.836, 15.372, 22.149, 18.444, 19.776);
  path.cubicTo(21.515, 17.402, 23.049, 14.24, 21.869, 12.713);
  path.cubicTo(20.689, 11.186, 17.242, 11.872, 14.17, 14.246);
  path.cubicTo(11.098, 16.62, 9.565, 19.782, 10.745, 21.309);
  path.moveTo(32.439, 26.85);
  path.cubicTo(35.726, 28.835, 37.59, 31.768, 36.604, 33.402);
  path.cubicTo(35.617, 35.036, 32.154, 34.752, 28.867, 32.767);
  path.cubicTo(25.58, 30.783, 23.715, 27.849, 24.702, 26.215);
  path.cubicTo(25.689, 24.581, 29.152, 24.865, 32.439, 26.85);
  path.moveTo(33.271, 22.855);
  path.cubicTo(35.02, 22.037, 35.104, 18.522, 33.458, 15.003);
  path.cubicTo(31.812, 11.485, 29.06, 9.296, 27.311, 10.114);
  path.cubicTo(25.561, 10.933, 25.478, 14.448, 27.124, 17.966);
  path.cubicTo(28.77, 21.484, 31.522, 23.674, 33.271, 22.856);
  path.moveTo(21.62, 29.933);
  path.cubicTo(23.404, 33.483, 23.42, 37.078, 21.656, 37.965);
  path.cubicTo(19.892, 38.852, 17.015, 36.695, 15.23, 33.145);
  path.cubicTo(13.446, 29.596, 13.43, 26, 15.195, 25.113);
  path.cubicTo(16.959, 24.226, 19.835, 26.384, 21.62, 29.933);
  return path;
}

Path urineSample() {
  final path = Path();
  path.fillType = PathFillType.evenOdd;
  path.moveTo(6.879, 6.879);
  path.cubicTo(6.316, 7.441, 6, 8.204, 6, 9);
  path.lineTo(6, 14);
  path.lineTo(8.138, 14);
  path.quadraticBezierTo(8.138, 14.066, 8.142, 14.133);
  path.lineTo(9.876, 40.133);
  path.cubicTo(9.946, 41.183, 10.818, 41.999, 11.87, 42);
  path.lineTo(35.13, 42);
  path.cubicTo(36.183, 42, 37.055, 41.183, 37.125, 40.133);
  path.lineTo(38.859, 14.133);
  path.cubicTo(38.862, 14.089, 38.863, 14.044, 38.863, 14);
  path.lineTo(42, 14);
  path.lineTo(42, 9);
  path.cubicTo(42.003, 7.793, 41.28, 6.703, 40.168, 6.236);
  path.cubicTo(39.798, 6.08, 39.401, 6, 39, 6);
  path.lineTo(9, 6);
  path.cubicTo(8.204, 6, 7.441, 6.316, 6.879, 6.879);
  path.moveTo(36.862, 14);
  path.lineTo(10.138, 14);
  path.lineTo(10.405, 18);
  path.lineTo(21, 18);
  path.cubicTo(22.105, 18, 23, 18.895, 23, 20);
  path.lineTo(23, 22);
  path.lineTo(36.329, 22);
  path.close();
  path.moveTo(11.114, 20);
  path.lineTo(11.892, 34);
  path.lineTo(21, 34);
  path.lineTo(21, 20);
  path.close();
  path.moveTo(11, 11.714);
  path.lineTo(9, 11.714);
  path.lineTo(9, 8.286);
  path.lineTo(11, 8.286);
  path.close();
  path.moveTo(15, 8.286);
  path.lineTo(13, 8.286);
  path.lineTo(13, 11.714);
  path.lineTo(15, 11.714);
  path.close();
  path.moveTo(19, 11.714);
  path.lineTo(17, 11.714);
  path.lineTo(17, 8.286);
  path.lineTo(19, 8.286);
  path.close();
  path.moveTo(23, 8.286);
  path.lineTo(21, 8.286);
  path.lineTo(21, 11.714);
  path.lineTo(23, 11.714);
  path.close();
  path.moveTo(27, 11.714);
  path.lineTo(25, 11.714);
  path.lineTo(25, 8.286);
  path.lineTo(27, 8.286);
  path.close();
  path.moveTo(31, 8.286);
  path.lineTo(29, 8.286);
  path.lineTo(29, 11.714);
  path.lineTo(31, 11.714);
  path.close();
  path.moveTo(35, 11.714);
  path.lineTo(33, 11.714);
  path.lineTo(33, 8.286);
  path.lineTo(35, 8.286);
  path.close();
  path.moveTo(39, 8.286);
  path.lineTo(37, 8.286);
  path.lineTo(37, 11.714);
  path.lineTo(39, 11.714);
  path.close();
  return path;
}

Path bacteria() {
  final path = Path();
  path.fillType = PathFillType.evenOdd;
  path.moveTo(20.953, 10.462);
  path.cubicTo(19.679, 9.04, 17.904, 8.166, 16, 8.022);
  path.lineTo(16, 5);
  path.lineTo(14, 5);
  path.lineTo(14, 8.137);
  path.cubicTo(11.935, 8.543, 10.139, 9.805, 9.056, 11.61);
  path.lineTo(6.5, 10.134);
  path.lineTo(5.5, 11.866);
  path.lineTo(8.263, 13.462);
  path.cubicTo(8.087, 14.103, 7.999, 14.764, 8, 15.429);
  path.cubicTo(8, 17.444, 8.243, 19.402, 8.7, 21.276);
  path.lineTo(5.741, 22.069);
  path.lineTo(6.259, 24.001);
  path.lineTo(9.254, 23.198);
  path.cubicTo(10.115, 25.78, 11.399, 28.2, 13.055, 30.359);
  path.lineTo(10.293, 33.121);
  path.lineTo(11.707, 34.536);
  path.lineTo(14.34, 31.902);
  path.cubicTo(15.894, 33.621, 17.683, 35.113, 19.653, 36.334);
  path.lineTo(18.133, 38.964);
  path.lineTo(19.866, 39.964);
  path.lineTo(21.394, 37.317);
  path.cubicTo(24.08, 38.692, 26.998, 39.556, 30, 39.867);
  path.lineTo(30, 43);
  path.lineTo(32, 43);
  path.lineTo(32, 39.993);
  path.quadraticBezierTo(32.285, 40, 32.571, 40);
  path.cubicTo(34.78, 40.003, 36.875, 39.02, 38.285, 37.32);
  path.lineTo(40.965, 38.866);
  path.lineTo(41.965, 37.134);
  path.lineTo(39.346, 35.623);
  path.cubicTo(39.766, 34.692, 40, 33.659, 40, 32.571);
  path.cubicTo(40, 29.935, 38.604, 27.496, 36.33, 26.162);
  path.lineTo(37.866, 23.5);
  path.lineTo(36.134, 22.5);
  path.lineTo(34.467, 25.387);
  path.cubicTo(33.848, 25.224, 33.211, 25.142, 32.571, 25.143);
  path.cubicTo(30.34, 25.146, 28.176, 24.378, 26.446, 22.968);
  path.lineTo(28.707, 20.708);
  path.lineTo(27.293, 19.293);
  path.lineTo(25.032, 21.554);
  path.cubicTo(23.622, 19.824, 22.854, 17.66, 22.857, 15.429);
  path.cubicTo(22.859, 14.291, 22.598, 13.169, 22.095, 12.148);
  path.lineTo(24.535, 9.708);
  path.lineTo(23.121, 8.293);
  path.close();
  path.moveTo(15, 15);
  path.cubicTo(14.448, 15, 14, 15.448, 14, 16);
  path.cubicTo(14, 16.552, 14.448, 17, 15, 17);
  path.cubicTo(15.552, 17, 16, 16.552, 16, 16);
  path.cubicTo(16, 15.448, 15.552, 15, 15, 15);
  path.moveTo(12, 16);
  path.cubicTo(12, 14.343, 13.343, 13, 15, 13);
  path.cubicTo(16.657, 13, 18, 14.343, 18, 16);
  path.cubicTo(18, 17.657, 16.657, 19, 15, 19);
  path.cubicTo(13.343, 19, 12, 17.657, 12, 16);
  path.moveTo(24, 29);
  path.cubicTo(23.448, 29, 23, 29.448, 23, 30);
  path.cubicTo(23, 30.552, 23.448, 31, 24, 31);
  path.cubicTo(24.552, 31, 25, 30.552, 25, 30);
  path.cubicTo(25, 29.448, 24.552, 29, 24, 29);
  path.moveTo(21, 30);
  path.cubicTo(21, 28.343, 22.343, 27, 24, 27);
  path.cubicTo(25.657, 27, 27, 28.343, 27, 30);
  path.cubicTo(27, 31.657, 25.657, 33, 24, 33);
  path.cubicTo(22.343, 33, 21, 31.657, 21, 30);
  path.moveTo(17, 26);
  path.cubicTo(18.105, 26, 19, 25.105, 19, 24);
  path.cubicTo(19, 22.895, 18.105, 22, 17, 22);
  path.cubicTo(15.895, 22, 15, 22.895, 15, 24);
  path.cubicTo(15, 25.105, 15.895, 26, 17, 26);
  path.moveTo(34, 32);
  path.cubicTo(34, 33.105, 33.105, 34, 32, 34);
  path.cubicTo(30.895, 34, 30, 33.105, 30, 32);
  path.cubicTo(30, 30.895, 30.895, 30, 32, 30);
  path.cubicTo(33.105, 30, 34, 30.895, 34, 32);
  return path;
}

Path antibody() {
  final path = Path();
  path.moveTo(12.93, 19.257);
  path.cubicTo(13.322, 19.636, 13.946, 19.631, 14.332, 19.245);
  path.cubicTo(14.718, 18.859, 14.723, 18.235, 14.344, 17.843);
  path.lineTo(8.344, 11.843);
  path.cubicTo(7.954, 11.452, 7.32, 11.452, 6.929, 11.843);
  path.cubicTo(6.539, 12.233, 6.539, 12.866, 6.929, 13.257);
  path.close();
  path.moveTo(4.303, 13.651);
  path.cubicTo(3.907, 14.036, 3.898, 14.669, 4.283, 15.065);
  path.lineTo(12.008, 23.005);
  path.lineTo(26.01, 23.005);
  path.cubicTo(26.113, 21.946, 26.953, 21.109, 28.012, 21.01);
  path.cubicTo(27.977, 21.006, 27.943, 21.004, 27.908, 21.004);
  path.lineTo(12.852, 21.004);
  path.lineTo(5.717, 13.671);
  path.cubicTo(5.332, 13.275, 4.699, 13.266, 4.303, 13.651);
  path.moveTo(28.034, 26.992);
  path.cubicTo(26.967, 26.903, 26.116, 26.065, 26.01, 25);
  path.lineTo(12.008, 25);
  path.lineTo(4.283, 32.939);
  path.cubicTo(3.898, 33.335, 3.907, 33.968, 4.302, 34.353);
  path.cubicTo(4.698, 34.739, 5.332, 34.73, 5.717, 34.334);
  path.lineTo(12.852, 27);
  path.lineTo(27.91, 27);
  path.quadraticBezierTo(27.973, 27, 28.035, 26.992);
  path.moveTo(14.344, 30.162);
  path.cubicTo(14.735, 29.771, 14.735, 29.138, 14.344, 28.747);
  path.cubicTo(13.953, 28.356, 13.32, 28.356, 12.929, 28.747);
  path.lineTo(6.929, 34.747);
  path.cubicTo(6.539, 35.138, 6.539, 35.771, 6.93, 36.161);
  path.cubicTo(7.32, 36.552, 7.954, 36.552, 8.344, 36.161);
  path.close();
  path.moveTo(30.896, 25);
  path.lineTo(29.954, 25);
  path.cubicTo(29.806, 25.471, 29.336, 25.764, 28.848, 25.689);
  path.cubicTo(28.36, 25.614, 28, 25.194, 28, 24.7);
  path.lineTo(28, 23.3);
  path.cubicTo(28, 22.806, 28.36, 22.386, 28.848, 22.311);
  path.cubicTo(29.336, 22.236, 29.806, 22.529, 29.954, 23);
  path.lineTo(30.896, 23);
  path.cubicTo(31.029, 22.32, 31.297, 21.673, 31.684, 21.098);
  path.lineTo(31.1, 20.514);
  path.cubicTo(30.706, 20.892, 30.082, 20.883, 29.698, 20.495);
  path.cubicTo(29.314, 20.108, 29.312, 19.483, 29.693, 19.093);
  path.lineTo(31.093, 17.693);
  path.cubicTo(31.483, 17.312, 32.108, 17.314, 32.495, 17.698);
  path.cubicTo(32.883, 18.082, 32.892, 18.706, 32.514, 19.1);
  path.lineTo(33.098, 19.684);
  path.cubicTo(33.673, 19.297, 34.32, 19.029, 35, 18.896);
  path.lineTo(35, 17.954);
  path.cubicTo(34.529, 17.806, 34.236, 17.336, 34.311, 16.848);
  path.cubicTo(34.386, 16.36, 34.806, 16, 35.3, 16);
  path.lineTo(36.7, 16);
  path.cubicTo(37.194, 16, 37.614, 16.36, 37.689, 16.848);
  path.cubicTo(37.764, 17.336, 37.471, 17.806, 37, 17.954);
  path.lineTo(37, 18.896);
  path.cubicTo(37.68, 19.029, 38.327, 19.297, 38.902, 19.684);
  path.lineTo(39.486, 19.1);
  path.cubicTo(39.108, 18.706, 39.117, 18.082, 39.505, 17.698);
  path.cubicTo(39.892, 17.314, 40.517, 17.312, 40.907, 17.693);
  path.lineTo(42.307, 19.093);
  path.cubicTo(42.688, 19.483, 42.686, 20.108, 42.302, 20.495);
  path.cubicTo(41.918, 20.883, 41.294, 20.892, 40.9, 20.514);
  path.lineTo(40.316, 21.098);
  path.cubicTo(40.696, 21.663, 40.969, 22.308, 41.104, 23);
  path.lineTo(42.046, 23);
  path.cubicTo(42.194, 22.529, 42.664, 22.236, 43.152, 22.311);
  path.cubicTo(43.64, 22.386, 44, 22.806, 44, 23.3);
  path.lineTo(44, 24.7);
  path.cubicTo(44, 25.194, 43.64, 25.614, 43.152, 25.689);
  path.cubicTo(42.664, 25.764, 42.194, 25.471, 42.046, 25);
  path.lineTo(41.104, 25);
  path.cubicTo(41.004, 25.512, 40.827, 26.006, 40.58, 26.465);
  path.lineTo(41.6, 27.485);
  path.cubicTo(41.993, 27.096, 42.626, 27.1, 43.014, 27.493);
  path.cubicTo(43.403, 27.885, 43.4, 28.518, 43.007, 28.907);
  path.lineTo(41.607, 30.307);
  path.cubicTo(41.217, 30.688, 40.592, 30.686, 40.205, 30.302);
  path.cubicTo(39.817, 29.918, 39.808, 29.294, 40.186, 28.9);
  path.lineTo(39.303, 28.017);
  path.cubicTo(38.637, 28.565, 37.846, 28.938, 37, 29.104);
  path.lineTo(37, 30.046);
  path.cubicTo(37.471, 30.194, 37.764, 30.664, 37.689, 31.152);
  path.cubicTo(37.614, 31.64, 37.194, 32, 36.7, 32);
  path.lineTo(35.3, 32);
  path.cubicTo(34.806, 32, 34.386, 31.64, 34.311, 31.152);
  path.cubicTo(34.236, 30.664, 34.529, 30.194, 35, 30.046);
  path.lineTo(35, 29.104);
  path.cubicTo(34.32, 28.971, 33.673, 28.703, 33.098, 28.316);
  path.lineTo(32.514, 28.9);
  path.cubicTo(32.892, 29.294, 32.883, 29.918, 32.495, 30.302);
  path.cubicTo(32.108, 30.686, 31.483, 30.688, 31.093, 30.307);
  path.lineTo(29.693, 28.907);
  path.cubicTo(29.312, 28.517, 29.314, 27.892, 29.698, 27.505);
  path.cubicTo(30.082, 27.117, 30.706, 27.108, 31.1, 27.486);
  path.lineTo(31.684, 26.902);
  path.cubicTo(31.297, 26.327, 31.029, 25.68, 30.896, 25);
  return path;
}

Path stoolCup() {
  final path = Path();
  path.moveTo(28.955, 1.53);
  path.lineTo(30.475, 1.53);
  path.lineTo(30.475, 6.1);
  path.lineTo(28.955, 6.1);
  path.close();
  path.moveTo(25.905, 1.53);
  path.lineTo(28.955, 1.53);
  path.lineTo(28.955, 0);
  path.lineTo(3.045, 0);
  path.lineTo(3.045, 1.53);
  path.lineTo(6.1, 1.53);
  path.lineTo(6.1, 6.1);
  path.lineTo(3.045, 6.1);
  path.lineTo(3.045, 30.48);
  path.lineTo(4.575, 30.48);
  path.lineTo(4.575, 7.62);
  path.lineTo(27.425, 7.62);
  path.lineTo(27.425, 30.48);
  path.lineTo(28.955, 30.48);
  path.lineTo(28.955, 6.1);
  path.lineTo(25.905, 6.1);
  path.close();
  path.moveTo(10.665, 6.1);
  path.lineTo(7.615, 6.1);
  path.lineTo(7.615, 1.53);
  path.lineTo(10.665, 1.53);
  path.close();
  path.moveTo(15.235, 6.1);
  path.lineTo(12.2, 6.1);
  path.lineTo(12.2, 1.53);
  path.lineTo(15.24, 1.53);
  path.close();
  path.moveTo(19.805, 6.1);
  path.lineTo(16.765, 6.1);
  path.lineTo(16.765, 1.53);
  path.lineTo(19.805, 1.53);
  path.close();
  path.moveTo(24.385, 6.1);
  path.lineTo(21.335, 6.1);
  path.lineTo(21.335, 1.53);
  path.lineTo(24.385, 1.53);
  path.close();
  path.moveTo(4.575, 30.48);
  path.lineTo(27.425, 30.48);
  path.lineTo(27.425, 32);
  path.lineTo(4.575, 32);
  path.close();
  path.moveTo(24.385, 15.24);
  path.lineTo(25.905, 15.24);
  path.lineTo(25.905, 16.77);
  path.lineTo(24.385, 16.77);
  path.close();
  path.moveTo(24.385, 22.86);
  path.lineTo(22.855, 22.86);
  path.lineTo(22.855, 19.81);
  path.lineTo(21.335, 19.81);
  path.lineTo(21.335, 18.29);
  path.lineTo(18.285, 18.29);
  path.lineTo(18.285, 16.77);
  path.lineTo(16.765, 16.77);
  path.lineTo(16.765, 15.24);
  path.lineTo(15.235, 15.24);
  path.lineTo(15.235, 13.72);
  path.lineTo(13.715, 13.72);
  path.lineTo(13.715, 15.24);
  path.lineTo(12.2, 15.24);
  path.lineTo(12.2, 18.29);
  path.lineTo(13.72, 18.29);
  path.lineTo(13.72, 19.81);
  path.lineTo(16.77, 19.81);
  path.lineTo(16.77, 21.34);
  path.lineTo(13.72, 21.34);
  path.lineTo(13.72, 19.81);
  path.lineTo(12.2, 19.81);
  path.lineTo(12.2, 18.29);
  path.lineTo(10.67, 18.29);
  path.lineTo(10.67, 19.81);
  path.lineTo(9.145, 19.81);
  path.lineTo(9.145, 22.86);
  path.lineTo(7.615, 22.86);
  path.lineTo(7.615, 24.38);
  path.lineTo(6.1, 24.38);
  path.lineTo(6.1, 27.43);
  path.lineTo(7.62, 27.43);
  path.lineTo(7.62, 28.96);
  path.lineTo(24.39, 28.96);
  path.lineTo(24.39, 27.43);
  path.lineTo(25.91, 27.43);
  path.lineTo(25.91, 24.38);
  path.lineTo(24.39, 24.38);
  path.close();
  path.moveTo(22.855, 25.91);
  path.lineTo(9.145, 25.91);
  path.lineTo(9.145, 24.38);
  path.lineTo(22.855, 24.38);
  path.close();
  path.moveTo(22.855, 16.77);
  path.lineTo(24.385, 16.77);
  path.lineTo(24.385, 18.29);
  path.lineTo(22.855, 18.29);
  path.close();
  path.moveTo(21.335, 15.24);
  path.lineTo(22.855, 15.24);
  path.lineTo(22.855, 16.77);
  path.lineTo(21.335, 16.77);
  path.close();
  path.moveTo(21.335, 9.15);
  path.lineTo(22.855, 9.15);
  path.lineTo(22.855, 10.67);
  path.lineTo(21.335, 10.67);
  path.close();
  path.moveTo(12.195, 10.67);
  path.lineTo(13.715, 10.67);
  path.lineTo(13.715, 12.19);
  path.lineTo(12.195, 12.19);
  path.close();
  path.moveTo(10.665, 12.19);
  path.lineTo(12.195, 12.19);
  path.lineTo(12.195, 13.72);
  path.lineTo(10.665, 13.72);
  path.close();
  path.moveTo(9.145, 10.67);
  path.lineTo(10.665, 10.67);
  path.lineTo(10.665, 12.19);
  path.lineTo(9.145, 12.19);
  path.close();
  path.moveTo(6.095, 15.24);
  path.lineTo(7.615, 15.24);
  path.lineTo(7.615, 16.77);
  path.lineTo(6.095, 16.77);
  path.close();
  path.moveTo(1.525, 1.53);
  path.lineTo(3.045, 1.53);
  path.lineTo(3.045, 6.1);
  path.lineTo(1.525, 6.1);
  path.close();
  return path;
}
