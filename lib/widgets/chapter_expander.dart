import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_state.dart';

class ChapterExpander extends StatelessWidget {
  final Map<String, dynamic> chapter;

  const ChapterExpander({super.key, required this.chapter});

  // Função para Compartilhamento (Item Único, Hierárquico)
  void _shareContent(BuildContext context, String reference, String content,
      String type) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // ... (Lógica de montagem do buffer mantida)
    final contentList = appState.findHierarchicalContent(reference, type);

    if (contentList.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    buffer.write('*Norma – Jornada e Frequência CAERN*\n\n');
    buffer.write('--- Seção Compartilhada (${contentList.length} itens) ---\n');
    buffer.write('-----------------------------------------------------\n');

    for (var item in contentList) {
      buffer.write('\n[${item.type}] *Ref: ${item.reference}*\n');
      buffer.write('${item.content}\n');
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
  }

  // Função que encontra um item no estado global para favoritar/selecionar
  NormaContent? _findNormaContent(
      BuildContext context, String reference, String content) {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      return appState.allContent.firstWhere(
        (c) => c.reference == reference && c.content == content,
        orElse: () => throw Exception(),
      );
    } catch (_) {
      return null;
    }
  }

  // NOVO: Exibe o conteúdo completo e permite compartilhar
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
            IconButton(
              // Botão de Compartilhar no Diálogo
              icon: const Icon(Icons.share, color: Colors.indigo),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _shareContent(
                    context, content.reference, content.content, content.type);
              },
              tooltip: 'Compartilhar',
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

  // NOVO: Menu de Ações no Artigo/Capítulo (Abre no clique longo)
// NOVO: Menu de Ações no Artigo/Capítulo (Abre no clique longo)
  void _showActionMenu(BuildContext context, NormaContent content) {
    final appState = Provider.of<AppState>(context, listen: false);
    final bool isFav = appState.isFavorite(content.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para permitir o ajuste de altura
      builder: (BuildContext dialogContext) {
        // CORREÇÃO APLICADA: Usar Padding para garantir espaço para a barra de navegação do sistema
        return SingleChildScrollView(
          child: Padding(
            // Adiciona padding na parte inferior igual ao bottom inset do sistema (barra de navegação/gestos)
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Título/Header opcional para o modal
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Ações para ${content.reference}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.indigo),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 1),

                // Itens do menu
                ListTile(
                  leading: Icon(isFav ? Icons.star_border : Icons.star,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(isFav
                      ? 'Remover dos Favoritos'
                      : 'Adicionar aos Favoritos'),
                  onTap: () {
                    appState.toggleFavorite(content);
                    Navigator.pop(dialogContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.lightBlue),
                  title: const Text('Compartilhar (Conteúdo Hierárquico)'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _shareContent(context, content.reference, content.content,
                        content.type);
                  },
                ),
                // Item que estava sendo sobreposto
                ListTile(
                  leading: const Icon(Icons.select_all, color: Colors.indigo),
                  title: const Text('Iniciar Seleção em Lote'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    appState.toggleSelection(content.id);
                  },
                ),
                // Botão de fechar (opcional, mas bom para fechar)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final directArticles = chapter['articles'] ?? [];
    final sections = chapter['sections'] ?? [];
    final String chapTitle = chapter['chapter'];
    final String chapContent = chapter['title'] ?? '';

    final appState = Provider.of<AppState>(context);
    final chapNormaContent = _findNormaContent(context, chapTitle, chapContent);
    final bool isFavorite =
        chapNormaContent != null && appState.isFavorite(chapNormaContent.id);
    final bool isSelected = chapNormaContent != null &&
        appState.selectedContentIds.contains(chapNormaContent.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : (isFavorite
                  ? Border.all(
                      color: Theme.of(context).colorScheme.secondary, width: 2)
                  : null),
        ),
        child: InkWell(
          onDoubleTap: () {
            if (chapNormaContent != null) {
              appState.toggleFavorite(chapNormaContent);
            }
          },
          onLongPress: () {
            if (chapNormaContent != null) {
              appState.isSelecting
                  ? appState.toggleSelection(chapNormaContent.id)
                  : _showActionMenu(context, chapNormaContent);
            }
          },
          onTap: () {
            if (appState.isSelecting && chapNormaContent != null) {
              appState.toggleSelection(chapNormaContent.id);
            } else if (chapNormaContent != null) {
              _showFullContentDialog(context, chapNormaContent);
            }
          },
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(Icons.book,
                color: isFavorite ? Colors.amber : Colors.indigo),
            title: Text(
              '$chapTitle – $chapContent',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.5,
              ),
            ),
            trailing: appState.isSelecting
                ? Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      if (chapNormaContent != null) {
                        appState.toggleSelection(chapNormaContent.id);
                      }
                    },
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var art in directArticles) ...[
                      _buildArticleTile(context, art, chapTitle),
                      const SizedBox(height: 10),
                    ],
                    for (var section in sections)
                      _buildSection(context, section, chapTitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, Map<String, dynamic> section, String chapTitle) {
    final articles = section['articles'] ?? [];
    final String sectionRef = '$chapTitle - ${section['text']}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8, left: 4),
          child: Text(
            section['text'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: Colors.indigo.shade800,
            ),
          ),
        ),
        for (var art in articles) ...[
          _buildArticleTile(context, art, sectionRef),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildArticleTile(
      BuildContext context, Map<String, dynamic> article, String baseRef) {
    final items = article['items'] ?? [];
    final paragraphs = article['paragraphs'] ?? [];
    final String artText = article['text'] ?? '';
    final String artContent = article['content'] ?? '';
    final String artRef = '$baseRef - $artText';

    final appState = Provider.of<AppState>(context);
    final artNormaContent = _findNormaContent(context, artRef, artContent);
    final bool isFav =
        artNormaContent != null && appState.isFavorite(artNormaContent.id);
    final bool isSelected = artNormaContent != null &&
        appState.selectedContentIds.contains(artNormaContent.id);

    return Card(
      elevation: 1,
      color: isSelected ? Colors.lightBlue.shade50 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        // CORREÇÃO: Substitui .shade200 por .withOpacity para cores de ColorScheme
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)
            : (isFav
                ? BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.4),
                    width: 1.5)
                : BorderSide.none),
      ),
      child: InkWell(
        onDoubleTap: () {
          if (artNormaContent != null) {
            appState.toggleFavorite(artNormaContent);
          }
        },
        onLongPress: () {
          if (artNormaContent != null) {
            appState.isSelecting
                ? appState.toggleSelection(artNormaContent.id)
                : _showActionMenu(context, artNormaContent);
          }
        },
        onTap: () {
          if (appState.isSelecting && artNormaContent != null) {
            appState.toggleSelection(artNormaContent.id);
          } else if (artNormaContent != null && artContent.isNotEmpty) {
            _showFullContentDialog(context, artNormaContent);
          }
        },
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading:
              Icon(Icons.balance, color: isFav ? Colors.amber : Colors.indigo),
          title: Text(
            artText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: artContent.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    artContent,
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
                  ),
                )
              : null,
          trailing: appState.isSelecting
              ? Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    if (artNormaContent != null) {
                      appState.toggleSelection(artNormaContent.id);
                    }
                  },
                )
              : null,
          children: [
            if (items.isNotEmpty)
              _buildSectionList(
                  context, items, 'Itens', Icons.list_alt, artRef),
            if (paragraphs.isNotEmpty)
              _buildSectionList(context, paragraphs, 'Parágrafos',
                  Icons.format_align_left, artRef),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryWithActions(
      BuildContext context, dynamic entry, String baseRef) {
    final entryText = _formatEntry(entry);
    final String index =
        (entry is Map<String, dynamic> && entry.containsKey('index'))
            ? entry['index']
            : '';
    final String content = (entry is Map<String, dynamic>)
        ? entry['definition'] ?? entry['content'] ?? ''
        : entryText;
    final String itemRef = '$baseRef - $index';

    final appState = Provider.of<AppState>(context);
    final itemNormaContent = _findNormaContent(context, itemRef, content);
    final bool isSelected = itemNormaContent != null &&
        appState.selectedContentIds.contains(itemNormaContent.id);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              entryText,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
          if (appState.isSelecting)
            Checkbox(
              value: isSelected,
              onChanged: (val) {
                if (itemNormaContent != null) {
                  appState.toggleSelection(itemNormaContent.id);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionList(BuildContext context, List<dynamic> entries,
      String label, IconData icon, String baseRef) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.indigo.shade400),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var entry in entries)
            _buildEntryWithActions(context, entry, baseRef),
        ],
      ),
    );
  }

  String _formatEntry(dynamic entry) {
    if (entry is Map<String, dynamic>) {
      if (entry.containsKey('sub_items') && entry['sub_items'] is List) {
        final term = entry['term'] != null ? '${entry['term']}: ' : '';
        final index = entry['index'] != null ? '${entry['index']} - ' : '';

        final subItemsFormatted = (entry['sub_items'] as List)
            .map((sub) => _formatEntry(sub))
            .join('\n      ');

        return '$index$term\n    $subItemsFormatted';
      }

      final index = entry['index'] != null ? '${entry['index']} ' : '';
      final term = entry['term'] != null ? '${entry['term']}: ' : '';
      final def = entry['definition'] ?? entry['content'] ?? '';
      return '$index$term$def';
    }
    return entry.toString();
  }
}
