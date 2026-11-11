import '../audio/game_audio.dart';
import '../audio/audio_events.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';
import '../auth/session_store.dart';
import '../multiplayer/rooms_repository.dart';
import '../presentation/pages/multijugador_page.dart';
import '../auth/auth_repository.dart';
import '../server/server_configuration.dart';
import '../presentation/pages/acceso_page.dart';
import '../presentation/pages/servidor_page.dart';
import 'rutas_brilliant.dart';
import 'tema_brilliant.dart';

class BrilliantGameApp extends StatefulWidget {
  final Random? azarPartida;
  final AuthRepository? authRepository;
  final RoomsRepository? roomsRepository;
  final ServerSettingsStore? serverStore;
  final SessionStore? sessionStore;
  final ServerProbe? serverProbe;
  final AuthRepository Function(Uri)? authRepositoryFactory;
  const BrilliantGameApp({
    super.key,
    this.azarPartida,
    this.authRepository,
    this.roomsRepository,
    this.serverStore,
    this.sessionStore,
    this.serverProbe,
    this.authRepositoryFactory,
  });
  @override
  State<BrilliantGameApp> createState() => _BrilliantGameAppState();
}

class _BrilliantGameAppState extends State<BrilliantGameApp>
    with WidgetsBindingObserver {
  final _audioNavigation = AudioNavigation(GameAudio.instance);
  AuthRepository? _repository;
  RoomsRepository? _roomsRepository;
  AuthCubit? _auth;
  late final _store = widget.serverStore ?? PreferencesServerSettingsStore();
  late final _probe = widget.serverProbe ?? HttpServerProbe();
  late final bool _configurationEnabled =
      widget.authRepository == null || widget.serverStore != null;
  Uri _server = HttpAuthRepository.configuredBaseUrl;
  bool _configured = false;
  String? _warning;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_configurationEnabled) {
      _load();
    } else {
      _createAuth();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    GameAudio.instance.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) _auth?.resumeSession();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _auth?.suspendSession();
    }
  }

  void _createAuth() {
    _repository =
        widget.authRepository ??
        widget.authRepositoryFactory?.call(_server) ??
        HttpAuthRepository(baseUrl: _server);
    final sessionStore =
        widget.sessionStore ??
        (widget.authRepository == null && widget.authRepositoryFactory == null
            ? SecureSessionStore(_server.toString())
            : null);
    _auth = AuthCubit(_repository!, sessionStore: sessionStore);
    if (sessionStore != null) _auth!.restoreSession();
    _roomsRepository =
        widget.roomsRepository ?? HttpRoomsRepository(baseUrl: _server);
  }

  Future<void> _load() async {
    try {
      final stored = await _store.read();
      if (!mounted) return;
      if (stored != null) {
        _server = ServerAddress.parse(stored);
      } else if (const bool.hasEnvironment('API_BASE_URL')) {
        _server = ServerAddress.parse(_server.toString());
      }
      _configured = stored != null || const bool.hasEnvironment('API_BASE_URL');
      if (!_configured) _warning = 'Configura el servidor para comenzar.';
    } catch (_) {
      if (!mounted) return;
      _warning =
          'No se pudo cargar la dirección guardada. Configura el servidor para comenzar.';
    }
    if (!mounted) return;
    setState(_createAuth);
  }

  void _changeServer(Uri address) {
    if (_auth?.state.session != null || _auth?.state.busy == true) return;
    final previousAuth = _auth;
    final previousRepository = _repository;
    final previousRoomsRepository = _roomsRepository;
    setState(() {
      _server = address;
      _configured = true;
      _warning = null;
      _revision++;
      _createAuth();
    });
    previousAuth?.close();
    if (widget.authRepository == null) previousRepository?.close();
    if (widget.roomsRepository == null) previousRoomsRepository?.close();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.close();
    if (widget.authRepository == null) _repository?.close();
    if (widget.roomsRepository == null) _roomsRepository?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth == null) {
      return MaterialApp(
        theme: TemaBrilliant.oscuro,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return BlocProvider.value(
      value: auth,
      child: BlocBuilder<AuthCubit, AuthState>(
        // Cada identidad y servidor tienen su Navigator. Al salir o cambiar
        // de servidor se desmontan todas las rutas y los formularios anteriores.
        buildWhen: (previous, current) =>
            previous.session?.user.id != current.session?.user.id,
        builder: (context, state) => MaterialApp(
          key: ValueKey((_revision, state.session?.user.id)),
          title: 'Brilliant Game',
          navigatorObservers: [_audioNavigation],
          debugShowCheckedModeBanner: false,
          theme: TemaBrilliant.oscuro,
          home: state.session == null
              ? Builder(
                  builder: (context) => AccesoPage(
                    canAuthenticate: !_configurationEnabled || _configured,
                    serverWarning: _warning,
                    serverLabel: _configured
                        ? _server.authority
                        : 'Sin configurar',
                    onServerSettings: !_configurationEnabled
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ServidorPage(
                                currentAddress: _configured ? _server : null,
                                store: _store,
                                probe: _probe,
                                onSaved: _changeServer,
                              ),
                            ),
                          ),
                  ),
                )
              : null,
          onGenerateRoute: state.session == null
              ? null
              : (settings) => RutasBrilliant.generar(
                  settings,
                  azarPartida: widget.azarPartida,
                  cuenta: state.session!.user,
                  multijugadorBuilder: (_) =>
                      MultijugadorPage(repository: _roomsRepository!),
                ),
        ),
      ),
    );
  }
}
