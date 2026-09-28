import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class RemoteImageTile extends StatelessWidget {
  final String? url;
  final String label;
  final double height;

  const RemoteImageTile({super.key, required this.url, required this.label, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null || url!.isEmpty)
              Container(
                color: AppColors.background,
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 32),
              )
            else
              Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 32),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: AppColors.background, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2));
                },
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
                child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
