import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Campo para la URL de la foto de la cafetería, con vista previa en vivo.
class PhotoUrlField extends StatefulWidget {
  const PhotoUrlField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<PhotoUrlField> createState() => _PhotoUrlFieldState();
}

class _PhotoUrlFieldState extends State<PhotoUrlField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  bool get _looksValid {
    final t = widget.controller.text.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: 'URL de foto (opcional)',
            prefixIcon: Icon(Icons.image_outlined, size: 20),
          ),
        ),
        if (_looksValid) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(
                widget.controller.text.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _error(),
                loadingBuilder: (ctx, child, progress) =>
                    progress == null ? child : _loading(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _loading() => Container(
        color: AppColors.paper,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _error() => Container(
        color: AppColors.paper,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.faint),
            SizedBox(height: 4),
            Text(
              'No se pudo cargar la imagen',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
}
