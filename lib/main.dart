import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'splash_screen.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Студент прописывает свой URL и anonKey
  await Supabase.initialize(
    url: 'https://nxsmdxakrnzhbdwiwuas.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54c21keGFrcm56aGJkd2l3dWFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MzQ4NzYsImV4cCI6MjA4MzAxMDg3Nn0.jSUsvUZBOWLUUty86fAnVbXMeTiMwJvdzHoM1k01RCk',
  );

  print('Supabase initialized: ${Supabase.instance.client.auth.currentSession}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        nextScreen: const HomeScreen(),
      ),
    );
  }
}
