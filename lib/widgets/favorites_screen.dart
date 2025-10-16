// [widgets/favorites_screen.dart]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_state.dart';
import 'content_tile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<String> _selectedFavIds = [];

  // Reutiliza a função de compartilhamento hierárquico para o Dismissible
  void _shareContent(BuildContext context, NormaContent content) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Busca todo o conteúdo abaixo do nó atual (hierárquico)
    final contentList =
        appState.findHierarchicalContent(content.reference, content.type);

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

  void _toggleFavSelection(String id) {
    setState(() {
      if (_selectedFavIds.contains(id)) {
        _selectedFavIds.remove(id);
      } else {
        _selectedFavIds.add(id);
      }
    });
  }

  void _clearFavSelection() {
    setState(() {
      _selectedFavIds.clear();
    });
  }

  // Lógica de compartilhamento em lote
  void _shareBatchFavorites(
      BuildContext context, List<NormaContent> contentList) async {
    if (contentList.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    buffer.write('*Norma – Jornada e Frequência CAERN*\n\n');
    buffer.write(
        '--- Conteúdo Favorito Selecionado (${contentList.length} itens) ---\n');
    buffer.write('-----------------------------------------------------\n');

    for (var content in contentList) {
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

    _clearFavSelection();
  }

  // Diálogo de confirmação para limpar todos os favoritos
  Future<void> _confirmClearFavorites(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Limpar Todos os Favoritos?'),
          content: const Text(
              'Tem certeza de que deseja remover todos os itens da sua lista de favoritos?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await appState.clearAllFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os favoritos foram limpos.')),
      );
    }
  }

  // Lógica de compartilhamento de item único (URL)
  void _shareSingleContentUrl(
      BuildContext shareContext, NormaContent content) async {
    final String textToShare =
        '*Norma – Jornada e Frequência CAERN*\n\n*Referência:* ${content.reference}\n\n${content.content}';

    final String encodedText = Uri.encodeQueryComponent(textToShare);
    final whatsappUrl = Uri.parse('whatsapp://send?text=$encodedText');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(shareContext).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(shareContext).showSnackBar(
        SnackBar(content: Text('Erro ao tentar compartilhar: $e')),
      );
    }
  }

  // Diálogo de Opções (Clique Longo)
  void _showOptionsDialog(
      BuildContext context, NormaContent content, AppState appState) {
    final isFav = appState.isFavorite(content.id);

    // CORREÇÃO: Usamos showModalBottomSheet, que abre na parte inferior.
    // O problema visual que você está descrevendo é geralmente causado por
    // Widgets que não ocupam espaço suficiente ou por um tema que interage
    // mal com as áreas de segurança do dispositivo (insets).
    showModalBottomSheet(
      context: context,
      // Garante que o modal se ajuste à área de visualização e evite conflito com teclados/barras de navegação.
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return SingleChildScrollView(
          // Envolve em SingleChildScrollView
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
                title: const Text('Compartilhar (Item Único)'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _shareSingleContentUrl(context, content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.indigo),
                title: const Text('Compartilhar (Conteúdo Hierárquico)'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _shareContent(
                      context, content); // Usa a lógica hierárquica nativa
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.indigo),
                title: const Text('Ver na Norma (Navegar)'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  appState.setContentToFocus(content); // Define o foco
                  // O NormaHomeScreen fará a navegação
                },
              ),
              // Botão de fechar para garantir acessibilidade
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                    top: 10),
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final favorites = appState.favorites;
    final bool isSelectingFav = _selectedFavIds.isNotEmpty;

    final selectedFavContent =
        favorites.where((f) => _selectedFavIds.contains(f.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: isSelectingFav
            ? Text('Compartilhar: ${selectedFavContent.length} itens',
                style: const TextStyle(fontWeight: FontWeight.bold))
            : const Text('Conteúdo Favorito',
                style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: isSelectingFav
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearFavSelection,
              )
            : null,
        actions: [
          if (isSelectingFav)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () =>
                  _shareBatchFavorites(context, selectedFavContent),
              tooltip: 'Compartilhar Selecionados',
            )
          else if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () => _confirmClearFavorites(context),
              tooltip: 'Limpar Todos os Favoritos',
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Você ainda não adicionou nenhum favorito.'),
                  SizedBox(height: 5),
                  Text(
                      'Use o clique duplo ou o menu de ações na tela "Norma".'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final content = favorites[index];
                final isSelected = _selectedFavIds.contains(content.id);

                return Dismissible(
                  key: ValueKey(content.id),
                  direction: isSelectingFav
                      ? DismissDirection.none
                      : DismissDirection.horizontal,

                  // Fundo (Deslize para a direita: Compartilhar)
                  background: Container(
                    color: Colors.lightBlue,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.share, color: Colors.white),
                  ),
                  // Segundo Fundo (Deslize para a esquerda: Excluir)
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),

                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // Deslize para a direita (Compartilhar)
                      _shareContent(context, content);
                      return false; // Não remove o item
                    } else if (direction == DismissDirection.endToStart) {
                      // Deslize para a esquerda (Excluir)
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Remover Favorito?'),
                            content: Text(
                                'Deseja remover "${content.reference}" dos favoritos?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Remover'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirm == true) {
                        appState.toggleFavorite(content);
                      }
                      return false; // Sempre retorna false para o dismiss não animar, a remoção é feita via toggleFavorite.
                    }
                    return false;
                  },

                  child: ContentTile(
                    content: content,
                    isSelectable: true,
                    isSelected: isSelected,
                    // CLIQUE LONGO: Alterna seleção em lote OU abre opções
                    onLongPress: isSelectingFav
                        ? () => _toggleFavSelection(content.id)
                        : () => _showOptionsDialog(context, content, appState),
                    // CLIQUE CURTO: Alterna seleção em lote OU navega para a Norma
                    onTap: isSelectingFav
                        ? () => _toggleFavSelection(content.id)
                        : () => appState.setContentToFocus(
                            content), // Define o item para focar
                  ),
                );
              },
            ),
    );
  }
}
