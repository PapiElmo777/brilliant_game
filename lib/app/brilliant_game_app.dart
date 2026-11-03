import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_repository.dart';
import '../presentation/pages/acceso_page.dart';
import 'rutas_brilliant.dart';
import 'tema_brilliant.dart';

class BrilliantGameApp extends StatefulWidget {
  final Random? azarPartida;
  final AuthRepository? authRepository;
  const BrilliantGameApp({super.key, this.azarPartida, this.authRepository});
  @override
  State<BrilliantGameApp> createState() => _BrilliantGameAppState();
}

class _BrilliantGameAppState extends State<BrilliantGameApp> {
  late final _repository = widget.authRepository ?? HttpAuthRepository();
  late final _auth = AuthCubit(_repository);
  @override
  void dispose() {
    _auth.close();
    if (widget.authRepository == null) _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _auth,
    child: BlocBuilder<AuthCubit, AuthState>(
      // Cada identidad tiene su Navigator. Borrar/caducar desmonta TODAS las
      // rutas y diálogos del juego, incluso los abiertos durante una petición.
      buildWhen: (previous, current) =>
          previous.session?.user.id != current.session?.user.id,
      builder: (context, state) => MaterialApp(
        key: ValueKey(state.session?.user.id),
        title: 'Brilliant Game',
        debugShowCheckedModeBanner: false,
        theme: TemaBrilliant.oscuro,
        home: state.session == null ? const AccesoPage() : null,
        onGenerateRoute: state.session == null
            ? null
            : (settings) => RutasBrilliant.generar(
                settings,
                azarPartida: widget.azarPartida,
                cuenta: state.session!.user,
              ),
      ),
    ),
  );
}
