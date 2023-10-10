import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/api/auth_api_manager.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;
import 'package:instaflutter/constants.dart';

class ReAuthUserScreen extends StatefulWidget {
  final AuthProviders provider;
  final String? currentEmail, newEmail, phoneNumber;
  final bool isDeleteUser;

  const ReAuthUserScreen({
    Key? key,
    required this.provider,
    this.currentEmail,
    this.newEmail,
    this.phoneNumber,
    this.isDeleteUser = true,
  }) : super(key: key);

  @override
  State<ReAuthUserScreen> createState() => _ReAuthUserScreenState();
}

class _ReAuthUserScreenState extends State<ReAuthUserScreen> {
  final TextEditingController _passwordController = TextEditingController();
  late Widget body = const CircularProgressIndicator.adaptive();
  String? _verificationID, smsCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReauthUserBloc(
          provider: widget.provider, authenticationRepository: authApiManager),
      child: Builder(builder: (context) {
        return BlocConsumer<ReauthUserBloc, ReauthUserState>(
          listener: (context, state) {
            if (state is CodeSentState) {
              _verificationID = state.verificationID;
            } else if (state is ReauthSuccessfulSate) {
              context.read<LoadingCubit>().hideLoading();
              Navigator.pop(context, true);
            } else if (state is ReauthFailureState) {
              context.read<LoadingCubit>().hideLoading();
              showAlertDialog(
                  context, 'Authentication Error'.tr(), state.errorMessage);
            } else if (state is AutoPhoneVerificationCompletedState) {}
          },
          builder: (context, state) {
            if (state is ReauthUserInitial) {
              switch (state.provider) {
                case AuthProviders.password:
                  body = buildPasswordField(context);
                  break;
                case AuthProviders.phone:
                  context.read<ReauthUserBloc>().add(
                      VerifyPhoneNumberEvent(phoneNumber: widget.phoneNumber!));
                  break;
                case AuthProviders.facebook:
                  body = buildFacebookButton(context);
                  break;
                case AuthProviders.apple:
                  body = buildAppleButton(context);
                  break;
              }
            } else if (state is CodeSentState) {
              body = buildPhoneField(context);
            }

            return Dialog(
              elevation: 16,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 40.0),
                        child: Text(
                          'Please Re-Authenticate in order to perform this action.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      body,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget buildPasswordField(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 'Password'.tr()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(colorPrimary),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
              ),
            ),
            onPressed: () {
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Verifying...'.tr(),
                    false,
                    Color(colorPrimary),
                  );
              context.read<ReauthUserBloc>().add(
                    PasswordClickEvent(
                      currentEmail: widget.currentEmail!,
                      newEmail: widget.newEmail,
                      password: _passwordController.text.trim(),
                      isDeleteUser: widget.isDeleteUser,
                    ),
                  );
            },
            child: Text(
              'Verify'.tr(),
              style: TextStyle(
                  color: isDarkMode(context) ? Colors.black : Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFacebookButton(BuildContext context) {
    return ElevatedButton.icon(
      label: Text(
        'Facebook Verify'.tr(),
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      icon: Image.asset(
        'assets/images/facebook_logo.png',
        color: Colors.white,
        height: 30,
        width: 30,
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
        backgroundColor: const Color(facebookButtonColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(
            color: Color(facebookButtonColor),
          ),
        ),
      ),
      onPressed: () {
        context.read<LoadingCubit>().showLoading(
              context,
              'Verifying...'.tr(),
              false,
              Color(colorPrimary),
            );
        context.read<ReauthUserBloc>().add(FacebookClickEvent());
      },
    );
  }

  Widget buildAppleButton(BuildContext context) {
    return FutureBuilder<bool>(
      future: apple.TheAppleSignIn.isAvailable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator.adaptive();
        }
        if (!snapshot.hasData || (snapshot.data != true)) {
          return Center(
              child:
                  Text('Apple sign in is not available on this device.'.tr()));
        } else {
          return apple.AppleSignInButton(
            cornerRadius: 12.0,
            type: apple.ButtonType.continueButton,
            style: isDarkMode(context)
                ? apple.ButtonStyle.white
                : apple.ButtonStyle.black,
            onPressed: () {
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Verifying...'.tr(),
                    false,
                    Color(colorPrimary),
                  );
              context.read<ReauthUserBloc>().add(AppleClickEvent());
            },
          );
        }
      },
    );
  }

  Widget buildPhoneField(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PinCodeTextField(
            length: 6,
            appContext: context,
            keyboardType: TextInputType.phone,
            backgroundColor: Colors.transparent,
            pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 40,
                fieldWidth: 40,
                activeColor: Color(colorPrimary),
                activeFillColor: isDarkMode(context)
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                selectedFillColor: Colors.transparent,
                selectedColor: Color(colorPrimary),
                inactiveColor: Colors.grey.shade600,
                inactiveFillColor: Colors.transparent),
            enableActiveFill: true,
            onCompleted: (code) {
              smsCode = code;
              context.read<LoadingCubit>().showLoading(
                    context,
                    'Verifying...'.tr(),
                    true,
                    Color(colorPrimary),
                  );
              context.read<ReauthUserBloc>().add(SubmitSmsCodeEvent(
                  smsCode: code,
                  verificationID: _verificationID!,
                  isDeleteUser: widget.isDeleteUser));
            },
            onChanged: (value) {
              debugPrint(value);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
