import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/reglas.dart';

void main() {
  //-------------------------COLOR ROJO Y AMARILLO----------------------------------------
  group('Pruebas de la regla Rojo/Amarillo', () {
    test(
      'Debe retornar true si la lista está vacia y se inserta un numero',
      () {
        final listaActual = <int>[];
        final resultado = cumpleReglaRojoAmarillo(listaActual, 4);

        expect(resultado, isTrue);
      },
    );

    test('Debe retornar true si el nuevo número no existe en la lista', () {
      final listaActual = [1, 2, 3];
      final resultado = cumpleReglaRojoAmarillo(listaActual, 4);

      expect(resultado, isTrue);
    });

    test('Debe retornar false si el nuevo numero ya existe en la lista', () {
      final listaActual = [1, 2, 4];
      final resultado = cumpleReglaRojoAmarillo(listaActual, 4);

      expect(resultado, isFalse);
    });

    test('Debe retornar false si la lista original ya contenia duplicados', () {
      final listaActual = [1, 2, 2];
      final resultado = cumpleReglaRojoAmarillo(listaActual, 4);

      expect(resultado, isFalse);
    });

    test(
      'Debe aceptar el sexto numero si los cinco anteriores son diferentes',
      () {
        final listaCasiLlena = [1, 2, 3, 4, 5];
        expect(cumpleReglaRojoAmarillo(listaCasiLlena, 6), isTrue);
        // Cualquier numero del 1 al 5 debe ser rechazado
        expect(cumpleReglaRojoAmarillo(listaCasiLlena, 3), isFalse);
      },
    );
  });
  //-------------------------COLOR VERDE----------------------------------------
  group('Pruebas de la regla Verde', () {
    test('Debe retornar true con una lista vacia', () {
      expect(cumpleReglaVerde([], 4), isTrue);
    });

    test('Debe retornar true sin importar que numeros haya en la lista', () {
      expect(cumpleReglaVerde([1, 2, 3], 4), isTrue);
      expect(cumpleReglaVerde([5, 5], 2), isTrue);
    });
  });
  //-------------------------COLOR AZUL----------------------------------------
  group('Pruebas de la regla Azul', () {
    test('Debe retornar true si la lista está vacia', () {
      expect(cumpleReglaAzul([], 4), isTrue);
    });

    test(
      'Debe retornar true si el nuevo numero es identico a los existentes',
      () {
        final listaActual = [4, 4];
        expect(cumpleReglaAzul(listaActual, 4), isTrue);
      },
    );

    test('Debe retornar false si el nuevo número es diferente', () {
      final listaActual = [4, 4];
      expect(cumpleReglaAzul(listaActual, 5), isFalse);
    });

    test(
      'Debe retornar false si la lista original ya tenia numeros diferentes',
      () {
        final listaActual = [4, 5];
        expect(cumpleReglaAzul(listaActual, 4), isFalse);
        expect(cumpleReglaAzul(listaActual, 5), isFalse);
      },
    );

    test(
      'Debe evaluar correctamente cuando el area solo tiene un numero colocado',
      () {
        final listaUnElemento = [3];
        // el nuevo numero coincide con el unico que hay
        expect(cumpleReglaAzul(listaUnElemento, 3), isTrue);
        // Falla, el nuevo numero es distinto al unico que hay
        expect(cumpleReglaAzul(listaUnElemento, 4), isFalse);
      },
    );
  });
  //-------------------------------COLOR MORADO----------------------------------
  group('Pruebas de la regla Morada', () {
    test('Debe retornar true si la lista está vacia', () {
      expect(cumpleReglaMorado([], 3), isTrue);
    });

    test('Debe retornar true si se agrega un segundo numero diferente', () {
      final listaActual = [3];
      expect(cumpleReglaMorado(listaActual, 5), isTrue);
    });

    test(
      'Debe retornar true si se repite uno de los dos números ya existentes',
      () {
        final listaActual = [3, 5, 3];
        expect(cumpleReglaMorado(listaActual, 5), isTrue);
        expect(cumpleReglaMorado(listaActual, 3), isTrue);
      },
    );

    test(
      'Debe retornar false si se intenta agregar un tercer número diferente',
      () {
        final listaActual = [3, 5, 3];
        expect(cumpleReglaMorado(listaActual, 1), isFalse);
      },
    );

    test('No debe modificar la lista original', () {
      final listaActual = [3, 5];
      cumpleReglaMorado(listaActual, 6);
      expect(listaActual.length, 2);
      expect(listaActual, equals([3, 5]));
    });
    test(
      'Debe retornar true si el area esta llena de un solo numero y se agrega un segundo numero distinto',
      () {
        final listaActual = [4, 4, 4, 4];
        expect(cumpleReglaMorado(listaActual, 2), isTrue);
      },
    );

    test(
      'Debe retornar true si el area tiene varios numeros iguales y se sigue agregando el mismo',
      () {
        final listaActual = [6, 6, 6];
        expect(cumpleReglaMorado(listaActual, 6), isTrue);
      },
    );

    test('Debe manejar correctamente los números límite del dado (1 y 6)', () {
      final listaActual = [1];
      expect(cumpleReglaMorado(listaActual, 6), isTrue);

      final listaAlLimite = [1, 6, 1, 6];
      expect(cumpleReglaMorado(listaAlLimite, 1), isTrue);
      expect(cumpleReglaMorado(listaAlLimite, 6), isTrue);
      expect(cumpleReglaMorado(listaAlLimite, 2), isFalse);
    });
  });
}
