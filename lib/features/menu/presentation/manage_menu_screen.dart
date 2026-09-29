import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../application/cafe_menu_controller.dart';
import '../domain/product.dart';

/// Panel de la cafetería para administrar su menú: agregar, editar,
/// activar/desactivar y eliminar productos.
class ManageMenuScreen extends ConsumerWidget {
  const ManageMenuScreen({super.key});

  static const _order = ['Café', 'Pizza', 'Postre'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(cafeMenuProvider);
    final categories = <String>[
      ..._order.where((c) => products.any((p) => p.category == c)),
      ...products
          .map((p) => p.category)
          .where((c) => !_order.contains(c))
          .toSet(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Menú de la cafetería')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: products.isEmpty
          ? const _EmptyMenu()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                96,
              ),
              children: [
                for (final category in categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.md,
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  for (final product
                      in products.where((p) => p.category == category)) ...[
                    _ProductRow(
                      product: product,
                      onEdit: () => _openForm(context, ref, product),
                      onToggle: () => ref
                          .read(cafeMenuProvider.notifier)
                          .toggleAvailable(product.id),
                      onDelete: () => _confirmDelete(context, ref, product),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, Product? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductForm(
        existing: existing,
        onSave: (product) {
          final notifier = ref.read(cafeMenuProvider.notifier);
          if (existing == null) {
            notifier.add(product);
          } else {
            notifier.update(product);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Quitar "${product.name}" del menú?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(cafeMenuProvider.notifier).remove(product.id);
    }
  }
}

// ─── Product row ────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final off = !product.available;
    return Opacity(
      opacity: off ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _Thumb(product: product),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatMxn(product.priceCents),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: product.available,
                  activeTrackColor: AppColors.success,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.faint, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.product});
  final Product product;

  IconData get _icon => switch (product.category) {
        'Pizza' => Icons.local_pizza_outlined,
        'Postre' => Icons.icecream_outlined,
        _ => Icons.local_cafe_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url != null && url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.paper,
        alignment: Alignment.center,
        child: Icon(_icon, size: 22, color: AppColors.faint),
      );
}

// ─── Add / edit form ────────────────────────────────────────────────────────

class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.existing, required this.onSave});
  final Product? existing;
  final ValueChanged<Product> onSave;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  static const _categories = ['Café', 'Pizza', 'Postre'];

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _image;
  late String _category;
  late bool _available;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p != null ? (p.priceCents / 100).toStringAsFixed(0) : '',
    );
    _image = TextEditingController(text: p?.imageUrl ?? '');
    _category = p != null && _categories.contains(p.category)
        ? p.category
        : _categories.first;
    _available = p?.available ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _image.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final pesos = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (name.isEmpty) {
      setState(() => _error = 'Escribe el nombre del producto.');
      return;
    }
    if (pesos == null || pesos < 0) {
      setState(() => _error = 'Escribe un precio válido.');
      return;
    }
    final existing = widget.existing;
    final image = _image.text.trim();
    final product = Product(
      id: existing?.id ??
          'p_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: _desc.text.trim(),
      priceCents: (pesos * 100).round(),
      category: _category,
      imageUrl: image.isEmpty ? null : image,
      eligibleForDailyPerk: existing?.eligibleForDailyPerk ?? false,
      available: _available,
    );
    widget.onSave(product);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isEdit ? 'Editar producto' : 'Nuevo producto',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _field('Nombre', _name, hint: 'Ej. Cappuccino'),
              const SizedBox(height: AppSpacing.md),
              _field('Descripción', _desc,
                  hint: 'Ej. Espresso con leche espumada', maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      'Precio (MXN)',
                      _price,
                      hint: '0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _categoryField()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _field('Imagen (URL, opcional)', _image,
                  hint: 'https://…', keyboardType: TextInputType.url),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Disponible',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Switch(
                      value: _available,
                      activeTrackColor: AppColors.success,
                      onChanged: (v) => setState(() => _available = v),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: const TextStyle(color: Color(0xFFC0392B))),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppRadius.buttonHeight,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Guardar cambios' : 'Agregar al menú'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORÍA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 40, color: AppColors.muted),
            SizedBox(height: AppSpacing.lg),
            Text('Tu menú está vacío',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: AppSpacing.xs),
            Text('Agrega tu primer producto con el botón "Agregar".',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
