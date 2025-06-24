import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://192.168.1.114:5000/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        chats = data['chats'];
      });
    } else {
      print('❌ Error loading chats: ${response.body}');
    }
  }

  String formattedTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return DateFormat.Hm().format(dt); // 14:32
    } else if (diff.inDays == 1) {
      return 'Вчора';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE', 'uk').format(dt); // Пн, Вт, Ср...
    } else {
      return DateFormat('d MMM', 'uk').format(dt); // 9 черв.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final name = chat['display_name']?.toString().trim().isNotEmpty == true
              ? chat['display_name']
              : (chat['username'] ?? 'Без імені');
          final lastMessage = chat['last_message'] ?? '';
          final unread = chat['unread_count'] ?? 0;
          final timestamp = chat['last_timestamp'] ?? '';
          final isOnline = chat['online'] ?? false;

          return ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                if (isOnline)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(radius: 5, backgroundColor: Colors.green),
                  ),
              ],
            ),
            title: Text(name),
            subtitle: Text(lastMessage),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (timestamp.isNotEmpty)
                  Text(
                    formattedTime(timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                if (unread > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    userId: chat['id'],
                    username: name,
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
