
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const WhiteApp());
}

class WhiteApp extends StatelessWidget {
  const WhiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  Map<String, String> _responses = {};

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('responses');
    if (data != null) {
      setState(() {
        _responses = Map<String, String>.from(json.decode(data));
      });
    }
  }

  Future<void> _saveResponses() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('responses', json.encode(_responses));
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      final key = text.toLowerCase();
      final reply = _responses[key] ?? 'Desculpe, não entendi.';
      _messages.add({'sender': 'bot', 'text': reply});
    });
    _controller.clear();
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen(responses: _responses, onSave: (map) {
        _responses = map;
        _saveResponses();
      })),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('White Chat'),
        actions: [IconButton(onPressed: _goToSettings, icon: const Icon(Icons.settings))],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Digite sua mensagem...'),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Map<String, String> responses;
  final ValueChanged<Map<String, String>> onSave;
  const SettingsScreen({required this.responses, required this.onSave, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_passwordController.text == '123456') {
                    setState(() => _authenticated = true);
                  }
                },
                child: const Text('Entrar'),
              )
            ],
          ),
        ),
      );
    }
    final controllers = widget.responses.map((k, v) => MapEntry(k, TextEditingController(text: v)));
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Respostas')),
      body: ListView(
        children: [
          ...controllers.entries.map((e) => ListTile(
                title: Text(e.key),
                subtitle: TextField(controller: e.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => widget.responses.remove(e.key));
                    widget.onSave(widget.responses);
                  },
                ),
              )),
          ListTile(
            title: const Text('Adicionar nova'),
            leading: const Icon(Icons.add),
            onTap: () {
              String key = '';
              String value = '';
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Nova Resposta'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: 'Palavra-chave'),
                        onChanged: (t) => key = t.toLowerCase(),
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Resposta'),
                        onChanged: (t) => value = t,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (key.isNotEmpty) {
                          setState(() => widget.responses[key] = value);
                          widget.onSave(widget.responses);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
