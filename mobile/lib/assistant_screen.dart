import 'package:flutter/material.dart';
import 'api_client.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final messages = <Map<String, String>>[];
  bool busy = false;
  String? error;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (busy || text.isEmpty) return;
    setState(() {
      messages.add({'role': 'user', 'content': text});
      busy = true;
      error = null;
      input.clear();
    });
    try {
      final start = messages.length > 7 ? messages.length - 7 : 0;
      final reply = await widget.api.askAssistant(messages.sublist(start));
      if (!mounted) return;
      setState(() => messages.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ask ResQ')),
        body: SafeArea(
            child: Column(children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Animal care and app guidance • AI can make mistakes. For urgent care, contact a veterinarian. Messages are sent to OpenAI; leave out personal details.',
              )),
          Expanded(
              child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            itemBuilder: (_, i) => Align(
              alignment: messages[i]['role'] == 'user'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: SelectableText(messages[i]['content']!))),
            ),
          )),
          if (busy)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets),
                    SizedBox(width: 10),
                    Text('ResQ is fetching a little help…')
                  ],
                )),
          if (error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(error!, style: const TextStyle(color: Colors.red))),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                  controller: input,
                  maxLength: 1500,
                  minLines: 1,
                  maxLines: 3,
                  enabled: !busy,
                  decoration: const InputDecoration(
                      hintText: 'How can I help your animal?'),
                )),
                IconButton(
                    tooltip: 'Send message',
                    onPressed: busy ? null : send,
                    icon: const Icon(Icons.send_rounded)),
              ])),
        ])),
      );
}
