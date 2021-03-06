import 'package:Openbook/provider.dart';
import 'package:Openbook/services/httpie.dart';
import 'package:Openbook/services/localization.dart';
import 'package:Openbook/services/user.dart';
import 'package:Openbook/services/validation.dart';
import 'package:Openbook/widgets/buttons/button.dart';
import 'package:Openbook/widgets/buttons/success_button.dart';
import 'package:Openbook/widgets/buttons/secondary_button.dart';
import 'package:flutter/material.dart';

class OBAuthLoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OBAuthLoginPageState();
  }
}

class OBAuthLoginPageState extends State<OBAuthLoginPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitted;
  bool _passwordIsVisible;
  String _loginFeedback;
  bool _loginInProgress;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  LocalizationService _localizationService;
  ValidationService _validationService;
  UserService _userService;

  @override
  void initState() {
    super.initState();

    _loginInProgress = false;
    _isSubmitted = false;
    _passwordIsVisible = false;

    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
  }

  @override
  Widget build(BuildContext context) {
    var openbookProvider = OpenbookProvider.of(context);
    _localizationService = openbookProvider.localizationService;
    _validationService = openbookProvider.validationService;
    _userService = openbookProvider.userService;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: <Widget>[
                    _buildHeading(context: context),
                    const SizedBox(
                      height: 30.0,
                    ),
                    _buildLoginForm(),
                    const SizedBox(
                      height: 20.0,
                    ),
                    _buildLoginFeedback()
                  ],
                ))),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: _buildPreviousButton(context: context),
              ),
              Expanded(child: _buildContinueButton(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFeedback() {
    if (_loginFeedback == null) return const SizedBox();

    return SizedBox(
      child: Text(
        _loginFeedback,
        style: TextStyle(fontSize: 16.0, color: Colors.deepOrange),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    String buttonText = _localizationService.trans('AUTH.LOGIN.LOGIN');

    return OBSuccessButton(
      isLoading: _loginInProgress,
      minWidth: double.infinity,
      size: OBButtonSize.large,
      child: Text(buttonText, style: TextStyle(fontSize: 18.0)),
      onPressed: () async {
        _isSubmitted = true;
        if (_validateForm()) {
          await _login(context);
        }
      },
    );
  }

  Future<void> _login(BuildContext context) async {
    _setLoginInProgress(true);
    String username = _usernameController.text;
    String password = _passwordController.text;
    try {
      await _userService.loginWithCredentials(
          username: username, password: password);
      Navigator.pop(context);  //pop the login form screen
      Navigator.pushReplacementNamed(context, '/'); //replace the underlying login splash screen too
    } on CredentialsMismatchError {
      _setLoginFeedback(
          _localizationService.trans('AUTH.LOGIN.CREDENTIALS_MISMATCH_ERROR'));
    } on HttpieRequestError {
      _setLoginFeedback(_localizationService.trans('AUTH.LOGIN.SERVER_ERROR'));
    } on HttpieConnectionRefusedError {
      _setLoginFeedback(
          _localizationService.trans('AUTH.LOGIN.CONNECTION_ERROR'));
    }
    _setLoginInProgress(false);
  }

  Widget _buildPreviousButton({@required BuildContext context}) {
    String buttonText = _localizationService.trans('AUTH.LOGIN.PREVIOUS');

    return OBSecondaryButton(
      isFullWidth: true,
      isLarge: true,
      child: Row(
        children: <Widget>[
          Icon(Icons.arrow_back_ios),
          const SizedBox(
            width: 10.0,
          ),
          Text(
            buttonText,
            style: TextStyle(fontSize: 18.0),
          )
        ],
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHeading({@required BuildContext context}) {
    String titleText = _localizationService.trans('AUTH.LOGIN.TITLE');
    String subtitleText = _localizationService.trans('AUTH.LOGIN.SUBTITLE');

    return Column(
      children: <Widget>[
        Text(
          '👋',
          style: TextStyle(fontSize: 45.0, color: Colors.black),
        ),
        const SizedBox(
          height: 20.0,
        ),
        Text(titleText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
        const SizedBox(
          height: 10.0,
        ),
        Text(subtitleText,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16.0)),
      ],
    );
  }

  Widget _buildLoginForm() {
    // If we use StreamBuilder to build the TexField it has a weird
    // bug which places the cursor at the beginning of the label everytime
    // the stream changes. Therefore a flag is used to bootstrap initial value

    String usernameInputLabel =
        _localizationService.trans('AUTH.LOGIN.USERNAME_LABEL');

    String passwordInputLabel =
        _localizationService.trans('AUTH.LOGIN.PASSWORD_LABEL');

    EdgeInsetsGeometry inputContentPadding =
        EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0);

    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            SizedBox(
              child: Row(children: <Widget>[
                new Expanded(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _usernameController,
                            validator: _validateUsername,
                            decoration: InputDecoration(
                              contentPadding: inputContentPadding,
                              labelText: usernameInputLabel,
                              border: OutlineInputBorder(),
                            ),
                            autocorrect: false,
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordIsVisible,
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              suffixIcon: GestureDetector(
                                child: Icon(_passwordIsVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onTap: () {
                                  _togglePasswordVisibility();
                                },
                              ),
                              contentPadding: inputContentPadding,
                              labelText: passwordInputLabel,
                              border: OutlineInputBorder(),
                            ),
                            autocorrect: false,
                          )
                        ],
                      )),
                ),
              ]),
            ),
          ],
        ));
  }

  String _validateUsername(String value) {
    if (!_isSubmitted) return null;
    return _validationService.validateUserUsername(value);
  }

  String _validatePassword(String value) {
    if (!_isSubmitted) return null;

    return _validationService.validateUserPassword(value);
  }

  bool _validateForm() {
    if (_loginFeedback != null) {
      _setLoginFeedback(null);
    }
    return _formKey.currentState.validate();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordIsVisible = !_passwordIsVisible;
    });
  }

  void _setLoginFeedback(String feedback) {
    setState(() {
      _loginFeedback = feedback;
    });
  }

  void _setLoginInProgress(bool loginInProgress) {
    setState(() {
      _loginInProgress = loginInProgress;
    });
  }
}
