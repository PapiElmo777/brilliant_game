import 'package:flutter/material.dart';
import '../../server/server_configuration.dart';
import '../widgets/fondo_espacial.dart';

class ServidorPage extends StatefulWidget {
  final Uri? currentAddress;
  final ServerSettingsStore store;
  final ServerProbe probe;
  final ValueChanged<Uri> onSaved;
  const ServidorPage({
    super.key,
    required this.currentAddress,
    required this.store,
    required this.probe,
    required this.onSaved,
  });
  @override
  State<ServidorPage> createState() => _ServidorPageState();
}

class _ServidorPageState extends State<ServidorPage> {
  late final _address = TextEditingController(
    text: widget.currentAddress?.toString() ?? '',
  );
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final address = ServerAddress.parse(_address.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.probe.check(address);
      if (!mounted) return;
      try {
        await widget.store.write(address.toString());
      } catch (_) {
        throw const ServerConfigurationException(
          'No se pudo guardar la dirección en este dispositivo. Inténtalo de nuevo.',
        );
      }
      if (mounted) widget.onSaved(address);
    } on ServerConfigurationException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Servidor'),
        automaticallyImplyLeading: !_busy,
      ),
      body: FondoEspacial(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.dns_outlined,
                        size: 52,
                        color: Color(0xFF72E9FF),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Conecta con tu servidor',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Conecta este dispositivo a la misma red Wi-Fi que la computadora. Escribe la dirección que aparece en la terminal del servidor.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const ValueKey('server_address'),
                        controller: _address,
                        enabled: !_busy,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Dirección del servidor',
                          hintText: 'http://192.168.0.31:8080',
                          helperText:
                              'También puedes escribir solo la IP y el puerto.',
                        ),
                        onFieldSubmitted: _busy ? null : (_) => _save(),
                        validator: (value) {
                          try {
                            ServerAddress.parse(value ?? '');
                            return null;
                          } on ServerConfigurationException catch (error) {
                            return error.message;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'La dirección quedará guardada para la próxima vez. Tus cuentas pertenecen al servidor elegido.',
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              key: const ValueKey('server_error'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const ValueKey('server_save'),
                        onPressed: _busy ? null : _save,
                        icon: const Icon(Icons.wifi),
                        label: Text(
                          _busy
                              ? 'Comprobando conexión…'
                              : 'GUARDAR Y CONECTAR',
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
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
}
