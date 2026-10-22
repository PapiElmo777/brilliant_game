class RecursosNivel {
  final int numero;
  final String fondo;
  final String miniatura;
  final String nave;
  final String personaje;
  final double proporcionNave;
  final double emisionY;

  const RecursosNivel(
    this.numero,
    this.personaje, {
    this.proporcionNave = 4 / 3,
    this.emisionY = .85,
  }) : fondo = 'assets/images/backgrounds/Nivel $numero.png',
       miniatura = 'assets/images/minis/Mini $numero.png',
       nave = 'assets/images/characters/$personaje N$numero.png';
}
