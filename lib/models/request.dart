import 'dart:typed_data';

import 'package:flutter/material.dart';

enum RequestStatus {
  newRequest,
  inProgress,
  completed,
  cancelled,
}

extension RequestStatusExtension on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.newRequest:
        return 'Новая';
      case RequestStatus.inProgress:
        return 'В работе';
      case RequestStatus.completed:
        return 'Выполнена';
      case RequestStatus.cancelled:
        return 'Отменена';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.newRequest:
        return Colors.blue;
      case RequestStatus.inProgress:
        return Colors.orange;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.newRequest:
        return Icons.fiber_new;
      case RequestStatus.inProgress:
        return Icons.hourglass_empty;
      case RequestStatus.completed:
        return Icons.check_circle;
      case RequestStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class Request {
  final String id;
  final String title;
  final String description;
  final RequestStatus status;
  final String? statusId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? priority;
  final String? roomNumber;
  final String? roomId;
  final String? requestorUserId;
  final String? requestorName;
  final String? responsibleUserId;
  final String? responsibleName;
  final int? rating;
  final String? requestType;
  final String? requestTypeId;
  final List<Uint8List> photoBytes;

  const Request({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.statusId,
    required this.createdAt,
    this.updatedAt,
    this.priority,
    this.roomNumber,
    this.roomId,
    this.requestorUserId,
    this.requestorName,
    this.responsibleUserId,
    this.responsibleName,
    this.rating,
    this.requestType,
    this.requestTypeId,
    this.photoBytes = const [],
  });

  Request copyWith({
    String? id,
    String? title,
    String? description,
    RequestStatus? status,
    String? statusId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? priority,
    String? roomNumber,
    String? roomId,
    String? requestorUserId,
    String? requestorName,
    String? responsibleUserId,
    String? responsibleName,
    int? rating,
    String? requestType,
    String? requestTypeId,
    List<Uint8List>? photoBytes,
  }) {
    return Request(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      statusId: statusId ?? this.statusId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      roomNumber: roomNumber ?? this.roomNumber,
      roomId: roomId ?? this.roomId,
      requestorUserId: requestorUserId ?? this.requestorUserId,
      requestorName: requestorName ?? this.requestorName,
      responsibleUserId: responsibleUserId ?? this.responsibleUserId,
      responsibleName: responsibleName ?? this.responsibleName,
      rating: rating ?? this.rating,
      requestType: requestType ?? this.requestType,
      requestTypeId: requestTypeId ?? this.requestTypeId,
      photoBytes: photoBytes ?? this.photoBytes,
    );
  }
}
