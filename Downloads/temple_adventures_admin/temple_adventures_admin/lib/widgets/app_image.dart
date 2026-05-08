import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:octo_image/octo_image.dart';

class AppImage extends StatelessWidget {
  const AppImage(
    this.image, {
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.semanticsLabel,
    this.color,
    this.fit = BoxFit.contain,
  });

  final String image;
  final double? height;
  final double? width;
  final String? semanticsLabel;
  final Color? color;
  final BoxFit fit;
  final double? borderRadius;

  bool get isNetworkImage => image.startsWith('http');
  bool get isSvg => image.toLowerCase().endsWith('.svg');
  bool get isLocalFile => File(image).existsSync();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 0),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // Network SVG
    if (isNetworkImage && isSvg) {
      return SvgPicture.network(
        image,
        height: height,
        width: width,
        color: color,
        fit: fit,
        semanticsLabel: semanticsLabel,
      );
    }

    // Local SVG
    if (!isNetworkImage && isSvg) {
      return SvgPicture.asset(
        image,
        height: height,
        width: width,
        color: color,
        fit: fit,
        semanticsLabel: semanticsLabel,
      );
    }

    // Network Image (jpg/png/webp)
    if (isNetworkImage) {
      return OctoImage(
        image: CachedNetworkImageProvider(image),
        progressIndicatorBuilder: (context, progress) => const Center(child: CircularProgressIndicator()),
        errorBuilder: OctoError.icon(color: Colors.red),
        fit: fit,
        height: height,
        width: width,
      );
    }

    // Local file (picked from gallery/camera)
    if (isLocalFile) {
      return Image.file(
        File(image),
        height: height,
        width: width,
        color: color,
        fit: fit,
      );
    }

    // Asset image
    if (image.startsWith('asset') || image.startsWith('assets')) {
      return Image.asset(
        image,
        height: height,
        width: width,
        color: color,
        fit: fit,
      );
    }

    // Fallback (empty / invalid)
    return Container(
      height: height,
      width: width,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
