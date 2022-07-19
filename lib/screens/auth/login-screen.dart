import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:transito/models/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordVisible = false;
  final _loginFormKey = GlobalKey<FormBuilderState>();
  final _emailFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordFieldKey = GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Welcome!')),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: SvgPicture.asset('assets/images/logo.svg'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Simply login and never miss a bus again!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: AppColors.kindaGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => debugPrint("Login"),
                            icon: SvgPicture.asset('assets/images/google_logo.svg'),
                            label:
                                Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: const [
                                Expanded(child: Divider(thickness: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'or',
                                    style: TextStyle(color: AppColors.kindaGrey),
                                  ),
                                ),
                                Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                          ),
                          FormBuilder(
                            key: _loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FormBuilderTextField(
                                  key: _emailFieldKey,
                                  name: 'email',
                                  scrollPadding: EdgeInsets.symmetric(vertical: 50),
                                  decoration: const InputDecoration(
                                    labelText: 'email',
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.email(),
                                  ]),
                                ),
                                const SizedBox(height: 16),
                                FormBuilderTextField(
                                  key: _passwordFieldKey,
                                  name: 'password',
                                  scrollPadding: EdgeInsets.symmetric(vertical: 50),
                                  obscureText: isPasswordVisible,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: FormBuilderValidators.compose(
                                      [FormBuilderValidators.required()]),
                                  decoration: InputDecoration(
                                    labelText: 'password',
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
                                const SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                  child: OutlinedButton(
                                      onPressed: () => debugPrint("balls"), child: Text('Login')),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'New Here?',
                          style: TextStyle(color: AppColors.kindaGrey),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Register!',
                          style: TextStyle(color: AppColors.veryPurple),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
