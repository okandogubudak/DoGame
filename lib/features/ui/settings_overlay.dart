import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game_engine/beer_game.dart';
import '../../services/settings_manager.dart';
import '../../services/sound_manager.dart';
import '../../services/vibration_manager.dart';

class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({super.key, required this.game});

  final BeerGame game;

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  int _selectedBarColorIndex = 0;
  int _selectedControlTypeIndex = 0;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final barColorIndex = await SettingsManager.instance.getBarColorIndex();
    final controlTypeIndex = await SettingsManager.instance.getControlTypeIndex();
    final soundEnabled = await SettingsManager.instance.getSoundEnabled();
    final musicEnabled = await SettingsManager.instance.getMusicEnabled();
    final vibrationEnabled = await SettingsManager.instance.getVibrationEnabled();
    
    if (mounted) {
      setState(() {
        _selectedBarColorIndex = barColorIndex;
        _selectedControlTypeIndex = controlTypeIndex;
        _soundEnabled = soundEnabled;
        _musicEnabled = musicEnabled;
        _vibrationEnabled = vibrationEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D3748),
            Color(0xFF4A5568),
            Color(0xFF718096),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Modern başlık
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D3748),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC733),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.brown,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'AYARLAR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        SoundManager.instance.playClick();
                        VibrationManager.instance.lightTap();
                        widget.game.overlays.remove('Settings');
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              // İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kontrol tipi seçimi
                      _buildSection(
                        '🎮 Kontrol Tipi',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Oyunda çubuğu nasıl kontrol etmek istiyorsunuz?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                SettingsManager.controlTypeNames.length,
                                (index) => _buildControlChip(index),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Çubuk rengi seçimi
                      _buildSection(
                        '🎨 Çubuk Rengi',
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(
                            SettingsManager.availableBarColors.length,
                            (index) => _buildColorChip(index),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Ses ayarları
                      _buildSection(
                        '🔊 Ses ve Titreşim',
                        Column(
                          children: [
                            _buildModernSwitchTile(
                              icon: Icons.music_note,
                              title: 'Müzik',
                              subtitle: 'Arka plan müziği',
                              value: _musicEnabled,
                              onChanged: (value) async {
                                setState(() {
                                  _musicEnabled = value;
                                });
                                await SettingsManager.instance.saveMusicEnabled(value);
                                SoundManager.instance.setMusicEnabled(value);
                                if (!value) {
                                  SoundManager.instance.stopMusic();
                                } else {
                                  SoundManager.instance.startMenuMusic();
                                }
                              },
                            ),
                            _buildModernSwitchTile(
                              icon: Icons.volume_up,
                              title: 'Ses Efektleri',
                              subtitle: 'Oyun sesleri',
                              value: _soundEnabled,
                              onChanged: (value) async {
                                setState(() {
                                  _soundEnabled = value;
                                });
                                await SettingsManager.instance.saveSoundEnabled(value);
                                SoundManager.instance.setSoundEnabled(value);
                                if (value) {
                                  SoundManager.instance.playClick();
                                }
                              },
                            ),
                            _buildModernSwitchTile(
                              icon: Icons.vibration,
                              title: 'Titreşim',
                              subtitle: 'Dokunsal geri bildirim',
                              value: _vibrationEnabled,
                              onChanged: (value) async {
                                setState(() {
                                  _vibrationEnabled = value;
                                });
                                await SettingsManager.instance.saveVibrationEnabled(value);
                                VibrationManager.instance.setVibrationEnabled(value);
                                if (value) {
                                  VibrationManager.instance.lightTap();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Geri butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3748),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () {
                            SoundManager.instance.playClick();
                            VibrationManager.instance.lightTap();
                            widget.game.overlays.remove('Settings');
                          },
                          child: const Text(
                            'TAMAM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }
  
  Widget _buildControlChip(int index) {
    final isSelected = _selectedControlTypeIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          setState(() {
            _selectedControlTypeIndex = index;
          });
          await SettingsManager.instance.saveControlType(ControlType.values[index]);
          VibrationManager.instance.lightTap();
          SoundManager.instance.playClick();
          widget.game.updateControlType(ControlType.values[index]);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D3748) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF2D3748) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            SettingsManager.controlTypeNames[index],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorChip(int index) {
    final isSelected = _selectedBarColorIndex == index;
    final color = SettingsManager.availableBarColors[index];
    
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedBarColorIndex = index;
        });
        await SettingsManager.instance.saveBarColor(index);
        VibrationManager.instance.lightTap();
        SoundManager.instance.playClick();
        widget.game.updateBarColor(color);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D3748) : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              )
            : null,
      ),
    );
  }
  
  Widget _buildModernSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF2D3748) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2D3748),
            activeTrackColor: const Color(0xFF2D3748).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
