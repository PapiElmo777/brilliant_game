import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth_cubit.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/avatar_usuario.dart';
import '../../catalogo/catalogo_tableros.dart';

class CuentaPage extends StatelessWidget {
  const CuentaPage({super.key});
  Future<void> _avatars(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar avatar'),
        content: SizedBox(
          width: 340,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            children: [
              for (final level
                  in CatalogoTableros.predeterminado().definiciones.values)
                InkWell(
                  key: ValueKey('avatar_${level.id}'),
                  onTap: () => Navigator.pop(context, level.id),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AvatarUsuario(avatarId: level.id, size: 72),
                      Text(level.nombre ?? level.id),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected != null) await auth.selectAvatar(selected);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) => PopScope(
      canPop: !state.busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi cuenta')),
        body: FondoEspacial(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: AvatarUsuario(
                          key: const ValueKey('avatar_cuenta'),
                          avatarId: state.session?.user.avatarId,
                          size: 96,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('seleccionar_avatar'),
                        onPressed: state.busy ? null : () => _avatars(context),
                        child: const Text('Seleccionar avatar'),
                      ),
                      if (state.error != null && !state.logoutUnconfirmed)
                        Text(state.error!),
                      Text(
                        state.session?.user.username ?? '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const ValueKey('logout_account'),
                        onPressed: state.busy || state.cooldown > 0
                            ? null
                            : () => context.read<AuthCubit>().logout(),
                        icon: const Icon(Icons.logout),
                        label: Text(
                          state.busy
                              ? 'Cerrando sesión…'
                              : state.logoutUnconfirmed
                              ? 'Reintentar cierre de sesión'
                              : 'Cerrar sesión',
                        ),
                      ),
                      if (state.logoutUnconfirmed) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            state.error!,
                            key: const ValueKey('logout_error'),
                          ),
                        ),
                        if (state.cooldown > 0)
                          Text('Vuelve a intentarlo en ${state.cooldown} s.'),
                        TextButton(
                          key: const ValueKey('logout_local'),
                          onPressed: () =>
                              context.read<AuthCubit>().logoutLocally(),
                          child: const Text('Salir solo de este dispositivo'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('delete_account'),
                        onPressed: state.busy
                            ? null
                            : () {
                                context.read<AuthCubit>().clearError();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const _EliminarCuentaPage(),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Eliminar cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _EliminarCuentaPage extends StatefulWidget {
  const _EliminarCuentaPage();
  @override
  State<_EliminarCuentaPage> createState() => _EliminarCuentaPageState();
}

class _EliminarCuentaPageState extends State<_EliminarCuentaPage> {
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _confirmed = false;
  bool _visible = false;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      final enabled = !state.busy && state.cooldown == 0;
      return PopScope(
        canPop: !state.busy,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Eliminar cuenta'),
            automaticallyImplyLeading: !state.busy,
          ),
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
                          const Text(
                            'Se eliminarán permanentemente tu cuenta y todas sus sesiones. Esta acción no se puede deshacer.',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const ValueKey('delete_password'),
                            controller: _password,
                            enabled: !state.busy,
                            obscureText: !_visible,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'Contraseña actual',
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
                            validator: (value) => (value ?? '').isEmpty
                                ? 'Escribe tu contraseña actual.'
                                : null,
                          ),
                          CheckboxListTile(
                            key: const ValueKey('delete_confirmation'),
                            contentPadding: EdgeInsets.zero,
                            value: _confirmed,
                            onChanged: state.busy
                                ? null
                                : (value) =>
                                      setState(() => _confirmed = value!),
                            title: const Text(
                              'Confirmo que quiero eliminar mi cuenta.',
                            ),
                          ),
                          if (state.error != null)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                state.error!,
                                key: const ValueKey('delete_error'),
                              ),
                            ),
                          if (state.cooldown > 0)
                            Text('Vuelve a intentarlo en ${state.cooldown} s.'),
                          const SizedBox(height: 20),
                          FilledButton(
                            key: const ValueKey('delete_submit'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF9D2436),
                            ),
                            onPressed: enabled && _confirmed
                                ? () {
                                    if (!_form.currentState!.validate()) return;
                                    FocusScope.of(context).unfocus();
                                    context.read<AuthCubit>().deleteAccount(
                                      _password.text,
                                    );
                                    _password.clear();
                                  }
                                : null,
                            child: Text(
                              state.busy
                                  ? 'Eliminando…'
                                  : 'ELIMINAR DEFINITIVAMENTE',
                            ),
                          ),
                          TextButton(
                            onPressed: state.busy
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
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
