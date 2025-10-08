import 'package:flutter/material.dart';

class DiscordPage extends StatelessWidget {
  const DiscordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'TODO : Add discord gateway websocket',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
