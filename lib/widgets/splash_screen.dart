import 'package:flutter/material.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart'; // NOVO
import 'norma_home_screen.dart'; // Importa a tela principal

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  
  // NOVO: Variável para armazenar as informações do pacote
  late Future<PackageInfo> _packageInfoFuture;
  
  @override
  void initState() {
    super.initState();
    
    // 1. Carrega as informações do pacote
    _packageInfoFuture = PackageInfo.fromPlatform();
    
    // Configuração da animação (opacidade/fade-in)
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Duração total da animação
      vsync: this,
    );
    
    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    // Inicia a animação
    _controller.forward();
    
    // Navega para a tela principal após um atraso (ex: 3 segundos no total)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NormaHomeScreen()),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // NOVO: Widget para construir o conteúdo da versão
  Widget _buildVersionInfo(AsyncSnapshot<PackageInfo> snapshot) {
    String versionText = '';
    if (snapshot.hasData) {
      // Obtém a versão completa (version + buildNumber)
      final String version = snapshot.data!.version;
      final String buildNumber = snapshot.data!.buildNumber;
      versionText = 'Versão: $version+$buildNumber'; 
    }
    
    return Column(
      children: [
        const SizedBox(height: 100), 
        
        // Versão da Aplicação
        Text(
          versionText,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 30), // Espaçamento entre a versão e o desenvolvedor

        // Desenvolvedor da Aplicação
        const Text(
          'Desenvolvido por:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hagliberto Alves de Oliveira',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo, 
      body: Center(
        child: FadeTransition( 
          opacity: _opacityAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Imagem de Abertura
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset('assets/image.png', fit: BoxFit.contain), 
              ),
              const SizedBox(height: 30),
              
              // 2. Título
              const Text(
                'Jornadas e Frequências',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // 3. NOVO: FutureBuilder para exibir a versão
              FutureBuilder<PackageInfo>(
                future: _packageInfoFuture,
                builder: (context, snapshot) {
                  return _buildVersionInfo(snapshot);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}