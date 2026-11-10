import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth_cubit.dart';
import '../widgets/fondo_espacial.dart';

class AccesoPage extends StatefulWidget {
  final VoidCallback? onServerSettings;
  final String? serverLabel;
  final String? serverWarning;
  final bool canAuthenticate;
  const AccesoPage({
    super.key,
    this.onServerSettings,
    this.serverLabel,
    this.serverWarning,
    this.canAuthenticate = true,
  });
  @override
  State<AccesoPage> createState() => _AccesoPageState();
}

class _AccesoPageState extends State<AccesoPage> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _visible = false;
  bool _connectionDialogShown = false;

  void _notifyConnectionLost(AuthState state) {
    if (!state.connectionLost) { _connectionDialogShown = false; return; }
    if (_connectionDialogShown) return;
    _connectionDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Conexión perdida'),
          content: const Text('Se perdió la conexión con el servidor. Revisa tu conexión e inicia sesión de nuevo.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar'))],
        ),
      );
    });
  }
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().authenticate(
      _username.text,
      _password.text,
      register: _register,
    );
    // La contraseña no sobrevive al envío; solo existe durante la petición.
    _password.clear();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      _notifyConnectionLost(state);
      final enabled =
          widget.canAuthenticate && !state.busy && state.cooldown == 0;
      return Scaffold(
        body: FondoEspacial(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/branding/LogoBrilliant.png',
                          height: 110,
                          semanticLabel: 'Brilliant',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _register ? 'Crear cuenta' : 'Iniciar sesión',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const ValueKey('auth_username'),
                          controller: _username,
                          enabled: !state.busy,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            helperText: '3–16 letras, números o guion bajo',
                          ),
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              RegExp(
                                r'^[A-Za-z0-9_]{3,16}$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Usa entre 3 y 16 letras ASCII, números o guion bajo.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('auth_password'),
                          controller: _password,
                          enabled: !state.busy,
                          obscureText: !_visible,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            helperText: _register
                                ? '3–128 caracteres y al menos un carácter especial'
                                : null,
                            suffixIcon: IconButton(
                              tooltip: _visible
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                              onPressed: () =>
                                  setState(() => _visible = !_visible),
                              icon: Icon(
                                _visible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: enabled ? (_) => _submit() : null,
                          validator: (value) {
                            final password = value ?? '';
                            final length = password.runes.length;
                            if (length < 3 || length > 128) {
                              return 'Usa entre 3 y 128 caracteres.';
                            }
                            if (_register &&
                                !RegExp(
                                  r'[\p{P}\p{S}]',
                                  unicode: true,
                                ).hasMatch(password)) {
                              return 'Incluye al menos un carácter especial, como !, @ o #.';
                            }
                            return null;
                          },
                        ),
                        if (widget.serverWarning != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(widget.serverWarning!),
                            ),
                          ),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                state.error!,
                                key: const ValueKey('auth_error'),
                              ),
                            ),
                          ),
                        if (state.cooldown > 0)
                          Text('Vuelve a intentarlo en ${state.cooldown} s.'),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('auth_submit'),
                          onPressed: enabled ? _submit : null,
                          child: Text(
                            state.busy
                                ? 'Conectando…'
                                : _register
                                ? 'CREAR CUENTA'
                                : 'INICIAR SESIÓN',
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('auth_switch'),
                          onPressed: state.busy
                              ? null
                              : () {
                                  context.read<AuthCubit>().clearError();
                                  _password.clear();
                                  _form.currentState!.reset();
                                  setState(() {
                                    _register = !_register;
                                    _visible = false;
                                  });
                                },
                          child: Text(
                            _register
                                ? 'Ya tengo una cuenta'
                                : 'Crear una cuenta',
                          ),
                        ),
                        if (widget.onServerSettings != null) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            key: const ValueKey('server_settings'),
                            onPressed: state.busy
                                ? null
                                : widget.onServerSettings,
                            icon: const Icon(Icons.dns_outlined),
                            label: const Text('Servidor'),
                          ),
                          Text(
                            widget.serverLabel ?? '',
                            key: const ValueKey('server_current'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
