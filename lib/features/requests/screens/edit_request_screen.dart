import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/requests_provider.dart';
import '../../../services/api_service.dart';
class EditRequestScreen extends StatefulWidget {
  final String requestId;

  const EditRequestScreen({super.key, required this.requestId});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPriority;
  String? _selectedResponsible;
  String? _selectedRoomId;
  String? _selectedTypeId;
  final List<Uint8List> _photoBytes = [];
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _types = [];
  bool _loading = true;
  String? _error;

  static const _priorities = ['Низкий', 'Средний', 'Высокий', 'Критический'];
  static const _titleMaxLength = 200;
  static const _descriptionMaxLength = 5000;
  static const _maxPhotos = 10;
  static const _maxPhotoSizeBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<RequestsProvider>();
    var request = provider.getById(widget.requestId);
    if (request == null) {
      request = await provider.fetchRequest(widget.requestId);
    }
    try {
      final rooms = await provider.getRooms();
      final types = await provider.getRequestTypes();
      if (mounted && request != null) {
        _titleController.text = request.title;
        _descriptionController.text = request.description;
        _selectedPriority = request.priority;
        _selectedResponsible = request.responsibleUserId;
        _selectedRoomId = request.roomId;
        _selectedTypeId = request.requestTypeId;
        _photoBytes.addAll(request.photoBytes);
        setState(() {
          _rooms = rooms;
          _types = types;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_photoBytes.length >= _maxPhotos) return;
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final bytesList = <Uint8List>[];
      for (final x in images) {
        if (bytesList.length + _photoBytes.length >= _maxPhotos) break;
        try {
          final bytes = await x.readAsBytes();
          if (bytes.isNotEmpty && bytes.length <= _maxPhotoSizeBytes) bytesList.add(bytes);
        } catch (_) {}
      }
      if (bytesList.isNotEmpty) setState(() => _photoBytes.addAll(bytesList));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photoBytes.removeAt(index));
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final request = context.read<RequestsProvider>().getById(widget.requestId);
      if (request == null) return;

      setState(() => _error = null);
      try {
        final updated = request.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          roomId: _selectedRoomId,
          responsibleUserId: _selectedResponsible,
          requestTypeId: _selectedTypeId,
          photoBytes: _photoBytes,
        );
        await context.read<RequestsProvider>().updateRequest(widget.requestId, updated);
        if (mounted) Navigator.of(context).pop();
      } on ApiException catch (e) {
        if (mounted) setState(() => _error = e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = auth.usersForResponsible;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактировать заявку')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать заявку'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Заголовок',
                hintText: 'Краткое описание проблемы',
                prefixIcon: Icon(Icons.title),
                counterText: '',
              ),
              maxLength: _titleMaxLength,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите заголовок';
                if (v.length > _titleMaxLength) return 'Не более $_titleMaxLength символов';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Подробное описание заявки',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
                counterText: '',
              ),
              maxLines: 5,
              maxLength: _descriptionMaxLength,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите описание';
                if (v.length > _descriptionMaxLength) return 'Не более $_descriptionMaxLength символов';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRoomId,
              decoration: const InputDecoration(
                labelText: 'Номер комнаты',
                prefixIcon: Icon(Icons.door_front_door),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Выберите —')),
                ..._rooms.map((r) => DropdownMenuItem(
                      value: r['id'] as String,
                      child: Text('${r['number']}${(r['description'] as String?)?.isNotEmpty == true ? ' (${r['description']})' : ''}'),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedRoomId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedResponsible,
              decoration: const InputDecoration(
                labelText: 'Ответственный',
                prefixIcon: Icon(Icons.person_pin),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Выберите —')),
                ...users.map((u) => DropdownMenuItem(
                      value: u.id,
                      child: Text('${u.name} (${u.login})'),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedResponsible = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              decoration: const InputDecoration(
                labelText: 'Тип заявки',
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Выберите —')),
                ..._types.map((t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text(t['name'] as String),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedTypeId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Приоритет',
                prefixIcon: Icon(Icons.flag),
              ),
              items: _priorities
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPriority = v),
            ),
            const SizedBox(height: 20),
            Text(
              'Фотографии',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._photoBytes.asMap().entries.map((e) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          e.value,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(e.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 32,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
