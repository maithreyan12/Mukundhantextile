import 'package:equatable/equatable.dart';
import '../../../data/models/user_profile.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile profile;

  const AuthAuthenticated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AuthUnauthenticated extends AuthState {}

/// Email confirmation required — user signed up but must verify email first
class AuthEmailConfirmationRequired extends AuthState {
  final String email;

  const AuthEmailConfirmationRequired(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}
