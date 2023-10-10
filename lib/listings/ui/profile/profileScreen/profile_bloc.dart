import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/firebase/profile_firebase.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProfileRepository profileRepository;
  ListingsUser currentUser;

  ProfileBloc({required this.currentUser, required this.profileRepository})
      : super(ProfileInitial()) {
    on<RetrieveLostDataEvent>((event, emit) async {
      final LostDataResponse response = await _imagePicker.retrieveLostData();
      if (response.file != null) {
        add(UpdateUserImageEvent(File(response.file!.path)));
      }
    });

    on<ChooseImageFromGalleryEvent>((event, emit) async {
      XFile? xImage = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xImage != null) {
        add(UpdateUserImageEvent(File(xImage.path)));
      }
    });

    on<CaptureImageByCameraEvent>((event, emit) async {
      XFile? xImage = await _imagePicker.pickImage(source: ImageSource.camera);
      if (xImage != null) {
        add(UpdateUserImageEvent(File(xImage.path)));
      }
    });

    on<UpdateUserImageEvent>((event, emit) async {
      emit(UploadingImageState());
      currentUser.profilePictureURL =
          await profileRepository.uploadUserImageToServer(
              image: event.imageFile, userID: currentUser.userID);
      await profileRepository.updateCurrentUser(currentUser);
      emit(UpdatedUserState(updatedUser: currentUser));
    });

    on<DeleteUserImageEvent>((event, emit) async {
      await profileRepository
          .deleteImageFromStorage(currentUser.profilePictureURL);
      currentUser.profilePictureURL = '';
      await profileRepository.updateCurrentUser(currentUser);
      emit(UpdatedUserState(updatedUser: currentUser));
    });
    on<InvalidateUserObjectEvent>((event, emit) {
      currentUser = event.newUser;
      emit(UpdatedUserState(updatedUser: event.newUser));
    });

    on<TryToDeleteUserEvent>((event, emit) async {
      if (profileRepository is ProfileFirebaseUtils) {
        AuthProviders? authProvider =
            await (profileRepository as ProfileFirebaseUtils)
                .getUserAuthProvider();
        emit(ReauthRequiredState(authProvider: authProvider!));
      } else {
        emit(DeleteUserConfirmationState());
      }
    });
    on<DeleteUserConfirmedEvent>((event, emit) async {
      await profileRepository.deleteUser(user: currentUser);
      emit(UserDeletedState());
    });
  }
}
