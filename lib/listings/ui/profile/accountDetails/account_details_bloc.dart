import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/firebase/profile_firebase.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'account_details_event.dart';

part 'account_details_state.dart';

class AccountDetailsBloc
    extends Bloc<AccountDetailsEvent, AccountDetailsState> {
  final ProfileRepository profileRepository;
  ListingsUser currentUser;

  AccountDetailsBloc(
      {required this.profileRepository, required this.currentUser})
      : super(AccountDetailsInitial()) {
    on<ValidateFieldsEvent>((event, emit) async {
      if (event.key.currentState?.validate() ?? false) {
        event.key.currentState!.save();
        emit(ValidFieldsState());
      } else {
        emit(AccountFieldsRequiredState());
      }
    });
    on<TryToSubmitDataEvent>((event, emit) async {
      if (profileRepository is ProfileFirebaseUtils) {
        AuthProviders? authProvider =
            await (profileRepository as ProfileFirebaseUtils)
                .getUserAuthProvider();
        if (authProvider == AuthProviders.phone &&
            currentUser.phoneNumber != event.phoneNumber) {
          emit(ReauthRequiredState(
            authProvider: authProvider!,
            data: event.phoneNumber,
          ));
        } else if (authProvider == AuthProviders.password &&
            currentUser.email != event.emailAddress) {
          emit(ReauthRequiredState(
            authProvider: authProvider!,
            data: event.emailAddress,
          ));
        } else {
          emit(UpdatingDataState());
          add(UpdateUserDataEvent(
            firstName: event.firstName,
            lastName: event.lastName,
            emailAddress: event.emailAddress,
            phoneNumber: event.phoneNumber,
          ));
        }
      } else {
        emit(UpdatingDataState());
        add(UpdateUserDataEvent(
          firstName: event.firstName,
          lastName: event.lastName,
          emailAddress: event.emailAddress,
          phoneNumber: event.phoneNumber,
        ));
      }
    });
    on<UpdateUserDataEvent>((event, emit) async {
      currentUser.firstName = event.firstName;
      currentUser.lastName = event.lastName;
      currentUser.email = event.emailAddress;
      currentUser.phoneNumber = event.phoneNumber;
      await profileRepository.updateCurrentUser(currentUser);
      emit(UserDataUpdatedState(updatedUser: currentUser));
    });
  }
}
