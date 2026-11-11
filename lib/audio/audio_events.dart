import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../auth/auth_cubit.dart';
import '../bloc/inicio_estado.dart';
import '../bloc/partida_estado.dart';
import '../models/tirada.dart';
import '../multiplayer/rooms_cubit.dart';
import '../multiplayer/rooms_repository.dart';
import 'game_audio.dart';

/// State transitions, rather than widget rebuilds, emit gameplay sounds.
class AudioEvents extends BlocObserver {
  final GameAudio audio;
  final BlocObserver? previous;
  AudioEvents(this.audio, {this.previous});
  final _matches = Expando<OnlineMatch>();
  final _sources = Expando<Map<String, dynamic>>();
  final _clocks = Expando<({String round, int low})>();
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    previous?.onChange(bloc, change);
    final a = change.currentState, b = change.nextState;
    if (a is PartidaEstado && b is PartidaEstado) {
      if (b.error != null && b.error != a.error) audio.play(GameSound.reject);
      if (b.dadoSeleccionado != null &&
          b.dadoSeleccionado != a.dadoSeleccionado) {
        audio.play(GameSound.select);
      }
      if (b.puedeOmitir &&
          !b.animandoMeteoros &&
          (!a.puedeOmitir || a.animandoMeteoros)) {
        audio.play(GameSound.reject);
      }
      if (b.historial.length > a.historial.length &&
          b.historial.last.resultado == ResultadoRonda.omitida) {
        audio.play(GameSound.skip);
      }
      if (b.celdaColocada != null && b.celdaColocada != a.celdaColocada) {
        audio.play(GameSound.place);
      }
      if (b.reclamoRonda != null && b.reclamoRonda != a.reclamoRonda) {
        audio.play(zoneSound(b.reclamoRonda!.puesto));
      }
      if (!a.partidaTerminada && b.partidaTerminada) {
        audio.stopEffects();
        audio.play(GameSound.victory);
      }
    } else if (a is InicioEstado && b is InicioEstado) {
      if (b.error != null && b.error != a.error) audio.play(GameSound.reject);
      if (b.numeroSeleccionado != a.numeroSeleccionado &&
          b.numeroSeleccionado != null) {
        audio.play(GameSound.select);
      }
      if (b.fase != a.fase && b.fase == FaseInicio.listo) {
        audio.play(GameSound.ready);
      }
      if (b.fase != a.fase && b.fase == FaseInicio.iniciado) {
        audio.play(GameSound.launch);
      }
    } else if (bloc is RoomsCubit && a is RoomsState && b is RoomsState) {
      _rooms(bloc, a, b);
    } else if (a is AuthState && b is AuthState) {
      if (!a.connectionLost && b.connectionLost) {
        audio.setScene(AudioScene.menu);
        audio.stopEffects();
        audio.play(GameSound.alert);
      } else if (a.session == null && b.session != null) {
        audio.play(GameSound.connect);
      } else if (a.session != null && b.session == null) {
        audio.setScene(AudioScene.menu);
        audio.play(GameSound.disconnect);
      } else if (b.error != null && b.error != a.error && !b.busy) {
        audio.play(GameSound.reject);
      }
    }
  }

  static GameSound zoneSound(int place) => switch (place) {
    1 => GameSound.zone1,
    2 => GameSound.zone2,
    _ => GameSound.zone3,
  };

  void _rooms(RoomsCubit rooms, RoomsState a, RoomsState b) {
    final oldLobby = a.lobby, lobby = b.lobby;
    if (oldLobby?.id != lobby?.id) {
      if (lobby == null) audio.setScene(AudioScene.menu);
      audio.play(lobby == null ? GameSound.disconnect : GameSound.connect);
    } else if (lobby != null && oldLobby != null) {
      if (oldLobby.members.length != lobby.members.length) {
        audio.play(
          lobby.members.length > oldLobby.members.length
              ? GameSound.connect
              : GameSound.disconnect,
        );
      }
      if (lobby.members.any(
        (m) =>
            m.ready &&
            !oldLobby.members.any((old) => old.id == m.id && old.ready),
      )) {
        audio.play(GameSound.ready);
      }
      if (lobby.levelId != oldLobby.levelId) audio.play(GameSound.select);
    }
    if (b.error != null && b.error != a.error) audio.play(GameSound.reject);
    // Sequence increases exclude paginated history; room changes establish a baseline.
    if (oldLobby?.id == lobby?.id &&
        a.channelConnected &&
        b.channelConnected &&
        lobby != null &&
        !a.loadingHistory &&
        !b.loadingHistory) {
      final sequence = a.messages.fold(
        0,
        (n, m) => m.sequence > n ? m.sequence : n,
      );
      final own = lobby.members
          .where((m) => m.userId == rooms.auth.state.session?.user.id)
          .firstOrNull
          ?.id;
      final fresh = b.messages.where(
        (m) => m.kind == 'PLAYER' && m.sequence > sequence,
      );
      if (fresh.any((m) => m.authorId == own)) audio.play(GameSound.sent);
      if (b.unread > a.unread && fresh.any((m) => m.authorId != own)) {
        audio.play(GameSound.chat);
      }
    }
    final source = lobby?.match;
    if (source == null) {
      if (_matches[rooms] != null) audio.setScene(AudioScene.menu);
      _clocks[rooms] = null;
      _matches[rooms] = null;
      _sources[rooms] = null;
      return;
    }
    final changed = !identical(_sources[rooms], source);
    final oldGame = _matches[rooms];
    final game = changed ? OnlineMatch.fromJson(source) : oldGame!;
    _matches[rooms] = game;
    _sources[rooms] = source;
    if (oldGame?.id != game.id) {
      audio.setScene(AudioScene.game);
      audio.play(GameSound.launch);
      if (game.round != null && b.secondsRemaining != null) {
        _clocks[rooms] = (round: game.round!.id, low: b.secondsRemaining!);
      }
      return; // Initial/restored snapshot must not replay past claims/messages.
    }
    if (changed) {
      if (!oldGame!.prepared && game.prepared) audio.play(GameSound.ready);
      if (oldGame.round?.id != game.round?.id && game.round != null) {
        audio
            .stopEffects(); // Cancels the previous countdown and outdated effects.
      }
      final action = game.round?.ownAction;
      if (oldGame.round?.id == game.round?.id &&
          oldGame.round?.ownAction == null &&
          action != null) {
        if (action['kind'] == 'SKIP') audio.play(GameSound.skip);
      }
      final own = lobby!.members
          .where((m) => m.userId == rooms.auth.state.session?.user.id)
          .firstOrNull
          ?.id;
      String key(Map<String, dynamic> c) =>
          '${c['memberId']}:${c['zoneId']}:${c['place']}';
      final seen = oldGame.claims.map(key).toSet();
      final fresh = game.claims.where((c) => !seen.contains(key(c))).toList();
      final mine = fresh.where((c) => c['memberId'] == own).firstOrNull;
      if (mine != null && game.result == null) {
        audio.play(zoneSound(mine['place'] as int));
      } else if (fresh.isNotEmpty && game.result == null) {
        final exhausted = fresh.any((c) => (c['place'] as int) >= 3);
        audio.play(exhausted ? GameSound.zoneExhausted : GameSound.zoneOther);
      }
      if (game.state == 'END_VOTE' && oldGame.state != 'END_VOTE') {
        audio.play(GameSound.alert);
      }
      final accepted = game.rematch?['acceptedCount'] as int? ?? 0;
      final oldAccepted = oldGame.rematch?['acceptedCount'] as int? ?? 0;
      if (accepted > oldAccepted) audio.play(GameSound.ready);
    }
    // Keep a low-water mark per round: server clock corrections and reconnects
    // must not repeat a warning. Silent/background transitions still advance it.
    final seconds = b.secondsRemaining;
    final round = game.round;
    if (round == null || seconds == null || game.state != 'ROUND_ACTIVE') {
      return;
    }
    final clock = _clocks[rooms];
    _clocks[rooms] = (
      round: round.id,
      low: clock?.round == round.id && clock!.low < seconds
          ? clock.low
          : seconds,
    );
    if (clock == null ||
        clock.round != round.id ||
        seconds >= clock.low ||
        round.ownAction != null ||
        !a.channelConnected ||
        !b.channelConnected) {
      return;
    }
    if (clock.low > 30 && seconds <= 30 && seconds > 10) {
      audio.play(GameSound.thirty);
    }
    if (seconds > 0 && seconds <= 10) {
      audio.play(seconds <= 3 ? GameSound.tickFinal : GameSound.tick);
    }
    if (seconds == 0) audio.play(GameSound.timeout);
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    previous?.onCreate(bloc);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    previous?.onClose(bloc);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    previous?.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    previous?.onEvent(bloc, event);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    previous?.onTransition(bloc, transition);
  }
}

/// Dialogs inherit the current scene. Returning to the root restores menu music.
class AudioNavigation extends NavigatorObserver {
  final GameAudio audio;
  AudioNavigation(this.audio);
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) {
      audio.setScene(AudioScene.menu);
    } else {
      audio.play(route is PopupRoute ? GameSound.panel : GameSound.click);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.isFirst == true) audio.setScene(AudioScene.menu);
    audio.play(GameSound.back);
  }
}
