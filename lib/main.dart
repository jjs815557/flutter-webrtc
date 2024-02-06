import 'package:flutter/material.dart';
import 'package:qrcode_phone/screens/receiver.first.screen.dart';
import 'package:qrcode_phone/screens/callscreen.dart';
import 'package:qrcode_phone/screens/caller.screen.dart';
import 'package:qrcode_phone/screens/receiver.second.screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ReceiverFirstScreen(),
    );
  }
}
