part of 'profile_bloc.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class UpdatedUserState extends ProfileState {
  ListingsUser updatedUser;

  UpdatedUserState({required this.updatedUser});
}

class UploadingImageState extends ProfileState {}

class DeleteUserConfirmationState extends ProfileState {}

class UserDeletedState extends ProfileState {}

class ReauthRequiredState extends ProfileState {
  AuthProviders authProvider;

  ReauthRequiredState({required this.authProvider});
}
