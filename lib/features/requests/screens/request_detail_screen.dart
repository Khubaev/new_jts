import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/request.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/requests_provider.dart';
import 'edit_request_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {

  bool _canEditData(AppUser? user, Request request) {
    if (user == null) return false;
    if (user.role.canSeeAllRequests) return true;
    return request.requestorUserId == user.id;
  }

  bool _canChangeStatus(AppUser? user, Request request) {
    if (user == null) return false;
    if (user.role.canSeeAllRequests) return true;
    return request.requestorUserId == user.id ||
        request.responsibleUserId == user.id;
  }

  bool _canDelete(AppUser? user, Request request) {
    if (user == null) return false;
    if (user.role.canSeeAllRequests) return true;
    return request.requestorUserId == user.id;
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestsProvider>().fetchRequest(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявка'),
        actions: [
          Consumer<RequestsProvider>(
            builder: (context, provider, _) {
              final request = provider.getById(widget.requestId);
              final user = context.watch<AuthProvider>().currentUser;
              if (request == null || user == null) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canChangeStatus(user, request))
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (statusId) {
                        provider.updateStatus(widget.requestId, statusId);
                      },
                      itemBuilder: (context) => provider.statuses
                          .map((s) => PopupMenuItem(
                                value: s['id'] as String,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: _colorFromHex(s['color'] as String?),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(s['name'] as String),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  if (_canEditData(user, request))
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditRequestScreen(requestId: widget.requestId),
                        ),
                      ),
                      tooltip: 'Редактировать',
                    ),
                  if (_canDelete(user, request))
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showDeleteDialog(context),
                      tooltip: 'Удалить',
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<RequestsProvider>(
        builder: (context, provider, _) {
          final request = provider.getById(widget.requestId);

          if (request == null) {
            return const Center(child: Text('Заявка не найдена'));
          }

          final auth = context.read<AuthProvider>();
          final requestor = auth.getUserById(request.requestorUserId ?? '');
          final responsible = auth.getUserById(request.responsibleUserId ?? '');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusChip(context, request.status),
                const SizedBox(height: 20),
                Text(
                  request.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        if (request.priority != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildInfoField(
                              context,
                              'Приоритет',
                              request.priority!,
                              Icons.flag,
                            ),
                          ),
                        if (request.roomNumber != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildInfoField(
                              context,
                              'Номер комнаты',
                              request.roomNumber!,
                              Icons.door_front_door,
                            ),
                          ),
                        if (request.requestType != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildInfoField(
                              context,
                              'Тип заявки',
                              request.requestType!,
                              Icons.category,
                            ),
                          ),
                        if (requestor != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildInfoField(
                              context,
                              'Постановщик',
                              requestor.name,
                              Icons.person_add,
                            ),
                          ),
                        if (responsible != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildInfoField(
                              context,
                              'Ответственный',
                              responsible.name,
                              Icons.person,
                            ),
                          ),
                        if (request.status == RequestStatus.completed && request.rating != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildRatingField(context, request.rating!),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Описание',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _buildInfoField(
                            context,
                            'Дата создания',
                            _formatDate(request.createdAt),
                            Icons.calendar_today,
                          ),
                        ),
                        if (request.updatedAt != null)
                          SizedBox(
                            width: itemWidth,
                            child: _buildInfoField(
                              context,
                              'Дата обновления',
                              _formatDate(request.updatedAt!),
                              Icons.update,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (request.photoBytes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Фотографии',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: request.photoBytes.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final bytes = request.photoBytes[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GestureDetector(
                            onTap: () => _showFullImage(context, bytes),
                            child: Image.memory(
                              bytes,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (request.status == RequestStatus.completed &&
                    request.rating == null &&
                    (context.read<AuthProvider>().currentUser?.role ?? UserRole.user).canSeeAllRequests) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Оценить заявку',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        onPressed: () {
                          provider.updateRating(widget.requestId, star);
                        },
                        icon: Icon(
                          (request.rating ?? 0) >= star
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, RequestStatus status) {
    return Chip(
      avatar: Icon(status.icon, color: Colors.white, size: 18),
      label: Text(
        status.label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: status.color,
    );
  }

  Widget _buildRatingField(BuildContext context, int rating) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Оценка заявки',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 28,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заявку?'),
        content: const Text(
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              context.read<RequestsProvider>().deleteRequest(widget.requestId);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
