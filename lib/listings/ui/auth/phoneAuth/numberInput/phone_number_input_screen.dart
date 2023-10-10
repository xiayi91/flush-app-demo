import 'dart:io';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/api/auth_api_manager.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/auth/phoneAuth/codeInput/code_input_screen.dart';
import 'package:instaflutter/listings/ui/auth/phoneAuth/numberInput/phone_number_input_bloc.dart';
import 'package:instaflutter/listings/ui/container/container_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:instaflutter/constants.dart';

File? _image;

class PhoneNumberInputScreen extends StatefulWidget {
  final bool isLogin;

  const PhoneNumberInputScreen({Key? key, required this.isLogin})
      : super(key: key);

  @override
  State<PhoneNumberInputScreen> createState() => _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState extends State<PhoneNumberInputScreen> {
  final GlobalKey<FormState> _key = GlobalKey();
  String? firstName, lastName, _phoneNumber;
  bool _isPhoneValid = false;
  AutovalidateMode _validate = AutovalidateMode.disabled;
  bool acceptEULA = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhoneNumberInputBloc>(
      create: (context) =>
          PhoneNumberInputBloc(authenticationRepository: authApiManager),
      child: Builder(
        builder: (context) {
          if (Platform.isAndroid && !widget.isLogin) {
            context.read<PhoneNumberInputBloc>().add(RetrieveLostDataEvent());
          }
          return MultiBlocListener(
            listeners: [
              BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) {
                  context.read<LoadingCubit>().hideLoading();
                  if (state.authState == AuthState.authenticated) {
                    context.read<LoadingCubit>().hideLoading();
                    if (mounted) {
                      pushAndRemoveUntil(
                          context,
                          ContainerWrapperWidget(currentUser: state.user!),
                          false);
                    }
                  } else {
                    showSnackBar(
                        context,
                        state.message ??
                            'Phone authentication failed, Please try again.'
                                .tr());
                  }
                },
              ),
              BlocListener<PhoneNumberInputBloc, PhoneNumberInputState>(
                listener: (context, state) {
                  if (state is CodeSentState) {
                    context.read<LoadingCubit>().hideLoading();
                    pushReplacement(
                        context,
                        CodeInputScreen(
                          isLogin: widget.isLogin,
                          verificationID: state.verificationID,
                          phoneNumber: _phoneNumber!,
                          firstName: firstName,
                          lastName: lastName,
                          image: _image,
                        ));
                  } else if (state is PhoneInputFailureState) {
                    context.read<LoadingCubit>().hideLoading();
                    showSnackBar(context, state.errorMessage);
                  } else if (state is AutoPhoneVerificationCompletedState) {
                    context
                        .read<AuthenticationBloc>()
                        .add(LoginWithPhoneNumberEvent(
                          credential: state.credential,
                          phoneNumber: _phoneNumber!,
                          firstName: firstName,
                          lastName: lastName,
                          image: _image,
                        ));
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
                child: BlocBuilder<PhoneNumberInputBloc, PhoneNumberInputState>(
                  buildWhen: (old, current) =>
                      current is PhoneInputFailureState && old != current,
                  builder: (context, state) {
                    if (state is PhoneInputFailureState) {
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
                              widget.isLogin
                                  ? 'Sign In'.tr()
                                  : 'Create new account'.tr(),
                              style: TextStyle(
                                  color: Color(colorPrimary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25.0),
                            ),

                            /// user profile picture,  this is visible until we verify the
                            /// code in case of sign up with phone number
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0, top: 32, right: 8, bottom: 8),
                              child: Visibility(
                                visible: !widget.isLogin,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    BlocBuilder<PhoneNumberInputBloc,
                                        PhoneNumberInputState>(
                                      buildWhen: (old, current) =>
                                          current is PictureSelectedState &&
                                          old != current,
                                      builder: (context, state) {
                                        if (state is PictureSelectedState) {
                                          _image = state.imageFile;
                                        }
                                        return state is PictureSelectedState
                                            ? SizedBox(
                                                width: 130,
                                                height: 130,
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
                                        onPressed: () =>
                                            _onCameraClick(context),
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
                            ),

                            /// user first name text field , this is visible until we verify the
                            /// code in case of sign up with phone number
                            Visibility(
                              visible: !widget.isLogin,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  cursorColor: Color(colorPrimary),
                                  textAlignVertical: TextAlignVertical.center,
                                  validator: validateName,
                                  textCapitalization: TextCapitalization.words,
                                  onSaved: (String? val) {
                                    firstName = val ?? 'Anonymous';
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
                            ),

                            /// last name of the user , this is visible until we verify the
                            /// code in case of sign up with phone number
                            Visibility(
                              visible: !widget.isLogin,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, right: 8.0, left: 8.0),
                                child: TextFormField(
                                  validator: validateName,
                                  textAlignVertical: TextAlignVertical.center,
                                  textCapitalization: TextCapitalization.words,
                                  cursorColor: Color(colorPrimary),
                                  onSaved: (String? val) {
                                    lastName = val ?? 'User';
                                  },
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
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
                            ),

                            /// user phone number,  this is visible until we verify the code
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, left: 8.0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                        color: Colors.grey.shade200)),
                                child: InternationalPhoneNumberInput(
                                  autoFocus: widget.isLogin,
                                  autoFocusSearch: true,
                                  onInputChanged: (PhoneNumber number) =>
                                      _phoneNumber = number.phoneNumber,
                                  onInputValidated: (bool value) =>
                                      _isPhoneValid = value,
                                  ignoreBlank: true,
                                  autoValidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  inputDecoration: InputDecoration(
                                    hintText: 'Phone Number'.tr(),
                                    border: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true,
                                    errorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  inputBorder: const OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  selectorConfig: const SelectorConfig(
                                      selectorType:
                                          PhoneInputSelectorType.DIALOG),
                                ),
                              ),
                            ),

                            /// the main action button of the screen, this is hidden if we
                            /// received the code from firebase
                            /// the action and the title is base on the state,
                            /// * Sign up with email and password: send email and password to
                            /// firebase
                            /// * Sign up with phone number: submits the phone number to
                            /// firebase and await for code verification
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 40.0, left: 40.0, top: 40.0),
                              child: BlocListener<PhoneNumberInputBloc,
                                  PhoneNumberInputState>(
                                listener: (context, state) {
                                  if (state is PhoneInputFailureState) {
                                    showSnackBar(context, state.errorMessage);
                                  } else if (state is ValidFieldsState) {
                                    context.read<LoadingCubit>().showLoading(
                                          context,
                                          'Sending code...'.tr(),
                                          false,
                                          Color(colorPrimary),
                                        );
                                    context.read<PhoneNumberInputBloc>().add(
                                        VerifyPhoneNumberEvent(
                                            phoneNumber: _phoneNumber!));
                                  }
                                },
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
                                  onPressed: () =>
                                      context.read<PhoneNumberInputBloc>().add(
                                            ValidateFieldsEvent(
                                              _key,
                                              acceptEula: acceptEULA,
                                              isLogin: widget.isLogin,
                                              isPhoneValid: _isPhoneValid,
                                            ),
                                          ),
                                  child: Text(
                                    'Send Code'.tr(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'OR'.tr(),
                                  style: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              ),
                            ),

                            /// switch between sign up with phone number and email sign up states
                            Center(
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  widget.isLogin
                                      ? 'Login with E-mail and password'.tr()
                                      : 'Sign up with E-mail and password'.tr(),
                                  style: const TextStyle(
                                      color: Colors.lightBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Visibility(
                              visible: !widget.isLogin,
                              child: ListTile(
                                trailing: BlocBuilder<PhoneNumberInputBloc,
                                    PhoneNumberInputState>(
                                  buildWhen: (old, current) =>
                                      current is EulaToggleState &&
                                      old != current,
                                  builder: (context, state) {
                                    if (state is EulaToggleState) {
                                      acceptEULA = state.eulaAccepted;
                                    }
                                    return Checkbox(
                                      onChanged: (value) => context
                                          .read<PhoneNumberInputBloc>()
                                          .add(
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

  /// a set of menu options that appears when trying to select a profile
  /// image from gallery or take a new pic
  _onCameraClick(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (actionSheetContext) => CupertinoActionSheet(
              message: const Text(
                'Add profile picture',
                style: TextStyle(fontSize: 15.0),
              ).tr(),
              actions: [
                CupertinoActionSheetAction(
                  isDefaultAction: false,
                  onPressed: () async {
                    Navigator.pop(actionSheetContext);
                    context
                        .read<PhoneNumberInputBloc>()
                        .add(ChooseImageFromGalleryEvent());
                  },
                  child: const Text('Choose from gallery').tr(),
                ),
                CupertinoActionSheetAction(
                  isDestructiveAction: false,
                  onPressed: () async {
                    Navigator.pop(actionSheetContext);
                    context
                        .read<PhoneNumberInputBloc>()
                        .add(CaptureImageByCameraEvent());
                  },
                  child: const Text('Take a picture').tr(),
                )
              ],
              cancelButton: CupertinoActionSheetAction(
                  child: const Text('Cancel').tr(),
                  onPressed: () => Navigator.pop(actionSheetContext)),
            ));
  }
}
