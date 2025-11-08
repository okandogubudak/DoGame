import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/game_themes.dart';
import '../widgets/modern_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  double _tiltSensitivity = 25.0;
  bool _vibrationsEnabled = true;
  String _selectedThemeId = 'neon';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = prefs.getDouble('musicVolume') ?? 0.7;
      _sfxVolume = prefs.getDouble('sfxVolume') ?? 0.8;
      _tiltSensitivity = prefs.getDouble('tiltSensitivity') ?? 25.0;
      _vibrationsEnabled = prefs.getBool('vibrationsEnabled') ?? true;
      _selectedThemeId = prefs.getString('theme') ?? 'neon';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setDouble('sfxVolume', _sfxVolume);
    await prefs.setDouble('tiltSensitivity', _tiltSensitivity);
    await prefs.setBool('vibrationsEnabled', _vibrationsEnabled);
    await prefs.setString('theme', _selectedThemeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GameThemes.getById(_selectedThemeId).backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle('🎵 SES AYARLARI'),
                    _buildSlider(
                      'Müzik Seviyesi',
                      Icons.music_note_rounded,
                      _musicVolume,
                      (value) {
                        setState(() => _musicVolume = value);
                        _saveSettings();
                      },
                    ),
                    _buildSlider(
                      'Efekt Sesi Seviyesi',
                      Icons.volume_up_rounded,
                      _sfxVolume,
                      (value) {
                        setState(() => _sfxVolume = value);
                        _saveSettings();
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('🎮 KONTROL AYARLARI'),
                    _buildSlider(
                      'Tilt Hassasiyeti',
                      Icons.phone_android_rounded,
                      _tiltSensitivity / 50,
                      (value) {
                        setState(() => _tiltSensitivity = value * 50);
                        _saveSettings();
                      },
                    ),
                    _buildSwitch(
                      'Titreşim',
                      Icons.vibration_rounded,
                      _vibrationsEnabled,
                      (value) {
                        setState(() => _vibrationsEnabled = value);
                        _saveSettings();
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('🎨 TEMA SEÇİMİ'),
                    _buildThemeSelector(),
                    
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('📊 DİĞER'),
                    _buildButton('Verileri Sıfırla', Icons.delete_forever_rounded, () {
                      _showResetDialog();
                    }),
                    _buildButton('Kalibre Et', Icons.settings_backup_restore_rounded, () {
                      _showCalibrateDialog();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ModernIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          const Text(
            'AYARLAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: const Color(0xFF6C63FF),
              overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C63FF),
            activeTrackColor: const Color(0xFF6C63FF).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Wrap(
        spacing: 15,
        runSpacing: 15,
        children: GameThemes.all.map((theme) {
          final isSelected = _selectedThemeId == theme.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedThemeId = theme.id;
              });
              _saveSettings();
            },
            child: Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                gradient: theme.backgroundGradient,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.white, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    theme.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Verileri Sıfırla', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm ilerlemenizi ve ayarlarınızı silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm veriler silindi')),
                );
              }
            },
            child: const Text('SİL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCalibrateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Kalibrasyon', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Telefonu düz bir yüzeye koyun ve "Tamam"a basın.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Kalibrasyonu tetikle
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kalibrasyon tamamlandı')),
              );
            },
            child: const Text('TAMAM', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }
}
