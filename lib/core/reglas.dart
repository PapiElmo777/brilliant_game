/// Restricciones sobre los números de una zona, independientes de su identidad.
enum ReglaZona {
  cualquierNumero,
  todosIguales,
  todosDiferentes,
  maxDosDiferentes;

  bool validarValores(Iterable<int> valores) {
    final lista = valores.toList();
    if (lista.any((valor) => valor < 1 || valor > 6)) return false;
    final distintos = lista.toSet().length;
    return switch (this) {
      ReglaZona.cualquierNumero => true,
      ReglaZona.todosIguales => distintos <= 1,
      ReglaZona.todosDiferentes => distintos == lista.length,
      ReglaZona.maxDosDiferentes => distintos <= 2,
    };
  }
}

// Se conservan las funciones existentes, delegando en la misma implementación.
bool cumpleReglaRojoAmarillo(List<int> lista, int numero) =>
    ReglaZona.todosDiferentes.validarValores([...lista, numero]);

bool cumpleReglaVerde(List<int> lista, int numero) =>
    ReglaZona.cualquierNumero.validarValores([...lista, numero]);

bool cumpleReglaAzul(List<int> lista, int numero) =>
    ReglaZona.todosIguales.validarValores([...lista, numero]);

bool cumpleReglaMorado(List<int> lista, int numero) =>
    ReglaZona.maxDosDiferentes.validarValores([...lista, numero]);
