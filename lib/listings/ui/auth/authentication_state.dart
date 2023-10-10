part of 'authentication_bloc.dart';

enum AuthState { firstRun, authenticated, unauthenticated }

class AuthenticationState {
  final AuthState authState;
  final ListingsUser? user;
  final String? message;

  AuthenticationState._(this.authState, {this.user, this.message});

  AuthenticationState.authenticated(ListingsUser user)
      : this._(AuthState.authenticated, user: user);

  AuthenticationState.unauthenticated({String? message})
      : this._(AuthState.unauthenticated,
            message: message ?? 'Unauthenticated');

  AuthenticationState.onboarding() : this._(AuthState.firstRun);
}
