import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../events/providers/events_provider.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? eventData;

  const EventFormScreen({super.key, this.eventData});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _bannerUrlController;
  late final TextEditingController _thumbnailUrlController;
  late DateTime _eventDate;
  late bool _isFeatured;
  late bool _isActive;
  bool _isLoading = false;
  bool get _isEditing => widget.eventData != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventData?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.eventData?['description'] ?? '');
    _bannerUrlController = TextEditingController(text: widget.eventData?['banner_url'] ?? '');
    _thumbnailUrlController = TextEditingController(text: widget.eventData?['thumbnail_url'] ?? '');
    _eventDate = widget.eventData?['event_date'] != null
        ? DateTime.parse(widget.eventData!['event_date'])
        : DateTime.now();
    _isFeatured = widget.eventData?['is_featured'] ?? false;
    _isActive = widget.eventData?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bannerUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_date': _eventDate.toIso8601String().split('T').first,
        'banner_url': _bannerUrlController.text.trim(),
        'thumbnail_url': _thumbnailUrlController.text.trim(),
        'is_featured': _isFeatured,
        'is_active': _isActive,
      };

      if (_isEditing) {
        await ref.read(eventsRepositoryProvider).updateEvent(widget.eventData!['id'], data);
      } else {
        await ref.read(eventsRepositoryProvider).createEvent(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event ${_isEditing ? "updated" : "created"}!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Event Date',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bannerUrlController,
                decoration: const InputDecoration(labelText: 'Banner Image URL'),
                validator: (v) => UrlValidator.validateOptionalUrl(v, fieldName: 'Banner URL'),
                onChanged: (_) => setState(() {}),
              ),
              if (UrlValidator.isValidUrl(_bannerUrlController.text)) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(imageUrl: _bannerUrlController.text.trim(), height: 120, width: double.infinity),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                validator: (v) => UrlValidator.validateOptionalUrl(v, fieldName: 'Thumbnail URL'),
                onChanged: (_) => setState(() {}),
              ),
              if (UrlValidator.isValidUrl(_thumbnailUrlController.text)) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(imageUrl: _thumbnailUrlController.text.trim(), height: 80, width: 80),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Featured Event'),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                contentPadding: EdgeInsets.zero,
              ),
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
                      : Text(_isEditing ? 'UPDATE EVENT' : 'CREATE EVENT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
