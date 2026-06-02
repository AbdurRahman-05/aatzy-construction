import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Provider ${index + 1}'),
            subtitle: const Text('Sure, we can start next week.'),
            trailing: const Text('10:42 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(name: 'Provider ${index + 1}')));
            },
          );
        },
      ),
    );
  }
}
