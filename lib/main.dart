// [main.dart]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'core/app_state.dart'; 
import 'widgets/splash_screen.dart'; // NOVO: Importa a tela de abertura

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const NormaApp(),
    ),
  );
}

class NormaApp extends StatelessWidget {
  const NormaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Norma – Jornada e Frequência',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.amber,
          surface: Colors.grey.shade50,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // CORREÇÃO: Usa a SplashScreen como tela inicial
      home: const SplashScreen(), 
    );
  }
}