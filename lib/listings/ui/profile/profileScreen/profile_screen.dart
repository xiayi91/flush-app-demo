import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_screen.dart';
import 'package:instaflutter/listings/ui/auth/welcome/welcome_screen.dart';
import 'package:instaflutter/listings/ui/listings/adminDashboard/admin_dashboard_screen.dart';
import 'package:instaflutter/listings/ui/listings/favoriteListings/favorite_listings_screen.dart';
import 'package:instaflutter/listings/ui/listings/myListings/my_listings_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/listings/ui/profile/accountDetails/account_details_screen.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';
import 'package:instaflutter/listings/ui/profile/contactUs/contact_us_screen.dart';
import 'package:instaflutter/listings/ui/profile/profileScreen/profile_bloc.dart';
import 'package:instaflutter/listings/ui/profile/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const ProfileScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ListingsUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Platform.isIOS
          ? AppBar(
              title: Text('Profile'.tr()),
            )
          : null,
      body: BlocProvider(
        create: (context) => ProfileBloc(
          currentUser: currentUser,
          profileRepository: profileApiManager,
        ),
        child: Builder(
          builder: (context) {
            return MultiBlocListener(
              listeners: [
                BlocListener<AuthenticationBloc, AuthenticationState>(
                  listener: (context, state) {
                    context.read<LoadingCubit>().hideLoading();
                    if (state.authState == AuthState.unauthenticated) {
                      pushAndRemoveUntil(context, const WelcomeScreen(), false);
                    }
                  },
                ),
                BlocListener<ProfileBloc, ProfileState>(
                  listener: (context, state) async {
                    if (state is UpdatedUserState) {
                      context.read<LoadingCubit>().hideLoading();
                      context.read<AuthenticationBloc>().user =
                          state.updatedUser;
                      currentUser = state.updatedUser;
                    } else if (state is UploadingImageState) {
                      context.read<LoadingCubit>().showLoading(
                            context,
                            'Uploading image...'.tr(),
                            false,
                            Color(colorPrimary),
                          );
                    } else if (state is ReauthRequiredState) {
                      bool? result = await showDialog(
                        context: context,
                        builder: (context) => ReAuthUserScreen(
                          provider: state.authProvider,
                          currentEmail:
                              auth.FirebaseAuth.instance.currentUser!.email,
                          phoneNumber: auth
                              .FirebaseAuth.instance.currentUser!.phoneNumber,
                          isDeleteUser: true,
                        ),
                      );
                      if (result != null && result) {
                        if (!mounted) return;
                        context
                            .read<AuthenticationBloc>()
                            .add(UserDeletedEvent());
                      }
                    } else if (state is DeleteUserConfirmationState) {
                      bool? result;
                      String title = 'Account Deletion'.tr();
                      String content =
                          'Are you sure you want to delete your account? This can not be undone.'
                              .tr();
                      if (Platform.isIOS) {
                        await showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                                  title: Text(title),
                                  content: Text(content),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        result = true;
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Yes').tr(),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        result = false;
                                        Navigator.pop(context);
                                      },
                                      child: const Text('No').tr(),
                                    ),
                                  ],
                                ));
                      } else {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(title),
                            content: Text(content),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  result = true;
                                  Navigator.pop(context);
                                },
                                child: const Text('Yes').tr(),
                              ),
                              TextButton(
                                onPressed: () {
                                  result = false;
                                  Navigator.pop(context);
                                },
                                child: const Text('No').tr(),
                              ),
                            ],
                          ),
                        );
                      }
                      if (result != null && result!) {
                        if (!mounted) return;
                        context.read<LoadingCubit>().showLoading(
                              context,
                              'Deleting account...'.tr(),
                              false,
                              Color(colorPrimary),
                            );
                        context
                            .read<ProfileBloc>()
                            .add(DeleteUserConfirmedEvent());
                      }
                    } else if (state is UserDeletedState) {
                      context.read<LoadingCubit>().hideLoading();
                      context
                          .read<AuthenticationBloc>()
                          .add(UserDeletedEvent());
                    }
                  },
                ),
              ],
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 32.0, left: 32, right: 32),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          BlocBuilder<ProfileBloc, ProfileState>(
                              buildWhen: (old, current) =>
                                  current is UpdatedUserState && old != current,
                              builder: (context, state) {
                                return Center(
                                    child: displayCircleImage(
                                        currentUser.profilePictureURL,
                                        130,
                                        false));
                              }),
                          Positioned.directional(
                            textDirection: Directionality.of(context),
                            start: 80,
                            end: 0,
                            child: FloatingActionButton(
                                backgroundColor: Color(colorAccent),
                                mini: true,
                                onPressed: () => _onCameraClick(context),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: isDarkMode(context)
                                      ? Colors.black
                                      : Colors.white,
                                )),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 16.0, right: 32, left: 32),
                      child: BlocBuilder<ProfileBloc, ProfileState>(
                          buildWhen: (old, current) =>
                              current is UpdatedUserState && old != current,
                          builder: (context, state) {
                            return Text(
                              currentUser.fullName(),
                              style: TextStyle(
                                  color: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20),
                              textAlign: TextAlign.center,
                            );
                          }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            onTap: () => push(
                                context,
                                MyListingsWrapperWidget(
                                    currentUser: currentUser)),
                            title: Text(
                              'My Listings'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            leading: Image.asset(
                              'assets/images/listings_welcome_image.png',
                              height: 24,
                              width: 24,
                              color: Color(colorPrimary),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            onTap: () => push(
                                context,
                                FavoriteListingsWrapperWidget(
                                  currentUser: currentUser,
                                )),
                            title: Text(
                              'My Favorites'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            leading: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                          ),
                          ListTile(
                            onTap: () async {
                              await push(
                                  context,
                                  AccountDetailsWrapperWidget(
                                      user: currentUser));
                              if (!mounted) return;
                              currentUser =
                                  context.read<AuthenticationBloc>().user!;
                              context.read<ProfileBloc>().add(
                                  InvalidateUserObjectEvent(
                                      newUser: currentUser));
                            },
                            title: const Text(
                              'Account Details',
                              style: TextStyle(fontSize: 16),
                            ).tr(),
                            leading: Icon(
                              Icons.person,
                              color: Color(colorPrimary),
                            ),
                          ),
                          ListTile(
                            onTap: () => push(
                                context, SettingsScreen(user: currentUser)),
                            title: const Text(
                              'Settings',
                              style: TextStyle(fontSize: 16),
                            ).tr(),
                            leading: Icon(
                              Icons.settings,
                              color: isDarkMode(context)
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                          ),
                          ListTile(
                            onTap: () => push(context, const ContactUsScreen()),
                            title: const Text(
                              'Contact Us',
                              style: TextStyle(fontSize: 16),
                            ).tr(),
                            leading: const Icon(
                              Icons.call,
                              color: Colors.green,
                            ),
                          ),
                          ListTile(
                            dense: true,
                            onTap: () => context
                                .read<ProfileBloc>()
                                .add(TryToDeleteUserEvent()),
                            title: Text(
                              'Delete Account'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            leading: const Icon(
                              CupertinoIcons.delete,
                              color: Colors.red,
                            ),
                          ),
                          if (currentUser.isAdmin)
                            ListTile(
                              dense: true,
                              onTap: () => push(
                                  context,
                                  AdminDashboardWrappingWidget(
                                      currentUser: currentUser)),
                              title: Text(
                                'Admin Dashboard'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                              leading: const Icon(
                                Icons.dashboard,
                                color: Colors.blueGrey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: double.infinity),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(
                                  color: isDarkMode(context)
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200),
                            ),
                          ),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black),
                          ).tr(),
                          onPressed: () {
                            context.read<LoadingCubit>().showLoading(
                                  context,
                                  'Logging out...'.tr(),
                                  false,
                                  Color(colorPrimary),
                                );
                            context
                                .read<AuthenticationBloc>()
                                .add(LogoutEvent(currentUser));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _onCameraClick(BuildContext context) => showCupertinoModalPopup(
        context: context,
        builder: (actionSheetContext) => CupertinoActionSheet(
          message: const Text(
            'Manage Profile Picture',
            style: TextStyle(fontSize: 15.0),
          ).tr(),
          actions: [
            if (currentUser.profilePictureURL.isNotEmpty)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(actionSheetContext);
                  context.read<LoadingCubit>().showLoading(
                        context,
                        'Removing picture...'.tr(),
                        false,
                        Color(colorPrimary),
                      );
                  context.read<ProfileBloc>().add(DeleteUserImageEvent());
                },
                child: const Text('Remove picture').tr(),
              ),
            CupertinoActionSheetAction(
              child: const Text('Choose from gallery').tr(),
              onPressed: () {
                Navigator.pop(actionSheetContext);
                context.read<ProfileBloc>().add(ChooseImageFromGalleryEvent());
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Take a picture').tr(),
              onPressed: () {
                Navigator.pop(actionSheetContext);
                context.read<ProfileBloc>().add(CaptureImageByCameraEvent());
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel').tr(),
            onPressed: () => Navigator.pop(actionSheetContext),
          ),
        ),
      );
}
