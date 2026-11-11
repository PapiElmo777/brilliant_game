import 'package:flutter/material.dart';
import 'game_audio.dart';

class AudioSettingsButton extends StatelessWidget {
  const AudioSettingsButton({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: GameAudio.instance,
    builder: (context, _) => IconButton(
      key: const ValueKey('audio_settings'),
      tooltip: 'Sonido',
      icon: Icon(
        GameAudio.instance.muted
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
      ),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const AudioSettings(),
      ),
    ),
  );
}

class AudioSettings extends StatelessWidget {
  final GameAudio? audio;
  const AudioSettings({super.key, this.audio});
  @override
  Widget build(BuildContext context) {
    final sound = audio ?? GameAudio.instance;
    return ListenableBuilder(
      listenable: sound,
      builder: (context, _) {
        Widget slider(
          String title,
          double value,
          ValueChanged<double> update,
          GameSound? preview,
        ) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$title · ${(value * 100).round()} %'),
            Slider(
              key: ValueKey('audio_$title'),
              value: value,
              onChanged: sound.muted ? null : update,
              onChangeEnd: sound.muted || preview == null
                  ? null
                  : (_) => sound.play(preview),
            ),
          ],
        );
        return AlertDialog(
          title: const Text('Sonido de la misión'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Silenciar todo'),
                    value: sound.muted,
                    onChanged: (value) => sound.configure(muted: value),
                  ),
                  slider(
                    'Música',
                    sound.musicVolume,
                    (v) => sound.configure(music: v),
                    null,
                  ),
                  slider(
                    'Efectos',
                    sound.effectsVolume,
                    (v) => sound.configure(effects: v),
                    GameSound.select,
                  ),
                  slider(
                    'Avisos',
                    sound.alertsVolume,
                    (v) => sound.configure(alerts: v),
                    GameSound.chat,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ],
        );
      },
    );
  }
}
