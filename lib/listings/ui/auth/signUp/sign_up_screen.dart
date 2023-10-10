import 'dart:io';

import 'package:easy_localization/easy_localization.dart' as easy_local;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/auth/phoneAuth/numberInput/phone_number_input_screen.dart';
import 'package:instaflutter/listings/ui/auth/signUp/sign_up_bloc.dart';
import 'package:instaflutter/listings/ui/container/container_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:instaflutter/constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  File? _image;
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey();
  String? firstName, lastName, email, password, confirmPassword;
  AutovalidateMode _validate = AutovalidateMode.disabled;
  bool acceptEULA = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (context) => SignUpBloc(),
      child: Builder(
        builder: (context) {
          if (Platform.isAndroid) {
            context.read<SignUpBloc>().add(RetrieveLostDataEvent());
          }
          return MultiBlocListener(
            listeners: [
              BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) {
                  context.read<LoadingCubit>().hideLoading();
                  if (state.authState == AuthState.authenticated) {
                    if (mounted) {
                      pushAndRemoveUntil(
                          context,
                          ContainerWrapperWidget(
                            currentUser: state.user!,
                          ),
                          false);
                    }
                  } else {
                    showSnackBar(
                        context,
                        state.message ??
                            'Couldn\'t sign up, Please try again.'.tr());
                  }
                },
              ),
              BlocListener<SignUpBloc, SignUpState>(
                listener: (context, state) {
                  if (state is ValidFieldsState) {
                    context.read<LoadingCubit>().showLoading(
                          context,
                          'Creating new account, Please wait...'.tr(),
                          false,
                          Color(colorPrimary),
                        );
                    context.read<AuthenticationBloc>().add(
                        SignupWithEmailAndPasswordEvent(
                            emailAddress: email!,
                            password: password!,
                            image: _image,
                            lastName: lastName,
                            firstName: firstName));
                  } else if (state is SignUpFailureState) {
                    showSnackBar(context, state.errorMessage);
                  }
                },
              ),
            ],
            child: Scaffold(
              appBar: AppBar(
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                iconTheme: IconThemeData(
                    color: isDarkMode(context) ? Colors.white : Colors.black),
              ),
              body: SingleChildScrollView(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
                child: BlocBuilder<SignUpBloc, SignUpState>(
                  buildWhen: (old, current) =>
                      current is SignUpFailureState && old != current,
                  builder: (context, state) {
                    if (state is SignUpFailureState) {
                      _validate = AutovalidateMode.onUserInteraction;
                    }
                    return Form(
                      key: _key,
                      autovalidateMode: _validate,
                      child: GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create new account',
                              style: TextStyle(
                                  color: Color(colorPrimary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25.0),
                            ).tr(),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0, top: 32, right: 8, bottom: 8),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  BlocBuilder<SignUpBloc, SignUpState>(
                                    buildWhen: (old, current) =>
                                        current is PictureSelectedState &&
                                        old != current,
                                    builder: (context, state) {
                                      if (state is PictureSelectedState) {
                                        _image = state.imageFile;
                                      }
                                      return state is PictureSelectedState
                                          ? SizedBox(
                                              height: 130,
                                              width: 130,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(65),
                                                child: state.imageFile == null
                                                    ? Image.asset(
                                                        'assets/images/placeholder.jpg',
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        state.imageFile!,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                            )
                                          : SizedBox(
                                              height: 130,
                                              width: 130,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(65),
                                                child: Image.asset(
                                                  'assets/images/placeholder.jpg',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                  Positioned(
                                    right: 110,
                                    child: FloatingActionButton(
                                      backgroundColor: Color(colorAccent),
                                      mini: true,
                                      onPressed: () => _onCameraClick(context),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: isDarkMode(context)
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, left: 8.0),
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                validator: validateName,
                                onSaved: (String? val) {
                                  firstName = val;
                                },
                                textInputAction: TextInputAction.next,
                                decoration: getInputDecoration(
                                  hint: 'First Name'.tr(),
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error,
                                  colorPrimary: Color(colorPrimary),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, left: 8.0),
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                validator: validateName,
                                onSaved: (String? val) {
                                  lastName = val;
                                },
                                textInputAction: TextInputAction.next,
                                decoration: getInputDecoration(
                                  hint: 'Last Name'.tr(),
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error,
                                  colorPrimary: Color(colorPrimary),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, left: 8.0),
                              child: TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: validateEmail,
                                onSaved: (String? val) {
                                  email = val;
                                },
                                decoration: getInputDecoration(
                                  hint: 'Email'.tr(),
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error,
                                  colorPrimary: Color(colorPrimary),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, left: 8.0),
                              child: TextFormField(
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                controller: _passwordController,
                                validator: validatePassword,
                                onSaved: (String? val) {
                                  password = val;
                                },
                                style: const TextStyle(
                                    height: 0.8, fontSize: 18.0),
                                cursorColor: Color(colorPrimary),
                                decoration: getInputDecoration(
                                  hint: 'Password'.tr(),
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error,
                                  colorPrimary: Color(colorPrimary),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, left: 8.0),
                              child: TextFormField(
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    context.read<SignUpBloc>().add(
                                          ValidateFieldsEvent(_key,
                                              acceptEula: acceptEULA),
                                        ),
                                obscureText: true,
                                validator: (val) => validateConfirmPassword(
                                    _passwordController.text, val),
                                onSaved: (String? val) {
                                  confirmPassword = val;
                                },
                                style: const TextStyle(
                                    height: 0.8, fontSize: 18.0),
                                cursorColor: Color(colorPrimary),
                                decoration: getInputDecoration(
                                  hint: 'Confirm Password'.tr(),
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error,
                                  colorPrimary: Color(colorPrimary),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 40.0, left: 40.0, top: 40.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(colorPrimary),
                                  padding: const EdgeInsets.only(
                                      top: 12, bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    side: BorderSide(
                                      color: Color(colorPrimary),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () => context.read<SignUpBloc>().add(
                                      ValidateFieldsEvent(_key,
                                          acceptEula: acceptEULA),
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                ).tr(),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                pushReplacement(
                                    context,
                                    const PhoneNumberInputScreen(
                                        isLogin: false));
                              },
                              child: Center(
                                child: Text(
                                  'Sign up with phone number'.tr(),
                                  style: const TextStyle(
                                      color: Colors.lightBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1),
                                ).tr(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ListTile(
                              trailing: BlocBuilder<SignUpBloc, SignUpState>(
                                buildWhen: (old, current) =>
                                    current is EulaToggleState &&
                                    old != current,
                                builder: (context, state) {
                                  if (state is EulaToggleState) {
                                    acceptEULA = state.eulaAccepted;
                                  }
                                  return Checkbox(
                                    onChanged: (value) =>
                                        context.read<SignUpBloc>().add(
                                              ToggleEulaCheckboxEvent(
                                                eulaAccepted: value!,
                                              ),
                                            ),
                                    activeColor: Color(colorPrimary),
                                    value: acceptEULA,
                                  );
                                },
                              ),
                              title: RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          'By creating an account you agree to our\n'
                                              .tr(),
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                      ),
                                      text: 'Terms of Use'.tr(),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          if (await canLaunchUrl(
                                              Uri.parse(eula))) {
                                            await launchUrl(Uri.parse(eula));
                                          }
                                        },
                                    ),
                                  ],
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
            ),
          );
        },
      ),
    );
  }

  _onCameraClick(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (actionSheetContext) => CupertinoActionSheet(
        title: const Text(
          'Add Profile Picture',
          style: TextStyle(fontSize: 15.0),
        ).tr(),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: false,
            onPressed: () async {
              Navigator.pop(actionSheetContext);
              context.read<SignUpBloc>().add(ChooseImageFromGalleryEvent());
            },
            child: const Text('Choose from gallery').tr(),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () async {
              Navigator.pop(actionSheetContext);
              context.read<SignUpBloc>().add(CaptureImageByCameraEvent());
            },
            child: const Text('Take a picture').tr(),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel').tr(),
            onPressed: () => Navigator.pop(actionSheetContext)),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _image = null;
    super.dispose();
  }
}
