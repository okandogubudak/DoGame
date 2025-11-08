import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/modern_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      
                      const SizedBox(height: 80),
                      
                      _buildMenuButtons(context),
                      
                      const SizedBox(height: 40),
                      
                      _buildBottomButtons(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return Column(
      children: [
        // Animasyonlu top ikonu
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
                Color(0xFFFF4500),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFF6B9D),
              Color(0xFF6C63FF),
            ],
          ).createShader(bounds),
          child: const Text(
            'DO GAME',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        const Text(
          'Topu Dengede Tut!',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      children: [
        ModernButton(
          text: 'OYNA',
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/game');
          },
          color: const Color(0xFF6C63FF),
        ),
        
        const SizedBox(height: 20),
        
        ModernButton(
          text: 'SEVİYELER',
          icon: Icons.stairs_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seviyeler yakında!')),
            );
          },
          color: const Color(0xFFFF6B9D),
        ),
        
        const SizedBox(height: 20),
        
        ModernButton(
          text: 'BAŞARIMLAR',
          icon: Icons.emoji_events_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Başarımlar yakında!')),
            );
          },
          color: const Color(0xFFFECA57),
        ),
      ],
    );
  }
  
  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ModernIconButton(
          icon: Icons.settings_rounded,
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          color: Colors.white,
        ),
        
        const SizedBox(width: 20),
        
        ModernIconButton(
          icon: Icons.leaderboard_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Liderlik Tablosu yakında!')),
            );
          },
          color: Colors.white,
        ),
        
        const SizedBox(width: 20),
        
        ModernIconButton(
          icon: Icons.info_outline_rounded,
          onPressed: () {
            _showInfoDialog(context);
          },
          color: Colors.white,
        ),
      ],
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Nasıl Oynanır?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(Icons.phone_android, 'Telefonu yatır veya eğ'),
            _buildInfoItem(Icons.sports_soccer, 'Topu hedefe götür'),
            _buildInfoItem(Icons.dangerous, 'Engellere çarpma'),
            _buildInfoItem(Icons.timer, 'Süre dolmadan bitir'),
          ],
        ),
        actions: [
          ModernButton(
            text: 'ANLADIM',
            onPressed: () => Navigator.pop(context),
            width: 150,
            height: 45,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
