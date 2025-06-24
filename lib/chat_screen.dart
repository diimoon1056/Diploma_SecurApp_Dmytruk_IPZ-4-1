import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String username;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = const FlutterSecureStorage();
  final _messageController = TextEditingController();
  List<dynamic> messages = [];
  String? _statusText;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _loadMessages();
    _loadStatus();
    _loadDisplayName();
    Timer.periodic(const Duration(seconds: 30), (_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.114:5000/status/${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['online'] == true) {
            _statusText = 'у мережі';
          } else if (data['last_seen'] != null) {
            final lastSeen = DateTime.parse(data['last_seen']).toLocal();
            final diff = DateTime.now().difference(lastSeen);
            if (diff.inMinutes < 60) {
              _statusText = 'був у мережі ${diff.inMinutes} хв тому';
            } else if (diff.inHours < 24) {
              _statusText = 'був у мережі ${diff.inHours} год тому';
            } else {
              _statusText = 'був у мережі ${diff.inDays} дн тому';
            }
          } else {
            _statusText = 'недоступно';
          }
        });
      }
    } catch (e) {
      print('Помилка статусу: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;
    await http.put(
      Uri.parse('http://192.168.1.114:5000/message/read?sender_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> _loadDisplayName() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;
    final response = await http.get(
      Uri.parse('http://192.168.1.114:5000/profile/${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _displayName = (data['display_name']?.toString().trim().isNotEmpty ?? false)
            ? data['display_name']
            : (data['username'] ?? 'Без імені');
      });
    }
  }

  Future<void> _loadMessages() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;

    final url = Uri.parse('http://192.168.1.114:5000/message?receiver_id=${widget.userId}');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        messages = data['messages'];
      });
    } else {
      print('Помилка завантаження: ${response.body}');
    }
  }

  Future<void> _sendMessage() async {
    final token = await _storage.read(key: 'token');
    final content = _messageController.text.trim();
    if (token == null || content.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://192.168.1.114:5000/message'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'receiver_id': widget.userId,
        'message': content,
      }),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      _loadMessages();
    } else {
      print('Помилка надсилання: ${response.body}');
    }
  }

  String formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat.Hm().format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_displayName ?? widget.username),
            if (_statusText != null)
              Row(
                children: [
                  Text(
                    _statusText!,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (_statusText == 'у мережі')
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.circle, color: Colors.green, size: 10),
                    ),
                ],
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[messages.length - index - 1];
                final fromMe = msg['from_me'] == true;
                final isRead = msg['read'] == true;
                final time = formatTime(msg['timestamp'] ?? '');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fromMe ? Colors.blueAccent : Colors.grey[800],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: fromMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: fromMe ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['message'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                                ),
                                if (fromMe && isRead)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Напишіть повідомлення...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
