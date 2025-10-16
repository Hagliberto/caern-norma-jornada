import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; 
import '../core/app_state.dart'; 
import 'chapter_expander.dart';

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
    buffer.write('-----------------------------------------------------\n');

    for (var content in selectedContent) {
      buffer.write('\n[${content.type}] *Ref: ${content.reference}*\n');
      buffer.write('${content.content}\n');
      buffer.write('-----------------------------------------------------\n');
    }
    
    final String textToShare = buffer.toString();
    
    try {
      await Share.share(textToShare);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tentar compartilhar nativamente: $e')),
      );
    }
    
    Provider.of<AppState>(context, listen: false).clearSelection();
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final chapters = appState.rawChapters; 

    // Define o conteúdo não-lista (indicador de carregamento/erro/vazio)
    Widget nonListContent;
    if (appState.isLoading) {
      nonListContent = const Center(child: CircularProgressIndicator());
    } else if (appState.error != null) {
      nonListContent = Center(
          child: Text(
            'Erro ao carregar a norma:\n${appState.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        );
    } else if (chapters.isEmpty) {
      nonListContent = const Center(child: Text('Nenhum conteúdo encontrado.'));
    } else {
      nonListContent = const SizedBox.shrink(); 
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar Dinâmica (SliverAppBar)
          SliverAppBar(
            pinned: true,
            expandedHeight: appState.isSelecting ? 100.0 : 60.0,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: appState.isSelecting
                ? const Text('Modo de Seleção', style: TextStyle(fontWeight: FontWeight.bold))
                : const Text('Norma – Jornada e Frequência', style: TextStyle(fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
               titlePadding: EdgeInsets.zero,
               centerTitle: true,
               title: appState.isSelecting
                   ? Container(
                       alignment: Alignment.bottomCenter,
                       padding: const EdgeInsets.only(bottom: 15),
                       child: Text('Selecionados: ${appState.selectedContentIds.length}',
                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     )
                   : null,
            ),
            leading: appState.isSelecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: appState.clearSelection,
                )
              : null,
            actions: [
              if (appState.isSelecting)
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _shareBatchContent(context, appState.selectedContent),
                  tooltip: 'Compartilhar em Lote',
                )
            ],
          ),
          
          // Renderiza o conteúdo (Capítulos ou Mensagem)
          if (chapters.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = chapters[index];
                  
                  return Column(
                      children: [
                        if (index > 0)
                          Divider(
                            color: Colors.indigo.shade200,
                            thickness: 1.2,
                            height: 24,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          // CORREÇÃO: IChapterExpander -> ChapterExpander
                          child: ChapterExpander(chapter: chapter), 
                        ),
                      ],
                    );
                },
                childCount: chapters.length,
              ),
            )
          else
            // Se não houver capítulos (carregando/erro/vazio), usa SliverFillRemaining
            SliverFillRemaining(
              hasScrollBody: false,
              child: nonListContent,
            ),
        ],
      ),
    );
  }
}