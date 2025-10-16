// [core/app_state.dart]

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// (NormaContent class mantida)
class NormaContent {
  final String id;
  final String content;
  final String reference; // Ex: "CAP. I - Art. 1º"
  final String type;      // Para identificar se é "Capítulo", "Artigo", "Parágrafo", etc.
  
  Map<String, dynamic> toJson() => {'id': id, 'content': content, 'reference': reference, 'type': type};
  factory NormaContent.fromJson(Map<String, dynamic> json) => 
    NormaContent(id: json['id'] as String, content: json['content'] as String, reference: json['reference'] as String, type: json['type'] as String);

  NormaContent({required this.id, required this.content, required this.reference, required this.type});
}

// Classe de gerenciamento de estado
class AppState extends ChangeNotifier {
  List<dynamic> _rawChapters = []; 
  List<dynamic> get rawChapters => _rawChapters; 

  List<NormaContent> _allContent = [];
  List<NormaContent> get allContent => _allContent; 
  
  // NOVO: Estado para focar em um item na NormaScreen após navegação
  NormaContent? _contentToFocus;
  NormaContent? get contentToFocus => _contentToFocus;
  
  void setContentToFocus(NormaContent? content) {
    _contentToFocus = content;
    notifyListeners();
  }

// --- Multi-Select ---
  final List<String> _selectedContentIds = [];
  List<String> get selectedContentIds => _selectedContentIds;
  
  List<NormaContent> get selectedContent {
    return _allContent.where((c) => _selectedContentIds.contains(c.id)).toList();
  }
  
  bool get isSelecting => _selectedContentIds.isNotEmpty;

  // --- Favoritos ---
  final List<String> _favoriteIds = [];
  List<NormaContent> get favorites {
    return _allContent.where((c) => _favoriteIds.contains(c.id)).toList();
  }
  
  bool isFavorite(String contentId) => _favoriteIds.contains(contentId);

  // --- Busca ---
  String _query = '';
  String get query => _query;

  List<NormaContent> get filteredContent {
    if (_query.isEmpty) {
      return [];
    }
    return _allContent
        .where((c) => c.content.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }
  
  // --- Estado da Aplicação ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // Inicialização e Carga de Dados
  Future<void> loadFromAssets() async {
    if (_rawChapters.isNotEmpty && _error == null) return; 

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await rootBundle.loadString('assets/norma_data_completa.json');
      _rawChapters = jsonDecode(raw) as List<dynamic>;
      
      _allContent = _extractAllContent(_rawChapters);
      
      await _loadFavorites();
      
    } catch (e) {
      _error = 'Falha ao carregar dados: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Novo método de extração, adicionando 'type'
  List<NormaContent> _extractAllContent(List<dynamic> chapters) {
    final List<NormaContent> list = [];
    int contentCounter = 0; 
    
    for (var chapter in chapters) {
      final String chapTitle = chapter['chapter'];
      final String chapId = (contentCounter++).toString();
      
      list.add(NormaContent(
          id: chapId,
          content: chapter['title'] ?? '',
          reference: chapTitle,
          type: 'Capítulo')); 

      void processArticles(List<dynamic> articles, String currentRef) {
        for (var art in articles) {
          final String artText = art['text'];
          final String baseRef = '$currentRef - $artText';
          final String artId = (contentCounter++).toString();

          if (art['content'] != null) {
            list.add(NormaContent(
                id: artId,
                content: art['content'],
                reference: baseRef,
                type: 'Artigo'));
          }

          if (art['items'] != null) {
            for (var item in art['items']) {
              final String itemRef = '$baseRef - ${item['index']}';
              if (item['sub_items'] != null) {
                for (var sub in item['sub_items']) {
                  list.add(NormaContent(
                      id: (contentCounter++).toString(),
                      content: sub['definition'],
                      reference: '$itemRef - ${sub['index']}',
                      type: 'Sub-Item'));
                }
              } else {
                list.add(NormaContent(
                    id: (contentCounter++).toString(),
                    content: item['definition'] ?? item['content'] ?? '',
                    reference: itemRef,
                    type: 'Item'));
              }
            }
          }

          if (art['paragraphs'] != null) {
            for (var p in art['paragraphs']) {
              final String pRef = '$baseRef - ${p['index']}';
              list.add(NormaContent(
                  id: (contentCounter++).toString(),
                  content: p['content'],
                  reference: pRef,
                  type: 'Parágrafo'));
            }
          }
        }
      }

      if (chapter['articles'] != null) {
        processArticles(chapter['articles'], chapTitle);
      }
      
      if (chapter['sections'] != null) {
        for (var section in chapter['sections']) {
          final String sectionRef = '$chapTitle - ${section['text']}';
          if (section['articles'] != null) {
            processArticles(section['articles'], sectionRef);
          }
        }
      }
    }
    return list;
  }
  
  // NOVO: Função para buscar o conteúdo hierárquico para compartilhamento (Swipe)
  List<NormaContent> findHierarchicalContent(String baseReference, String type) {
    if (type == 'Parágrafo' || type == 'Item' || type == 'Sub-Item' || baseReference.isEmpty) {
      try {
        final content = _allContent.firstWhere((c) => c.reference == baseReference);
        return [content];
      } catch (_) {
        return [];
      }
    }
    
    return _allContent.where((c) {
      return c.reference.startsWith(baseReference);
    }).toList();
  }

  // --- Gerenciamento de Seleção em Lote ---
  void toggleSelection(String id) {
    if (_selectedContentIds.contains(id)) {
      _selectedContentIds.remove(id);
    } else {
      _selectedContentIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedContentIds.clear();
    notifyListeners();
  }

  // --- Gerenciamento de Favoritos ---

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favoriteContentIds');
    _favoriteIds.clear();
    if (favs != null) {
      _favoriteIds.addAll(favs);
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteContentIds', _favoriteIds);
  }

  // Favoritar agora usa o clique duplo
  void toggleFavorite(NormaContent content) {
    if (_favoriteIds.contains(content.id)) {
      _favoriteIds.remove(content.id);
    } else {
      _favoriteIds.add(content.id);
    }
    _saveFavorites();
    notifyListeners();
  }
  
  // NOVO: Função para limpar todos os favoritos
  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    await _saveFavorites();
    notifyListeners();
  }
  
  void setQuery(String q) {
    _query = q.trim();
    notifyListeners();
  }
}