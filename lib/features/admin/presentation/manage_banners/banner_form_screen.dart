import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../home/providers/home_provider.dart';

class BannerFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? bannerData;

  const BannerFormScreen({super.key, this.bannerData});

  @override
  ConsumerState<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends ConsumerState<BannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _actionUrlController;
  late final TextEditingController _orderController;
  late bool _isActive;
  bool _isLoading = false;
  bool get _isEditing => widget.bannerData != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bannerData?['title'] ?? '');
    _subtitleController = TextEditingController(text: widget.bannerData?['subtitle'] ?? '');
    _imageUrlController = TextEditingController(text: widget.bannerData?['image_url'] ?? '');
    _actionUrlController = TextEditingController(text: widget.bannerData?['action_url'] ?? '');
    _orderController = TextEditingController(text: '${widget.bannerData?['display_order'] ?? 0}');
    _isActive = widget.bannerData?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'action_url': _actionUrlController.text.trim(),
        'display_order': int.tryParse(_orderController.text) ?? 0,
        'is_active': _isActive,
      };

      if (_isEditing) {
        await ref.read(bannerRepositoryProvider).updateBanner(widget.bannerData!['id'], data);
      } else {
        await ref.read(bannerRepositoryProvider).createBanner(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner ${_isEditing ? "updated" : "created"}!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Banner' : 'Add Banner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Banner Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                ),
                validator: (v) => UrlValidator.validateUrl(v, fieldName: 'Image URL'),
                onChanged: (_) => setState(() {}),
              ),
              // Image Preview
              if (UrlValidator.isValidUrl(_imageUrlController.text)) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedImage(
                    imageUrl: _imageUrlController.text.trim(),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _actionUrlController,
                decoration: const InputDecoration(
                  labelText: 'Action URL (optional)',
                  hintText: 'https://example.com',
                ),
                validator: (v) => UrlValidator.validateOptionalUrl(v, fieldName: 'Action URL'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display Order'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'UPDATE BANNER' : 'ADD BANNER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
