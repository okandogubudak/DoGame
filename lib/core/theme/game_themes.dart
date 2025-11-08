import 'package:flutter/material.dart';

class GameTheme {
  final String name;
  final String id;
  final Color primary;
  final Color secondary;
  final Color ballColor;
  final Color obstacleColor;
  final Color targetColor;
  final LinearGradient backgroundGradient;
  final String? backgroundImage;
  
  const GameTheme({
    required this.name,
    required this.id,
    required this.primary,
    required this.secondary,
    required this.ballColor,
    required this.obstacleColor,
    required this.targetColor,
    required this.backgroundGradient,
    this.backgroundImage,
  });
}

class GameThemes {
  static const GameTheme neon = GameTheme(
    name: 'Neon Nights',
    id: 'neon',
    primary: Color(0xFF6C63FF),
    secondary: Color(0xFFFF6B9D),
    ballColor: Color(0xFFFFD700),
    obstacleColor: Color(0xFFFF6B9D),
    targetColor: Color(0xFF4ECDC4),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A1A2E),
        Color(0xFF16213E),
        Color(0xFF0F3460),
      ],
    ),
  );
  
  static const GameTheme sunset = GameTheme(
    name: 'Sunset Vibes',
    id: 'sunset',
    primary: Color(0xFFFF6B6B),
    secondary: Color(0xFFFECA57),
    ballColor: Color(0xFFFFFFFF),
    obstacleColor: Color(0xFFEE5A6F),
    targetColor: Color(0xFFFECA57),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF6B6B),
        Color(0xFFFECA57),
        Color(0xFFFF9FF3),
      ],
    ),
  );
  
  static const GameTheme ocean = GameTheme(
    name: 'Ocean Deep',
    id: 'ocean',
    primary: Color(0xFF0ABDE3),
    secondary: Color(0xFF00D2D3),
    ballColor: Color(0xFFFFFFFF),
    obstacleColor: Color(0xFF2E86DE),
    targetColor: Color(0xFF48DBFB),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0C2461),
        Color(0xFF1B1464),
        Color(0xFF2E86DE),
      ],
    ),
  );
  
  static const GameTheme forest = GameTheme(
    name: 'Forest',
    id: 'forest',
    primary: Color(0xFF26DE81),
    secondary: Color(0xFF20BF6B),
    ballColor: Color(0xFFFFD700),
    obstacleColor: Color(0xFF4B6584),
    targetColor: Color(0xFF26DE81),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0C4B33),
        Color(0xFF196F3D),
        Color(0xFF239B56),
      ],
    ),
  );
  
  static const GameTheme space = GameTheme(
    name: 'Space',
    id: 'space',
    primary: Color(0xFF7F00FF),
    secondary: Color(0xFFE100FF),
    ballColor: Color(0xFFFFFFFF),
    obstacleColor: Color(0xFF7F00FF),
    targetColor: Color(0xFF00D9FF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF000000),
        Color(0xFF1A1A3E),
        Color(0xFF2E2E5F),
      ],
    ),
  );
  
  static const List<GameTheme> all = [neon, sunset, ocean, forest, space];
  
  static GameTheme getById(String id) {
    return all.firstWhere((theme) => theme.id == id, orElse: () => neon);
  }
}
