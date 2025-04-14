// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MindWaveApp());

class MindWaveApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindWave',
      theme: ThemeData.light(),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const platform = MethodChannel('mindwave_channel');

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isProcessing = false;

  Future<void> _sendMessage({required bool deepThink, required bool webSearch}) async {
    String prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // Формирование истории диалога в виде строки, где каждая строка: "sender: message"
    String history = _messages.map((m) => "${m['sender']}: ${m['text']}").join("\n");

    setState(() {
      _messages.add({'sender': 'user', 'text': prompt});
      _controller.clear();
      _isProcessing = true;
      _messages.add({
        'sender': 'ai',
        'text': deepThink
            ? 'Размышляет...'
            : webSearch
                ? 'Поиск веб-страниц...'
                : ''
      });
    });

    String method = deepThink ? 'deepThink' : 'webSearch';

    try {
      // Передаём и prompt, и историю диалога для глубокого мышления
      final args = deepThink ? {'prompt': prompt, 'history': history} : {'prompt': prompt};
      String response = await platform.invokeMethod(method, args);
      
      setState(() {
        _isProcessing = false;
        _messages.removeLast(); // удаляем временную запись (статус)
        _messages.add({'sender': 'ai', 'text': response});
      });
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _messages.removeLast();
        _messages.add({'sender': 'ai', 'text': "Ошибка: ${e.message}"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MindWave'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['sender'] == 'user';
                return Container(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    _messages[index]['text'] ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Чем могу помочь сегодня?',
                    ),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.lightbulb_outline),
                      tooltip: 'Глубокое мышление',
                      onPressed: _isProcessing
                          ? null
                          : () => _sendMessage(deepThink: true, webSearch: false),
                    ),
                    IconButton(
                      icon: Icon(Icons.public),
                      tooltip: 'Веб-поиск',
                      onPressed: _isProcessing
                          ? null
                          : () => _sendMessage(deepThink: false, webSearch: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
