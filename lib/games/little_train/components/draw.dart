import 'dart:ui';

/// Draws a whole generated picture into [dst].
///
/// The pictures are generated at ~512px and drawn at a few hundred, so they
/// are always being scaled — medium filtering keeps the thick outlines smooth
/// rather than jagged.
void drawPicture(
  Canvas canvas,
  Image image,
  Rect dst, {
  bool flip = false,
  double opacity = 1,
  double rotation = 0,
}) {
  final paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0, 1));
  final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  if (!flip && rotation == 0) {
    canvas.drawImageRect(image, src, dst, paint);
    return;
  }
  canvas.save();
  // Rotate about the bottom-middle, where a standing thing touches the ground.
  canvas.translate(dst.center.dx, dst.bottom);
  if (rotation != 0) canvas.rotate(rotation);
  if (flip) canvas.scale(-1, 1);
  canvas.drawImageRect(
    image,
    src,
    Rect.fromLTWH(-dst.width / 2, -dst.height, dst.width, dst.height),
    paint,
  );
  canvas.restore();
}

/// The rect a picture fills when drawn [height] tall, standing on
/// ([centerX], [bottom]) and keeping its own proportions.
Rect standing(Image image, double centerX, double bottom, double height) {
  final width = height * image.width / image.height;
  return Rect.fromLTWH(centerX - width / 2, bottom - height, width, height);
}
