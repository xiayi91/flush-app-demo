import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ProfileRepository profileRepository;

  SettingsBloc({required this.profileRepository}) : super(SettingsInitial()) {
    on<SettingsChangedEvent>((event, emit) {
      emit(SettingsChangedState());
    });
    on<SaveSettingsEvent>((event, emit) async {
      await profileRepository.updateCurrentUser(event.currentUser);
      emit(SettingsSavedState());
    });
  }
}
