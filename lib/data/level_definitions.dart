import 'package:flutter/material.dart';
import 'dart:math';

// Enums
enum Difficulty { easy, medium, hard, expert, boss }

enum ObstacleShape { circle, square, triangle }

enum ObstacleType { solid, deadly, bouncy, slippery }

enum MovementPattern { horizontal, vertical, circular, figure8 }

// Star Condition
class StarCondition {
  final int minScore;
  final int time;
  
  StarCondition({required this.minScore, required this.time});
}

// Power Up
class PowerUp {
  final Offset position;
  final String type;
  
  PowerUp({required this.position, required this.type});
}

// Level Data
class LevelData {
  final int id;
  final String name;
  final Difficulty difficulty;
  final int timeLimit;
  final Offset startPosition;
  final Offset targetPosition;
  final List<ObstacleData> obstacles;
  final List<StarCondition> stars;
  final List<PowerUp>? powerUps;
  
  LevelData({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.timeLimit,
    required this.startPosition,
    required this.targetPosition,
    required this.obstacles,
    List<StarCondition>? stars,
    this.powerUps,
  }) : stars = stars ?? [
    StarCondition(minScore: 50, time: timeLimit - 10),
    StarCondition(minScore: 80, time: timeLimit - 20),
    StarCondition(minScore: 100, time: timeLimit - 30),
  ];
}

// Obstacle Data
class ObstacleData {
  final Offset position;
  final double size;
  final double? width;
  final double? height;
  final ObstacleType type;
  final ObstacleShape shape;
  final bool isRotating;
  final double rotationSpeed;
  final bool isMoving;
  final MovementPattern? movementPattern;
  final double movementRange;
  final double movementSpeed;
  final Offset? movementCenter;
  
  ObstacleData({
    required this.position,
    this.size = 50,
    this.width,
    this.height,
    required this.type,
    required this.shape,
    this.isRotating = false,
    this.rotationSpeed = 0.0,
    this.isMoving = false,
    this.movementPattern,
    this.movementRange = 0.0,
    this.movementSpeed = 0.0,
    this.movementCenter,
  });
  
  Color get color {
    switch (type) {
      case ObstacleType.deadly:
        return const Color(0xFFFF4757);
      case ObstacleType.bouncy:
        return const Color(0xFF4ECDC4);
      case ObstacleType.slippery:
        return const Color(0xFF48DBFB);
      default:
        return const Color(0xFF78909C);
    }
  }
}

// Level Definitions
class LevelDefinitions {
  static List<LevelData> getAllLevels() {
    return [
      // === BÖLÜM 1: BAŞLANGIÇ ===
      LevelData(
        id: 1,
        name: 'İlk Adım',
        difficulty: Difficulty.easy,
        timeLimit: 45,
        startPosition: const Offset(100, 400),
        targetPosition: const Offset(700, 400),
        obstacles: [
          ObstacleData(
            position: const Offset(400, 400),
            size: 60,
            type: ObstacleType.solid,
            shape: ObstacleShape.circle,
          ),
        ],
        stars: [
          StarCondition(minScore: 50, time: 40),
          StarCondition(minScore: 80, time: 30),
          StarCondition(minScore: 100, time: 20),
        ],
      ),
      
      LevelData(
        id: 2,
        name: 'Koridor',
        difficulty: Difficulty.easy,
        timeLimit: 60,
        startPosition: const Offset(100, 400),
        targetPosition: const Offset(700, 400),
        obstacles: [
          ObstacleData(
            position: const Offset(400, 200),
            size: 600,
            width: 600,
            height: 40,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
          ObstacleData(
            position: const Offset(400, 600),
            size: 600,
            width: 600,
            height: 40,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
        ],
        stars: [
          StarCondition(minScore: 60, time: 55),
          StarCondition(minScore: 90, time: 40),
          StarCondition(minScore: 120, time: 25),
        ],
      ),
      
      LevelData(
        id: 3,
        name: 'Basit Labirent',
        difficulty: Difficulty.medium,
        timeLimit: 75,
        startPosition: const Offset(100, 100),
        targetPosition: const Offset(700, 700),
        obstacles: [
          ObstacleData(
            position: const Offset(300, 400),
            width: 40,
            height: 500,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
          ObstacleData(
            position: const Offset(500, 300),
            width: 400,
            height: 40,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          ),
          ObstacleData(
            position: const Offset(400, 500),
            size: 80,
            type: ObstacleType.deadly,
            shape: ObstacleShape.circle,
          ),
        ],
      ),
      
      LevelData(
        id: 4,
        name: 'Zigzag',
        difficulty: Difficulty.medium,
        timeLimit: 90,
        startPosition: const Offset(50, 400),
        targetPosition: const Offset(750, 400),
        obstacles: List.generate(5, (i) {
          return ObstacleData(
            position: Offset(150.0 + i * 150, i.isEven ? 300.0 : 500.0),
            width: 40,
            height: 200,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
          );
        }),
      ),
      
      LevelData(
        id: 5,
        name: 'Mayın Tarlası',
        difficulty: Difficulty.hard,
        timeLimit: 120,
        startPosition: const Offset(100, 400),
        targetPosition: const Offset(700, 400),
        obstacles: [
          ...List.generate(3, (i) {
            return ObstacleData(
              position: Offset(200.0 + i * 200, 400.0),
              width: 40,
              height: 400,
              type: ObstacleType.solid,
              shape: ObstacleShape.square,
            );
          }),
          ...List.generate(15, (i) {
            return ObstacleData(
              position: Offset(
                150.0 + (i % 5) * 100.0,
                250.0 + (i ~/ 5) * 100.0,
              ),
              size: 40,
              type: ObstacleType.deadly,
              shape: ObstacleShape.circle,
            );
          }),
        ],
      ),
      
      LevelData(
        id: 6,
        name: 'Dönen Şeyler',
        difficulty: Difficulty.hard,
        timeLimit: 90,
        startPosition: const Offset(100, 400),
        targetPosition: const Offset(700, 400),
        obstacles: [
          ObstacleData(
            position: const Offset(300, 400),
            size: 150,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isRotating: true,
            rotationSpeed: 1.0,
          ),
          ObstacleData(
            position: const Offset(500, 400),
            size: 150,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isRotating: true,
            rotationSpeed: -1.5,
          ),
        ],
      ),
      
      LevelData(
        id: 7,
        name: 'Platformlar',
        difficulty: Difficulty.hard,
        timeLimit: 100,
        startPosition: const Offset(100, 400),
        targetPosition: const Offset(700, 100),
        obstacles: [
          ObstacleData(
            position: const Offset(250, 400),
            width: 100,
            height: 30,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isMoving: true,
            movementPattern: MovementPattern.vertical,
            movementRange: 200,
            movementSpeed: 2.0,
          ),
          ObstacleData(
            position: const Offset(450, 300),
            width: 100,
            height: 30,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isMoving: true,
            movementPattern: MovementPattern.vertical,
            movementRange: 200,
            movementSpeed: 2.5,
          ),
          ObstacleData(
            position: const Offset(650, 400),
            width: 100,
            height: 30,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isMoving: true,
            movementPattern: MovementPattern.vertical,
            movementRange: 200,
            movementSpeed: 2.0,
          ),
        ],
      ),
      
      LevelData(
        id: 8,
        name: 'Kaos',
        difficulty: Difficulty.expert,
        timeLimit: 150,
        startPosition: const Offset(50, 50),
        targetPosition: const Offset(750, 750),
        obstacles: [
          ...List.generate(4, (i) {
            return ObstacleData(
              position: Offset(200.0 + i * 150, 400.0),
              width: 40,
              height: 300,
              type: ObstacleType.solid,
              shape: ObstacleShape.square,
            );
          }),
          ...List.generate(3, (i) {
            return ObstacleData(
              position: Offset(150.0 + i * 250, 200.0),
              size: 60,
              type: ObstacleType.deadly,
              shape: ObstacleShape.circle,
              isMoving: true,
              movementPattern: MovementPattern.circular,
              movementRange: 100,
              movementSpeed: 1.5,
            );
          }),
          ObstacleData(
            position: const Offset(400, 400),
            size: 200,
            type: ObstacleType.solid,
            shape: ObstacleShape.square,
            isRotating: true,
            rotationSpeed: 2.0,
          ),
        ],
      ),
      
      LevelData(
        id: 9,
        name: 'Final Boss',
        difficulty: Difficulty.boss,
        timeLimit: 180,
        startPosition: const Offset(400, 700),
        targetPosition: const Offset(400, 100),
        obstacles: [
          ObstacleData(
            position: const Offset(400, 400),
            size: 300,
            type: ObstacleType.solid,
            shape: ObstacleShape.circle,
            isRotating: true,
            rotationSpeed: 1.0,
          ),
          ...List.generate(8, (i) {
            final angle = (i * 45.0) * (pi / 180);
            return ObstacleData(
              position: Offset(
                400 + 200 * cos(angle),
                400 + 200 * sin(angle),
              ),
              size: 40,
              type: ObstacleType.deadly,
              shape: ObstacleShape.circle,
              isMoving: true,
              movementPattern: MovementPattern.circular,
              movementRange: 200,
              movementSpeed: 2.0,
              movementCenter: const Offset(400, 400),
            );
          }),
        ],
      ),
    ];
  }
}
