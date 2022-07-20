import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../models/app_colors.dart';
import '../../providers/authentication_service.dart';
import '../navbar_screens/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerFormKey = GlobalKey<FormBuilderState>();
  final _usernameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _emailFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordFieldKey = GlobalKey<FormBuilderFieldState>();
  bool isPasswordVisible = true;

  void onRegisterBtnPress() {
    _registerFormKey.currentState!.save();
    if (_registerFormKey.currentState!.validate()) {
      AuthenticationService()
          .registerUserWithEmail(
        _usernameFieldKey.currentState!.value,
        _emailFieldKey.currentState!.value,
        _passwordFieldKey.currentState!.value,
      )
          .then((value) {
        print(value);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
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
                                key: _usernameFieldKey,
                                name: 'username',
                                scrollPadding: const EdgeInsets.symmetric(vertical: 50),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                ]),
                                decoration: const InputDecoration(
                                  labelText: 'Username',
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
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
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
                                  child: Text('Register'),
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
