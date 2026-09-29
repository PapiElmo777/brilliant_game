import 'package:flutter/material.dart';

class BrilliantGameApp extends StatelessWidget {
  const BrilliantGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Brilliant Game',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SafeArea(child: Center(child: Text('BRILLIANT')))),
    );
  }
}
