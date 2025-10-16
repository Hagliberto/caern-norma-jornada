import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../core/app_state.dart';
import 'content_tile.dart'; 

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  // Exibe o conteúdo completo em um diálogo (Reutiliza a lógica do FavoritesScreen)
  void _showFullContentDialog(BuildContext context, NormaContent content) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(content.reference),
          content: SingleChildScrollView(
            child: Text(
              content.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          actions: <Widget>[
            // Ação de Compartilhamento no Diálogo
            IconButton( 
              icon: const Icon(Icons.share, color: Colors.indigo),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                final String textToShare = 
                    '*Norma – Jornada e Frequência CAERN*\n\n*Referência:* ${content.reference}\n\n${content.content}';
                
                // CORREÇÃO WHATSAPP: Usa Uri.encodeQueryComponent
                final String encodedText = Uri.encodeQueryComponent(textToShare);
                final whatsappUrl = Uri.parse('whatsapp://send?text=$encodedText');
                
                launchUrl(whatsappUrl, mode: LaunchMode.externalApplication).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao tentar compartilhar: $e')),
                  );
                });
              },
              tooltip: 'Compartilhar via WhatsApp',
            ),
            // Ação de Favoritar (Reativo)
            Consumer<AppState>( 
              builder: (context, appState, child) {
                final isFav = appState.isFavorite(content.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => appState.toggleFavorite(content),
                  tooltip: isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final results = appState.filteredContent;
    final bool isSearching = appState.query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: appState.setQuery,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar na norma...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          if (isSearching) 
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => appState.setQuery(''),
              tooltip: 'Limpar Busca',
            ),
        ],
      ),
      body: !isSearching 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Digite para buscar artigos, parágrafos ou itens.'),
                ],
              ),
            )
          : results.isEmpty
            ? const Center(child: Text('Nenhum resultado encontrado.'))
            : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final content = results[index];
                  return ContentTile(
                    content: content,
                    // Não é selecionável, mas permite clique para ver o conteúdo completo
                    onTap: () => _showFullContentDialog(context, content),
                  );
                },
              ),
    );
  }
}