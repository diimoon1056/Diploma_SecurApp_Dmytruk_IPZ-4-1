import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String message = '';

  Future<void> _changePassword() async {
    final token = await _storage.read(key: 'token');
    final response = await http.put(
      Uri.parse('http://192.168.1.109:5000/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'old_password': _oldPasswordController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        message = 'Пароль змінено успішно!';
      });
    } else {
      setState(() {
        message = 'Помилка: ${jsonDecode(response.body)['message']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Зміна пароля'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Старий пароль'),
          ),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Новий пароль'),
          ),
          const SizedBox(height: 10),
          if (message.isNotEmpty)
            Text(message, style: const TextStyle(color: Colors.green)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрити'),
        ),
        ElevatedButton(
          onPressed: _changePassword,
          child: const Text('Змінити'),
        ),
      ],
    );
  }
}


class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  String email = '';
  String message = '';


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.1.109:5000/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        email = data['email'] ?? 'Невідомо';
      });
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профіль'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(email, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Вийти з акаунту'),

            ),
            if (message.isNotEmpty)
              Text(message, style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _ChangePasswordDialog(),
                );
              },
              child: const Text('Змінити пароль'),
            ),
          ],
        ),
      ),
    );
  }
}
