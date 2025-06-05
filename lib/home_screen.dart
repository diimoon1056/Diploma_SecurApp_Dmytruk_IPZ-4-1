import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> users = [];
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      setState(() => error = 'Токен не знайдено');
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.109:5000/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('📨 TOKEN: $token');
    print('📦 PROFILE RESPONSE: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = data['users'] ?? [];
      });
    } else {
      setState(() {
        error = 'Не вдалося завантажити користувачів';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Користувачі'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: error.isNotEmpty
          ? Center(
              child: Text(error, style: const TextStyle(color: Colors.red)),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user['email'] ?? 'Без email'),
                  subtitle: Text(user['username'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          userId: user['_id'],
                          email: user['email'] ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
