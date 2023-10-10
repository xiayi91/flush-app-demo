import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/listings/ui/profile/accountDetails/account_details_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';

class AccountDetailsWrapperWidget extends StatelessWidget {
  final ListingsUser user;

  const AccountDetailsWrapperWidget({Key? key, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountDetailsBloc(
        profileRepository: profileApiManager,
        currentUser: user,
      ),
      child: AccountDetailsScreen(user: user),
    );
  }
}

class AccountDetailsScreen extends StatefulWidget {
  final ListingsUser user;

  const AccountDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AccountDetailsScreen> createState() {
    return _AccountDetailsScreenState();
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late ListingsUser user;
  final GlobalKey<FormState> _key = GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  String? firstName, email, mobile, lastName;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(colorPrimary),
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        title: Text(
          'Account details',
          style: TextStyle(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
              fontWeight: FontWeight.bold),
        ).tr(),
        centerTitle: true,
      ),
      body: BlocConsumer<AccountDetailsBloc, AccountDetailsState>(
        listener: (context, state) async {
          if (state is AccountFieldsRequiredState) {
            showSnackBar(context, 'Some fields are required.'.tr());
            _validate = AutovalidateMode.onUserInteraction;
          } else if (state is ValidFieldsState) {
            context.read<AccountDetailsBloc>().add(TryToSubmitDataEvent(
                  firstName: firstName!,
                  lastName: lastName!,
                  emailAddress: email!,
                  phoneNumber: mobile!,
                ));
          } else if (state is ReauthRequiredState) {
            bool result = await showDialog(
              context: context,
              builder: (context) => ReAuthUserScreen(
                provider: state.authProvider,
                phoneNumber: state.authProvider == AuthProviders.phone
                    ? state.data
                    : null,
                newEmail: state.authProvider == AuthProviders.password
                    ? state.data
                    : null,
                currentEmail: state.authProvider == AuthProviders.password
                    ? context.read<AuthenticationBloc>().user!.email
                    : null,
                isDeleteUser: false,
              ),
            );

            if (result) {
              if (!mounted) return;
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Saving details...'.tr(),
                    false,
                    Color(colorPrimary),
                  );
              context.read<AccountDetailsBloc>().add(UpdateUserDataEvent(
                    firstName: firstName!,
                    lastName: lastName!,
                    emailAddress: email!,
                    phoneNumber: mobile!,
                  ));
            }
          } else if (state is UpdatingDataState) {
            context.read<LoadingCubit>().showLoading(
                  context,
                  'Saving details...'.tr(),
                  false,
                  Color(colorPrimary),
                );
          } else if (state is UserDataUpdatedState) {
            context.read<LoadingCubit>().hideLoading();
            user = state.updatedUser;
            context.read<AuthenticationBloc>().user = state.updatedUser;
            showSnackBar(context, 'Details saved successfully'.tr());
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Form(
              key: _key,
              autovalidateMode: _validate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16, bottom: 8, top: 24),
                    child: const Text(
                      'PUBLIC INFO',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ).tr(),
                  ),
                  Material(
                      elevation: 2,
                      color:
                          isDarkMode(context) ? Colors.black54 : Colors.white,
                      child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children:
                              ListTile.divideTiles(context: context, tiles: [
                            ListTile(
                              title: Text(
                                'First name',
                                style: TextStyle(
                                  color: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ).tr(),
                              trailing: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 100),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    firstName = val;
                                  },
                                  initialValue: user.firstName,
                                  validator: validateName,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                  cursorColor: Color(colorAccent),
                                  textCapitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'First name'.tr(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 5)),
                                ),
                              ),
                            ),
                            ListTile(
                              title: Text(
                                'Last name',
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black),
                              ).tr(),
                              trailing: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 100),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    lastName = val;
                                  },
                                  initialValue: user.lastName,
                                  validator: validateName,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                  cursorColor: Color(colorAccent),
                                  textCapitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Last name'.tr(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 5)),
                                ),
                              ),
                            )
                          ]).toList())),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16, bottom: 8, top: 24),
                    child: const Text(
                      'PRIVATE DETAILS',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ).tr(),
                  ),
                  Material(
                    elevation: 2,
                    color: isDarkMode(context) ? Colors.black54 : Colors.white,
                    child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: ListTile.divideTiles(
                          context: context,
                          tiles: [
                            ListTile(
                              title: Text(
                                'Email Address',
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black),
                              ).tr(),
                              trailing: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    email = val;
                                  },
                                  initialValue: user.email,
                                  validator: validateEmail,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                  cursorColor: Color(colorAccent),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Email Address'.tr(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 5)),
                                ),
                              ),
                            ),
                            ListTile(
                              title: Text(
                                'Phone Number',
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black),
                              ).tr(),
                              trailing: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 150),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    mobile = val;
                                  },
                                  initialValue: user.phoneNumber,
                                  validator: validateMobile,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                  cursorColor: Color(colorAccent),
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Phone Number'.tr(),
                                      contentPadding:
                                          const EdgeInsets.only(bottom: 2)),
                                ),
                              ),
                            ),
                          ],
                        ).toList()),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 16),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: double.infinity),
                      child: Material(
                        elevation: 2,
                        color:
                            isDarkMode(context) ? Colors.black54 : Colors.white,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(12.0),
                          onPressed: () => context
                              .read<AccountDetailsBloc>()
                              .add(ValidateFieldsEvent(_key)),
                          child: Text(
                            'Save',
                            style: TextStyle(
                                fontSize: 18, color: Color(colorPrimary)),
                          ).tr(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
