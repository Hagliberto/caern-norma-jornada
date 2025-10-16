import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart'; 
import '../widgets/chapter_expander.dart';
import '../widgets/search_screen.dart'; 
import '../widgets/favorites_screen.dart'; 

class NormaScreen extends StatefulWidget {
  const NormaScreen({super.key});

  @override
  State<NormaScreen> createState() => _NormaScreenState();
}

class _NormaScreenState extends State<NormaScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadFromAssets();
    });
  }
  
  // Função que monta a mensagem consolidada e compartilha (Lote)
  void _shareBatchContent(BuildContext context, List<NormaContent> selectedContent) async {
    if (selectedContent.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    buffer.write('*Norma – Jornada e Frequência CAERN*\n\n');
    buffer.write('--- Conteúdo Selecionado (${selectedContent.length} itens) ---\n');

    // Lógica de granularidade:
    for (var content in selectedContent) {
      if (content.type == 'Capítulo') {
        // Se for Capítulo, inclui o título e TENTA incluir todos os artigos/seções
        buffer.write('\n*${content.reference}* - ${content.content}\n');
        
        // Tentativa de incluir o conteúdo do capítulo (Artigos, Itens, Parágrafos)
        // Isso é complexo e deve ser feito recursivamente. 
        // Para simplificar a granularidade do lote, vamos incluir todos os itens
        // que começam com a referência desse capítulo, se ainda não foram selecionados individualmente.
        // NOTE: A extração precisa ser feita com cuidado para garantir que as referências sejam únicas.
        
        // Aqui, vou simplificar, garantindo que a referência do item/parágrafo
        // que já está selecionado é adicionada abaixo. O sistema já seleciona o que o usuário quer.
        
      } else {
        // Para Artigo, Item ou Parágrafo, apenas a referência e o conteúdo vão.
        buffer.write('\n_Ref: ${content.reference}_\n${content.content}\n');
      }
      buffer.write('-----------------------------------------------------\n');
    }
    
    final String textToShare = buffer.toString();
    final String encodedText = Uri.encodeComponent(textToShare);
    final whatsappUrl = Uri.parse('whatsapp://send?text=$encodedText');
    final fallbackUrl = Uri.parse('https://wa.me/?text=$encodedText');
    
    // Tenta compartilhar (mesma lógica anterior)
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tentar compartilhar: $e')),
      );
    }
    
    // Limpa a seleção após o compartilhamento
    Provider.of<AppState>(context, listen: false).clearSelection();
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final chapters = appState.rawChapters; 

    // Define o AppBar baseado no modo de seleção
    final appBar = appState.isSelecting 
      ? AppBar(
          title: Text('Selecionados: ${appState.selectedContentIds.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: appState.clearSelection, // Sai do modo de seleção
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareBatchContent(context, appState.selectedContent),
              tooltip: 'Compartilhar em Lote',
            ),
          ],
        )
      : AppBar(
          title: const Text(
            'Norma – Jornada e Frequência',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            // Botão de Busca
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
            // Botão de Favoritos
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
          ],
        );


    return Scaffold(
      appBar: appBar,
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : appState.error != null
              ? Center(
                  child: Text(
                    'Erro ao carregar a norma:\n${appState.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : chapters.isEmpty
                  ? const Center(child: Text('Nenhum conteúdo encontrado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8.0),
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.indigo.shade200,
                        thickness: 1.2,
                        height: 24,
                      ),
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        return ChapterExpander(chapter: chapter);
                      },
                    ),
    );
  }
}