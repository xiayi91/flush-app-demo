part of 'account_details_bloc.dart';

abstract class AccountDetailsState {}

class AccountDetailsInitial extends AccountDetailsState {}

class AccountFieldsRequiredState extends AccountDetailsState {}

class ValidFieldsState extends AccountDetailsState {}

class UpdatingDataState extends AccountDetailsState {}

class UserDataUpdatedState extends AccountDetailsState {
  ListingsUser updatedUser;

  UserDataUpdatedState({required this.updatedUser});
}

class ReauthRequiredState extends AccountDetailsState {
  AuthProviders authProvider;
  String data;

  ReauthRequiredState({required this.authProvider, required this.data});
}
