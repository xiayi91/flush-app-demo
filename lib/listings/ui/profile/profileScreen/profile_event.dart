part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class RetrieveLostDataEvent extends ProfileEvent {}

class ChooseImageFromGalleryEvent extends ProfileEvent {}

class CaptureImageByCameraEvent extends ProfileEvent {}

class UpdateUserImageEvent extends ProfileEvent {
  File imageFile;

  UpdateUserImageEvent(this.imageFile);
}

class DeleteUserImageEvent extends ProfileEvent {}

class InvalidateUserObjectEvent extends ProfileEvent {
  ListingsUser newUser;

  InvalidateUserObjectEvent({required this.newUser});
}

class TryToDeleteUserEvent extends ProfileEvent {}

class DeleteUserConfirmedEvent extends ProfileEvent {}
