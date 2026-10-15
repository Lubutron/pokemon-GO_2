import 'package:flutter/material.dart';

import 'screens/pokemon_catalog_page.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF20243A);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5B55),
          surface: const Color(0xFFF6F7FB),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F7FB),
          foregroundColor: ink,
        ),
      ),
      home: const PokemonCatalogPage(),
    );
  }
}
