import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  String email = '';
  String username = '';
  String displayName = '';
  String avatarUrl = '';
  String message = '';

  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://192.168.1.114:5000/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        email = data['email'] ?? '';
        username = data['username'] ?? '';
        displayName = data['display_name'] ?? '';
        avatarUrl = data['avatar_url'] != null
            ? 'http://192.168.1.114:5000${data['avatar_url']}'
            : '';
        _usernameController.text = username;
        _displayNameController.text = displayName;
        _avatarUrlController.text = avatarUrl;
      });
    }
  }

  Future<void> _updateProfile() async {
    final token = await _storage.read(key: 'token');

    final body = {
      'username': _usernameController.text.trim(),
      'display_name': _displayNameController.text.trim(),
      'avatar_url': _avatarUrlController.text.trim(),
    };

    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();

    if (oldPass.isNotEmpty && newPass.isNotEmpty) {
      body['old_password'] = oldPass;
      body['new_password'] = newPass;
    }

    final response = await http.put(
      Uri.parse('http://192.168.1.114:5000/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    setState(() {
      message = jsonDecode(response.body)['message'] ?? 'Щось пішло не так';
    });

    if (response.statusCode == 200) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _loadProfile();
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final token = await _storage.read(key: 'token');
    final uri = Uri.parse('http://192.168.1.114:5000/upload-avatar');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('avatar', pickedFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200 && data['avatar_url'] != null) {
      setState(() {
        avatarUrl = 'http://192.168.1.114:5000${data['avatar_url']}';
        _avatarUrlController.text = avatarUrl;
        message = data['message'];
      });
    } else {
      setState(() {
        message = 'Не вдалося завантажити аватар';
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
      appBar: AppBar(title: const Text('Профіль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: _pickAndUploadAvatar,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Відображуване ім’я'),
            ),
            TextField(
              controller: _avatarUrlController,
              decoration: const InputDecoration(labelText: 'URL аватарки'),
            ),
            const Divider(height: 32),
            const Text('Зміна пароля', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(labelText: 'Старий пароль'),
              obscureText: true,
            ),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'Новий пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Зберегти зміни'),
            ),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Вийти з акаунту'),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message.contains('успішно') ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
