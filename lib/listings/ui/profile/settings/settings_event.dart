part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class SettingsChangedEvent extends SettingsEvent {}

class SaveSettingsEvent extends SettingsEvent {
  ListingsUser currentUser;

  SaveSettingsEvent({required this.currentUser});
}
