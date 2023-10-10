part of 'settings_bloc.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsChangedState extends SettingsState {}

class SettingsSavedState extends SettingsState {}
