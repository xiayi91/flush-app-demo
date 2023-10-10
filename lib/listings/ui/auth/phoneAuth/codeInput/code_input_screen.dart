import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/api/auth_api_manager.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/auth/phoneAuth/codeInput/code_input_bloc.dart';
import 'package:instaflutter/listings/ui/container/container_screen.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class CodeInputScreen extends StatefulWidget {
  final bool isLogin;
  final String verificationID, phoneNumber;
  final String? firstName, lastName;
  final File? image;

  const CodeInputScreen(
      {Key? key,
      required this.isLogin,
      required this.verificationID,
      required this.phoneNumber,
      this.firstName = 'Anonymous',
      this.lastName = 'User',
      this.image})
      : super(key: key);

  @override
  State<CodeInputScreen> createState() => _CodeInputScreenState();
}

class _CodeInputScreenState extends State<CodeInputScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CodeInputBloc>(
      create: (context) =>
          CodeInputBloc(authenticationRepository: authApiManager),
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
            listeners: [
              BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) {
                  context.read<LoadingCubit>().hideLoading();
                  if (state.authState == AuthState.authenticated) {
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
              BlocListener<CodeInputBloc, CodeInputState>(
                listener: (context, state) {
                  if (state is CodeSubmittedState) {
                    context.read<AuthenticationBloc>().add(
                        LoginWithPhoneNumberEvent(
                            credential: state.credential,
                            phoneNumber: widget.phoneNumber,
                            firstName: widget.firstName,
                            lastName: widget.lastName,
                            image: widget.image));
                  } else if (state is CodeSubmitFailedState) {
                    context.read<LoadingCubit>().hideLoading();
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
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 32.0, right: 24.0, left: 24.0),
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
                            context.read<LoadingCubit>().showLoading(
                                  context,
                                  widget.isLogin
                                      ? 'Logging in...'.tr()
                                      : 'Signing up...'.tr(),
                                  false,
                                  Color(colorPrimary),
                                );
                            context.read<CodeInputBloc>().add(SubmitCodeEvent(
                                code: code,
                                verificationID: widget.verificationID));
                          },
                          onChanged: (value) {
                            debugPrint(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
