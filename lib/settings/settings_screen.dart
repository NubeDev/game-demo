import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../player_progress/player_progress.dart';
import '../shared/kid_palette.dart';
import 'settings.dart';

/// The parent area, reachable only through the parental gate.
///
/// This is the ONE screen in the app written for an adult, so ordinary text and
/// ordinary controls are correct here (CLAUDE.md §3). Plain and boring on
/// purpose: nothing here should attract a child who lands on it.
///
/// The template's "player name" field was removed — a name is personal data,
/// and this app collects none (CLAUDE.md §4).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Grown-up settings'),
        backgroundColor: Colors.white,
        foregroundColor: KidPalette.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: settings.soundsOn,
                builder: (context, soundsOn, child) => SwitchListTile(
                  title: const Text('Sound effects'),
                  secondary: Icon(
                    soundsOn ? Icons.graphic_eq : Icons.volume_off,
                  ),
                  value: soundsOn,
                  onChanged: (_) => settings.toggleSoundsOn(),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.musicOn,
                builder: (context, musicOn, child) => SwitchListTile(
                  title: const Text('Music'),
                  secondary: Icon(
                    musicOn ? Icons.music_note : Icons.music_off,
                  ),
                  value: musicOn,
                  onChanged: (_) => settings.toggleMusicOn(),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Reset progress'),
                onTap: () {
                  context.read<PlayerProgress>().reset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress has been reset.')),
                  );
                },
              ),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Little Games works entirely offline. It shows no ads, '
                  'collects no personal data, and never sends anything from '
                  'this device.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
