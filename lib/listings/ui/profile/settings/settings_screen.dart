import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';
import 'package:instaflutter/listings/ui/profile/settings/settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  final ListingsUser user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ListingsUser user;
  late bool _allowPushNotifications;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _allowPushNotifications = user.settings.allowPushNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(profileRepository: profileApiManager),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Color(colorPrimary),
              iconTheme: IconThemeData(
                  color: isDarkMode(context)
                      ? Colors.grey.shade200
                      : Colors.white),
              title: Text(
                'Settings',
                style: TextStyle(
                    color: isDarkMode(context)
                        ? Colors.grey.shade200
                        : Colors.white,
                    fontWeight: FontWeight.bold),
              ).tr(),
              centerTitle: true,
            ),
            body: BlocConsumer<SettingsBloc, SettingsState>(
              listener: (context, state) {
                if (state is SettingsSavedState) {
                  context.read<LoadingCubit>().hideLoading();
                  BlocProvider.of<AuthenticationBloc>(context).user = user;
                  showSnackBar(context, 'Settings saved successfully'.tr());
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      elevation: 2,
                      color:
                          isDarkMode(context) ? Colors.black54 : Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 16.0, left: 16, top: 16),
                            child: Text(
                              'General',
                              style: TextStyle(
                                  color: isDarkMode(context)
                                      ? Colors.white54
                                      : Colors.black54,
                                  fontSize: 18),
                            ).tr(),
                          ),
                          SwitchListTile.adaptive(
                            activeColor: Color(colorAccent),
                            title: Text(
                              'Allow Push Notifications',
                              style: TextStyle(
                                  fontSize: 17,
                                  color: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold),
                            ).tr(),
                            value: _allowPushNotifications,
                            onChanged: (bool newValue) {
                              _allowPushNotifications = newValue;
                              context
                                  .read<SettingsBloc>()
                                  .add(SettingsChangedEvent());
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0, bottom: 16),
                      child: Material(
                        elevation: 2,
                        color:
                            isDarkMode(context) ? Colors.black54 : Colors.white,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(12.0),
                          onPressed: () {
                            user.settings.allowPushNotifications =
                                _allowPushNotifications;
                            context.read<LoadingCubit>().showLoading(
                                  context,
                                  'Saving changes...'.tr(),
                                  false,
                                  Color(colorPrimary),
                                );
                            context
                                .read<SettingsBloc>()
                                .add(SaveSettingsEvent(currentUser: user));
                          },
                          color: isDarkMode(context)
                              ? Colors.black54
                              : Colors.white,
                          child: Text(
                            'Save',
                            style: TextStyle(
                                fontSize: 18, color: Color(colorPrimary)),
                          ).tr(),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
