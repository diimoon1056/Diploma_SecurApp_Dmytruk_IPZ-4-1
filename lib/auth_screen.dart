import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _storage = const FlutterSecureStorage();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String error = '';
  String info = ''; // 🔹 додано для успішних повідомлень

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final url = Uri.parse(
        'http://192.168.1.114:5000/${isLogin ? 'login' : 'register'}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        if (!isLogin) 'username': email.split('@')[0],
      }),
    );

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🔘 response.statusCode: ${response.statusCode}');
        print('🔘 response.body: ${response.body}');

        if (isLogin && data['access_token'] != null) {
          await _storage.write(key: 'token', value: data['access_token']);
          print('✅ Вхід успішний. Токен: ${data['access_token']}');
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
        else {
          setState(() {
            isLogin = true;
            info = 'Реєстрація успішна. Увійдіть.';
            error = '';
          });
        }
      }
       else {
        setState(() {
          error = data['message'] ?? 'Помилка';
          info = '';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Невірна відповідь від сервера';
        info = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLogin ? 'Вхід' : 'Реєстрація',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(isLogin ? 'Увійти' : 'Зареєструватися'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      error = '';
                      info = '';
                    });
                  },
                  child: Text(isLogin
                      ? 'Немає акаунту? Зареєструватися'
                      : 'Вже є акаунт? Увійти'),
                ),
                if (error.isNotEmpty)
                  Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (info.isNotEmpty)
                  Text(
                    info,
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
