import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../services/sesion.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/////////////////////////////////////////////////////////////////

class S01Carga extends StatefulWidget {
  const S01Carga({super.key});

  @override
  State<S01Carga> createState() => _S01CargaState();
}

class _S01CargaState extends State<S01Carga> {
  @override
  void initState() {
    super.initState();
    verificar();
  }

  Future<void> verificar() async {
    bool haySesion = await Sesion.cargar();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    if (haySesion) {
      cambiar(context, Sesion.rutaInicio);
    } else {
      cambiar(context, Rutas.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.verde,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alt_route, size: 64, color: C.ocre),
            const SizedBox(height: 28),
            Text('COOTRASCHIPILIN', style: archivo(24, c: Colors.white)),
            const SizedBox(height: 10),
            Text('COOPERATIVA DE TRANSPORTE CHIPILIN',
                style: archivo(10,
                    w: FontWeight.w500, c: Colors.white70, espacio: 2)),
            const SizedBox(height: 50),
            SizedBox(
              width: 140,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  color: C.ocre,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Verificando sesión...', style: plex(12, c: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S02Login extends StatefulWidget {
  const S02Login({super.key});

  @override
  State<S02Login> createState() => _S02LoginState();
}

class _S02LoginState extends State<S02Login> {
  final usuario = TextEditingController();
  final clave = TextEditingController();
  bool verClave = false;
  bool cargando = false;
  String? error;

  Future<void> entrar() async {
    if (usuario.text.trim().isEmpty || clave.text.isEmpty) {
      setState(() => error = 'Escriba el usuario y la contraseña.');
      return;
    }
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final r = await Sitram.login(usuario.text.trim(), clave.text);
      if (!mounted) return;
      if (r.requiereCambioPassword) {
        Sesion.tokenCambio = r.token;
        ir(context, Rutas.cambiarClave);
      } else {
        Sesion.iniciar(r);
        Navigator.pushNamedAndRemoveUntil(
            context, Sesion.rutaInicio, (x) => false);
      }
    } catch (e) {
      setState(() => error = '$e');
    }
    if (mounted) setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.fondo,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
            decoration: const BoxDecoration(
              color: C.verde,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.alt_route, color: Colors.white, size: 34),
                const SizedBox(height: 26),
                Text('Bienvenido', style: archivo(22, c: Colors.white)),
                Text('Ingrese con las credenciales de su empresa.',
                    style: plex(12.5, c: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Campo('Usuario',
                    control: usuario,
                    icono: Icons.person_outline,
                    hint: 'Usuario o identificación'),
                Stack(
                  children: [
                    Campo('Contraseña',
                        control: clave,
                        clave: !verClave,
                        icono: Icons.lock_outline),
                    Positioned(
                      right: 4,
                      top: 24,
                      child: IconButton(
                        icon: Icon(
                            verClave
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: C.tenue),
                        onPressed: () => setState(() => verClave = !verClave),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Btn(cargando ? 'Ingresando...' : 'Iniciar sesión',
                    alTocar: cargando ? null : entrar),
                if (error != null)
                  Alerta(titulo: 'No se pudo iniciar sesión', texto: error!),
                const SizedBox(height: 10),
                Text('Cootraschipilin · Transporte mixto · Sucre',
                    textAlign: TextAlign.center, style: plex(11, c: C.tenue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S03CambiarClave extends StatefulWidget {
  const S03CambiarClave({super.key});

  @override
  State<S03CambiarClave> createState() => _S03CambiarClaveState();
}

class _S03CambiarClaveState extends State<S03CambiarClave> {
  String nueva = '';
  String confirma = '';
  bool guardando = false;

  bool get tieneDoce => nueva.length >= 12;
  bool get tieneMayus => nueva.contains(RegExp(r'[A-Z]'));
  bool get tieneMinus => nueva.contains(RegExp(r'[a-z]'));
  bool get tieneNumero => nueva.contains(RegExp(r'[0-9]'));
  bool get coinciden => nueva == confirma;
  bool get valida =>
      tieneDoce && tieneMayus && tieneMinus && tieneNumero && coinciden;

  Widget requisito(String texto, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.circle_outlined,
              size: 16, color: ok ? C.exito : C.tenue),
          const SizedBox(width: 8),
          Text(texto, style: plex(12, c: ok ? C.texto : C.tenue)),
        ],
      ),
    );
  }

  Future<void> guardar() async {
    setState(() => guardando = true);
    try {
      final LoginRespuesta r = await Sitram.cambiarPassword(nueva, confirma);
      Sesion.iniciar(r);
      if (!mounted) return;
      aviso(context, 'Contraseña actualizada');
      Navigator.pushNamedAndRemoveUntil(
          context, Sesion.rutaInicio, (x) => false);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Cambiar contraseña',
      atras: true,
      hijos: [
        const Alerta(
            tipo: 'info',
            texto:
                'Debe cambiar la contraseña asignada antes de continuar usando la aplicación.'),
        Campo('Nueva contraseña',
            requerido: true,
            clave: true,
            alCambiar: (v) => setState(() => nueva = v)),
        Campo('Confirmar contraseña',
            requerido: true,
            clave: true,
            error: confirma.isNotEmpty && !coinciden
                ? 'Las dos contraseñas no coinciden.'
                : null,
            alCambiar: (v) => setState(() => confirma = v)),
        Tarjeta(
          color: C.fondo,
          hijos: [
            Text('REQUISITOS', style: archivo(11, c: C.medio, espacio: 1.1)),
            requisito('Mínimo 12 caracteres', tieneDoce),
            requisito('Al menos una mayúscula', tieneMayus),
            requisito('Al menos una minúscula', tieneMinus),
            requisito('Al menos un número', tieneNumero),
          ],
        ),
        Btn(guardando ? 'Guardando...' : 'Guardar nueva contraseña',
            alTocar: valida && !guardando ? guardar : null),
        Btn('Cancelar',
            tipo: 'fantasma', alTocar: () => Navigator.pop(context)),
      ],
    );
  }
}

class _Resumen {
  final int asociados, conductores, vehiculos, planillasHoy, enTaller;
  final Map<String, String> sancionados;
  final List<Planilla> recientes;
  _Resumen(this.asociados, this.conductores, this.vehiculos, this.planillasHoy,
      this.sancionados, this.recientes, this.enTaller);
}

/////////////////////////////////////////////////////////////////

class S04Inicio extends StatefulWidget {
  const S04Inicio({super.key});

  @override
  State<S04Inicio> createState() => _S04InicioState();
}

class _S04InicioState extends State<S04Inicio> {
  Future<_Resumen>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = _traer();
    });
  }

  Future<_Resumen> _traer() async {
    final hoy = hoyIso();
    Pagina<Asociado> asociados = await Sitram.asociados(tam: 1);
    Pagina<Conductor> conductores = await Sitram.conductores(tam: 1);
    Pagina<Vehiculo> vehiculos = await Sitram.vehiculos(tam: 1);
    Pagina<Planilla> planillas = await Sitram.planillas(fecha: hoy, tam: 3);
    Map<String, String> sancionados = await Sitram.sancionadosEn(hoy);
    Pagina<Mantenimiento> enTaller =
        await Sitram.mantenimientos(estado: 'EN_MANTENIMIENTO', tam: 1);
    return _Resumen(
      asociados.total,
      conductores.total,
      vehiculos.total,
      planillas.total,
      sancionados,
      planillas.items,
      enTaller.total,
    );
  }

  Widget acceso(IconData icono, String texto, String ruta) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          await ir(context, ruta);
          cargar();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.borde),
          ),
          child: Column(
            children: [
              Icon(icono, size: 20, color: C.verde),
              const SizedBox(height: 4),
              Text(texto, textAlign: TextAlign.center, style: plex(10.5)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Hola, ${Sesion.username}',
      subtitulo: '${capital(Sesion.rol)} · ${Sesion.empresa}',
      nav: '/s04',
      hijos: [
        Cargar<_Resumen>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Indicador(
                          'Asociados', '${r.asociados}', 'registrados')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Indicador('Conductores', '${r.conductores}',
                          '${r.sancionados.length} sancionados hoy')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: Indicador('Vehículos', '${r.vehiculos}',
                          '${r.enTaller} en mantenimiento')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Indicador('Planillas hoy', '${r.planillasHoy}',
                          fechaVista(hoyIso()),
                          oscuro: true)),
                ],
              ),
              if (r.sancionados.isNotEmpty)
                Alerta(
                  titulo:
                      '${r.sancionados.length} conductor${r.sancionados.length == 1 ? '' : 'es'} sancionado${r.sancionados.length == 1 ? '' : 's'}',
                  texto: 'No pueden ser asignados a planillas hoy.',
                ),
              const Seccion('Accesos rápidos'),
              Row(
                children: [
                  acceso(Icons.description_outlined, 'Nueva planilla', Rutas.nuevaPlanilla),
                  acceso(Icons.directions_bus_outlined, 'Despacho', Rutas.registrarDespacho),
                  acceso(Icons.person_outline, 'Conductores', Rutas.conductores),
                  acceso(Icons.shield_outlined, 'Sanciones', Rutas.sanciones),
                ],
              ),
              const SizedBox(height: 8),
              Seccion('Planillas de hoy',
                  derecha: GestureDetector(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, Rutas.planillas, (x) => false),
                    child: Text('Ver todas',
                        style: plex(12, w: FontWeight.w600, c: C.verde)),
                  )),
              if (r.recientes.isEmpty)
                const Vacio(
                    icono: Icons.description_outlined,
                    titulo: 'Sin planillas hoy',
                    texto: 'Todavía no se ha registrado ninguna planilla.')
              else
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final p in r.recientes)
                      FilaLista(
                        inicio: Caja(p.placaVehiculo.length >= 3
                            ? p.placaVehiculo
                                .substring(p.placaVehiculo.length - 3)
                            : p.placaVehiculo),
                        titulo: '${p.placaVehiculo} · ${p.conductorNombre}',
                        sub:
                            'Nº ${p.numero} · ${horaVista(p.hora)} · ${capital(p.tipo)}',
                        derecha: ChipEstado(capital(p.estado),
                            tipo: tipoDe(capital(p.estado))),
                        alTocar: () async {
                          await ir(context, Rutas.detallePlanilla, p.numero);
                          cargar();
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
