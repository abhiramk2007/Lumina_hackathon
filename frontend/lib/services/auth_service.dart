import 'package:flutter/material.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/aws_config.dart';

class AuthService extends ChangeNotifier {
  final CognitoUserPool _userPool = CognitoUserPool(
    AWSConfig.userPoolId,
    AWSConfig.userPoolClientId,
  );

  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isAuthenticated => _session != null && _session!.isValid();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentEmail {
    if (_session != null && _session!.isValid()) {
      final payload = _session!.getIdToken().payload;
      if (payload != null && payload['email'] != null) {
        return payload['email'] as String;
      }
    }
    return _cognitoUser?.username;
  }

  String? get currentName {
    if (_session != null && _session!.isValid()) {
      final payload = _session!.getIdToken().payload;
      if (payload != null && payload['name'] != null) {
        return payload['name'] as String;
      }
    }
    return currentEmail?.split('@')[0].toUpperCase();
  }

  Future<String?> getToken() async {
    if (_session != null && _session!.isValid()) {
      return _session!.getIdToken().getJwtToken();
    }
    return null;
  }

  AuthService() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUser = prefs.getString('last_user');
      final lastPassword = prefs.getString('last_password');

      if (lastUser != null && lastPassword != null) {
        // Silently login in background to ensure valid tokens
        _cognitoUser = CognitoUser(lastUser, _userPool);
        final authDetails = AuthenticationDetails(username: lastUser, password: lastPassword);
        _session = await _cognitoUser!.authenticateUser(authDetails);
      } else if (lastUser != null) {
        _cognitoUser = CognitoUser(lastUser, _userPool);
        _session = await _cognitoUser!.getSession();
      }
    } catch (e) {
      print("Auth init error: $e");
      _session = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cognitoUser = CognitoUser(email, _userPool);
      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );

      _session = await cognitoUser.authenticateUser(authDetails);
      _cognitoUser = cognitoUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user', email);
      await prefs.setString('last_password', password);

      _isLoading = false;
      notifyListeners();
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "An unknown error occurred.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userAttributes = [
        AttributeArg(name: 'name', value: name),
        AttributeArg(name: 'email', value: email),
      ];

      await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );
      
      // Auto-login since our backend has AutoConfirmUser Lambda
      return await signIn(email, password);
    } on CognitoClientException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "An unknown error occurred during sign up.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (_cognitoUser != null) {
      await _cognitoUser!.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_user');
      await prefs.remove('last_password');
      
      _cognitoUser = null;
      _session = null;
      notifyListeners();
    }
  }
}
