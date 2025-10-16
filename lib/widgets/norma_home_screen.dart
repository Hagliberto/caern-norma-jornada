// [widgets/norma_home_screen.dart] 

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'norma_screen.dart'; 
import 'search_screen.dart'; 
import 'favorites_screen.dart'; 

class NormaHomeScreen extends StatefulWidget {
  const NormaHomeScreen({super.key});

  @override
  State<NormaHomeScreen> createState() => _NormaHomeScreenState();
}

class _NormaHomeScreenState extends State<NormaHomeScreen> {
  // 0: Norma (Capítulos), 1: Favoritos, 2: Busca
  int _selectedIndex = 0; 
  
  final List<Widget> _screens = [
    const NormaScreen(), 
    const FavoritesScreen(), 
    const SearchScreen(),
  ];
  
  // NOVO: Listener para forçar a mudança de aba quando um item for focado
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    // Se há um item para focar E não estamos na aba de Norma, navega para a aba de Norma (índice 0)
    if (appState.contentToFocus != null && _selectedIndex != 0) {
      // Usamos WidgetsBinding.instance.addPostFrameCallback para evitar
      // chamar setState durante o ciclo de build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedIndex = 0; 
        });
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      // Sempre que trocar de aba, limpa o foco para não manter o estado
      Provider.of<AppState>(context, listen: false).setContentToFocus(null); 
      
      if (index == 2) {
         Provider.of<AppState>(context, listen: false).setQuery('');
      }
      
      if (Provider.of<AppState>(context, listen: false).isSelecting) {
        Provider.of<AppState>(context, listen: false).clearSelection();
      }
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Norma',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}