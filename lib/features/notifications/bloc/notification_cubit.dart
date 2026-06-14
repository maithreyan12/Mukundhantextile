import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationState extends Equatable {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [isLoading, notifications, unreadCount];
}

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repo;

  NotificationCubit({NotificationRepository? notificationRepository})
      : _repo = notificationRepository ?? NotificationRepository(),
        super(const NotificationState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true));
    try {
      final results = await Future.wait([
        _repo.getNotifications(),
        _repo.getUnreadCount(),
      ]);
      emit(state.copyWith(
        isLoading: false,
        notifications: results[0] as List<NotificationModel>,
        unreadCount: results[1] as int,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    await loadNotifications();
  }
}
