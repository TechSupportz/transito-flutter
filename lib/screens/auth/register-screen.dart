import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../models/app_colors.dart';
import '../../providers/authentication_service.dart';
import '../../widgets/email_verification_dialog.dart';
import 'login-screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerFormKey = GlobalKey<FormBuilderState>();
  final _nameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _emailFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordFieldKey = GlobalKey<FormBuilderFieldState>();
  bool isPasswordVisible = true;
  bool _isLoading = false;

  void onRegisterBtnPress() {
    setState(() {
      _isLoading = true;
    });
    _registerFormKey.currentState!.saveAndValidate();
    if (_registerFormKey.currentState!.validate()) {
      AuthenticationService()
          .registerUserWithEmail(
        _nameFieldKey.currentState!.value,
        _emailFieldKey.currentState!.value,
        _passwordFieldKey.currentState!.value,
      )
          .then((err) {
        if (err == null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (Route<dynamic> route) => false,
          );
          showDialog(
            context: context,
            builder: (context) => const EmailVerificationDialog(),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          switch (err) {
            case 'email-already-in-use':
              _emailFieldKey.currentState!.invalidate('Email already in use');
              break;
            case 'weak-password':
              _passwordFieldKey.currentState!.invalidate('Password is too weak');
              break;
          }
        }
      });
    } else {
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SvgPicture.asset('assets/images/logo.svg'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Register now and never miss a bus again!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: AppColors.kindaGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: FormBuilder(
                          key: _registerFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FormBuilderTextField(
                                key: _nameFieldKey,
                                name: 'name',
                                scrollPadding: const EdgeInsets.symmetric(vertical: 50),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                ]),
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                ),
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                key: _emailFieldKey,
                                name: 'email',
                                scrollPadding: const EdgeInsets.symmetric(vertical: 50),
                                keyboardType: TextInputType.emailAddress,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.email(),
                                ]),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                key: _passwordFieldKey,
                                name: 'password',
                                scrollPadding: const EdgeInsets.symmetric(vertical: 50),
                                obscureText: !isPasswordVisible,
                                keyboardType: TextInputType.visiblePassword,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                valueTransformer: (value) => value?.trim(),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.minLength(8),
                                ]),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(isPasswordVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded),
                                    iconSize: 24,
                                    splashRadius: 1,
                                    onPressed: () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 16),
                                child: OutlinedButton(
                                  onPressed: () => onRegisterBtnPress(),
                                  child: AnimatedSwitcher(
                                    transitionBuilder: (child, animation) => ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                    duration: const Duration(milliseconds: 175),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : const Text('Register'),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
