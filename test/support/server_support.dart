import 'package:brilliant_game/server/server_configuration.dart';

class MemoryServerSettingsStore implements ServerSettingsStore {
  String? value;
  bool failRead = false;
  bool failWrite = false;
  final List<String> writes = [];
  MemoryServerSettingsStore([this.value]);
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('Fallo de lectura');
    return value;
  }

  @override
  Future<void> write(String address) async {
    if (failWrite) throw StateError('Fallo de escritura');
    value = address;
    writes.add(address);
  }
}

class FakeServerProbe implements ServerProbe {
  ServerConfigurationException? failure;
  final List<Uri> calls = [];
  @override
  Future<void> check(Uri address) async {
    calls.add(address);
    if (failure != null) throw failure!;
  }
}
