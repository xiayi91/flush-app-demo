// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';

part 'phone_number_input_event.dart';

part 'phone_number_input_state.dart';

class PhoneNumberInputBloc
    extends Bloc<PhoneNumberInputEvent, PhoneNumberInputState> {
  final AuthenticationRepository authenticationRepository;

  PhoneNumberInputBloc({required this.authenticationRepository})
      : super(PhoneNumberInputInitial()) {
    ImagePicker imagePicker = ImagePicker();

    on<RetrieveLostDataEvent>(
      (event, emit) async {
        final LostDataResponse response = await imagePicker.retrieveLostData();
        if (response.file != null) {
          emit(PictureSelectedState(imageFile: File(response.file!.path)));
        }
      },
    );

    on<ChooseImageFromGalleryEvent>(
      (event, emit) async {
        XFile? xImage =
            await imagePicker.pickImage(source: ImageSource.gallery);
        if (xImage != null) {
          emit(PictureSelectedState(imageFile: File(xImage.path)));
        }
      },
    );

    on<CaptureImageByCameraEvent>(
      (event, emit) async {
        XFile? xImage = await imagePicker.pickImage(source: ImageSource.camera);
        if (xImage != null) {
          emit(PictureSelectedState(imageFile: File(xImage.path)));
        }
      },
    );

    on<ValidateFieldsEvent>(
      (event, emit) async {
        if (event.key.currentState?.validate() ?? false) {
          if (event.acceptEula || event.isLogin) {
            if (event.isPhoneValid) {
              event.key.currentState!.save();
              emit(ValidFieldsState());
            } else {
              emit(PhoneInputFailureState(
                  errorMessage:
                      'Invalid phone number, Please try again with a valid phone number.'
                          .tr()));
            }
          } else {
            emit(PhoneInputFailureState(
                errorMessage: 'Please accept our terms of use.'.tr()));
          }
        } else {
          emit(PhoneInputFailureState(
              errorMessage: 'Please fill required fields.'.tr()));
        }
      },
    );

    on<ToggleEulaCheckboxEvent>(
        (event, emit) => emit(EulaToggleState(event.eulaAccepted)));

    on<VerifyPhoneNumberEvent>((event, emit) async {
      await authenticationRepository.verifyPhoneNumber(
          phoneNumber: event.phoneNumber,
          phoneCodeAutoRetrievalTimeout: onPhoneCodeAutoRetrievalTimeout,
          phoneCodeSent: onPhoneCodeSent,
          phoneVerificationFailed: onPhoneVerificationFailed,
          phoneVerificationCompleted: onPhoneVerificationCompleted);
    });
  }

  void onPhoneVerificationCompleted(
      auth.PhoneAuthCredential phoneAuthCredential) {
    emit(AutoPhoneVerificationCompletedState(credential: phoneAuthCredential));
  }

  void onPhoneVerificationFailed(auth.FirebaseAuthException error) {
    String message = 'An error has occurred, please try again.'.tr();
    switch (error.code) {
      case 'invalid-verification-code':
        message = 'Invalid code or has been expired.'.tr();
        break;
      case 'user-disabled':
        message = 'This user has been disabled.'.tr();
        break;
      default:
        message = 'An error has occurred, please try again.'.tr();
        break;
    }
    debugPrint(
        'PhoneNumberInputBloc.onPhoneVerificationFailed ${error.code} ${error.message}');
    emit(PhoneInputFailureState(errorMessage: message));
  }

  void onPhoneCodeSent(String verificationId, int? forceResendingToken) {
    emit(CodeSentState(verificationID: verificationId));
  }

  void onPhoneCodeAutoRetrievalTimeout(String verificationId) {}
}
