// ./lib/widgets/animated_image.dart

import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AnimatedImage extends StatefulWidget {
  final String imageOneUrl;
  final String imageTwoUrl;
  final double width;
  final double height;

  const AnimatedImage({
    Key? key,
    required this.imageOneUrl,
    required this.imageTwoUrl,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  _AnimatedImageState createState() => _AnimatedImageState();
}

class _AnimatedImageState extends State<AnimatedImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool showFirstImage = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            showFirstImage = !showFirstImage;
          });
          _controller.forward(from: 0);
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      showFirstImage ? widget.imageOneUrl : widget.imageTwoUrl,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.image_not_supported,
            color: AppColors.whiteText);
      },
    );
  }
}
