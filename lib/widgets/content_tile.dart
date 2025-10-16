// [widgets/content_tile.dart]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';

class ContentTile extends StatelessWidget {
  final NormaContent content;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;


  const ContentTile({
    super.key, 
    required this.content,
    this.isSelectable = false, 
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  // Função _shareContent (mantida mas não usada internamente)
  // ...

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isFav = appState.isFavorite(content.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Margem horizontal ajustada para o Dismissible
      elevation: 1,
      // Cor de seleção usando a cor primária do tema
      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white, 
      shape: isFav && !isSelectable
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1.5),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        // Clique duplo para alternar favorito - Útil em listas de busca/favoritos
        onDoubleTap: isSelectable ? null : () => appState.toggleFavorite(content),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha do Título e Checkbox de Seleção
              Row(
                children: [
                  Expanded(
                    child: Text(
                      content.reference,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ),
                  // Ícone de Favorito (em resultados de busca/norma)
                  if (!isSelectable && isFav)
                    const Padding(
                       padding: EdgeInsets.only(right: 8.0),
                       child: Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                  if (isSelectable) // Checkbox visível apenas se for selecionável (tela de favoritos)
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        if (onTap != null) onTap!();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Conteúdo (Texto do Artigo/Item/Parágrafo)
              Text(
                isSelectable 
                  ? (content.content.length > 150 ? '${content.content.substring(0, 150)}...' : content.content)
                  : (content.content.length > 250 ? '${content.content.substring(0, 250)}...' : content.content),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}