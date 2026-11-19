import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../services/sesion.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/////////////////////////////////////////////////////////////////

class S34MisVehiculos extends StatefulWidget {
  const S34MisVehiculos({super.key});

  @override
  State<S34MisVehiculos> createState() => _S34MisVehiculosState();
}

class _S34MisVehiculosState extends State<S34MisVehiculos> {
  Future<_DatosAsociado>? futuro;

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

  Future<_DatosAsociado> _traer() async {
    final vehiculos = await Sitram.misVehiculos();
    Map<String, String> sancionados = {};
    try {
      sancionados = await Sitram.sancionadosEn(hoyIso());
    } catch (_) {}
    return _DatosAsociado(vehiculos, sancionados);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Mis vehículos',
      subtitulo: Sesion.empresa,
      nav: Rutas.misVehiculos,
      hijos: [
        Cargar<_DatosAsociado>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (d) {
            if (d.vehiculos.isEmpty) {
              return const Vacio(
                  icono: Icons.directions_car_outlined,
                  titulo: 'Sin vehículos',
                  texto: 'No tiene vehículos con afiliación activa.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${d.vehiculos.length} vehículo${d.vehiculos.length == 1 ? '' : 's'} afiliado${d.vehiculos.length == 1 ? '' : 's'} a su cuenta',
                    style: plex(12.5, c: C.medio)),
                const SizedBox(height: 10),
                for (final v in d.vehiculos)
                  Tarjeta(
                    hijos: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(v.placa, style: archivo(20)),
                            Text('${capital(v.tipo)} · ${v.marca} ${v.modelo}', style: plex(12, c: C.tenue)),
                          ]),
                        ),
                        ChipEstado(v.activo ? 'Activo' : 'Inactivo', tipo: v.activo ? 'ok' : 'gris'),
                      ]),
                      const Divider(height: 22, color: C.borde),
                      for (final x in {
                        'Conductor': v.identificacionConductor.isEmpty ? 'Sin asignar' : 'CC ${v.identificacionConductor}',
                        'Fecha de afiliación': fechaVista(v.fechaAfiliacion),
                      }.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(child: Text(x.key, style: plex(12.5, c: C.tenue))),
                            Text(x.value, style: plex(13, w: FontWeight.w600)),
                          ]),
                        ),
                      if (d.sancionados.containsKey(v.identificacionConductor))
                        Alerta(texto: 'Su conductor está sancionado hasta el ${fechaVista(d.sancionados[v.identificacionConductor])}.'),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FiltrosAsociado extends StatelessWidget {
  final TextEditingController desde, hasta;
  final String? placa;
  final List<String> placas;
  final ValueChanged<String?> alCambiarPlaca;
  final VoidCallback alCambiar;
  const _FiltrosAsociado({required this.desde, required this.hasta, required this.placa, required this.placas, required this.alCambiarPlaca, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Dos(
        Campo('Desde', control: desde, sufijo: Icons.calendar_today_outlined, alTocar: () async {
          await elegirFecha(context, desde);
          alCambiar();
        }),
        Campo('Hasta', control: hasta, sufijo: Icons.calendar_today_outlined, alTocar: () async {
          await elegirFecha(context, hasta);
          alCambiar();
        }),
      ),
      CampoLista<String?>('Placa',
          valor: placa,
          hint: 'Todas',
          opciones: [const Opcion(null, 'Todas'), for (final p in placas) Opcion(p, p)],
          alCambiar: alCambiarPlaca),
    ]);
  }
}

String _inicioMes() {
  final h = DateTime.now();
  return fechaVista(isoFecha(DateTime(h.year, h.month, 1)));
}

/////////////////////////////////////////////////////////////////

class S35MisViajes extends StatefulWidget {
  const S35MisViajes({super.key});

  @override
  State<S35MisViajes> createState() => _S35MisViajesState();
}

class _S35MisViajesState extends State<S35MisViajes> {
  final desde = TextEditingController(text: _inicioMes());
  final hasta = TextEditingController(text: fechaVista(hoyIso()));
  String? placa;
  List<String> placas = [];
  int pagina = 1;
  Future<Pagina<Planilla>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
    traerPlacas();
  }

  Future<void> traerPlacas() async {
    try {
      List<VehiculoAsociado> lista = await Sitram.misVehiculos();
      List<String> nuevas = [];
      for (VehiculoAsociado v in lista) {
        nuevas.add(v.placa);
      }
      if (mounted) {
        setState(() {
          placas = nuevas;
        });
      }
    } catch (_) {}
  }

  void cargar() {
    setState(() {
      futuro = Sitram.misViajes(
        pagina: pagina,
        desde: isoDeVista(desde.text),
        hasta: isoDeVista(hasta.text),
        placa: placa,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Mis viajes',
      subtitulo: 'Planillas tipo viaje de sus vehículos',
      nav: Rutas.misViajes,
      hijos: [
        _FiltrosAsociado(
          desde: desde,
          hasta: hasta,
          placa: placa,
          placas: placas,
          alCambiarPlaca: (p) {
            placa = p;
            pagina = 1;
            cargar();
          },
          alCambiar: () {
            pagina = 1;
            cargar();
          },
        ),
        Cargar<Pagina<Planilla>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            final pagado = p.items.fold<double>(0, (s, x) => s + x.valorPagado);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: Indicador('Viajes', '${p.total}', 'En el periodo')),
                  const SizedBox(width: 12),
                  Expanded(child: Indicador('Pagado', pesos(pagado), 'En esta página')),
                ]),
                if (p.items.isEmpty)
                  const Vacio(icono: Icons.route_outlined, titulo: 'Sin viajes', texto: 'No hay viajes en ese periodo.')
                else
                  Tarjeta(
                    pad: 0,
                    hijos: [
                      for (final x in p.items)
                        FilaLista(
                          titulo: '${fechaVista(x.fecha)} · ${horaVista(x.hora)}',
                          sub: '${x.placaVehiculo} · ${x.conductorNombre} · Nº ${x.numero}',
                          derecha: ChipEstado(capital(x.estadoPago), tipo: tipoDe(capital(x.estadoPago))),
                        ),
                    ],
                  ),
                Paginacion(
                    pagina: p.pagina,
                    paginas: p.paginas,
                    alCambiar: (n) {
                      pagina = n;
                      cargar();
                    }),
              ],
            );
          },
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S36MisDespachos extends StatefulWidget {
  const S36MisDespachos({super.key});

  @override
  State<S36MisDespachos> createState() => _S36MisDespachosState();
}

class _S36MisDespachosState extends State<S36MisDespachos> {
  final desde = TextEditingController(text: _inicioMes());
  final hasta = TextEditingController(text: fechaVista(hoyIso()));
  String? placa;
  List<String> placas = [];
  int pagina = 1;
  Future<Pagina<Despacho>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
    traerPlacas();
  }

  Future<void> traerPlacas() async {
    try {
      List<VehiculoAsociado> lista = await Sitram.misVehiculos();
      List<String> nuevas = [];
      for (VehiculoAsociado v in lista) {
        nuevas.add(v.placa);
      }
      if (mounted) {
        setState(() {
          placas = nuevas;
        });
      }
    } catch (_) {}
  }

  void cargar() {
    setState(() {
      futuro = Sitram.misDespachos(
        pagina: pagina,
        desde: isoDeVista(desde.text),
        hasta: isoDeVista(hasta.text),
        placa: placa,
      );
    });
  }

  void limpiar() {
    desde.text = _inicioMes();
    hasta.text = fechaVista(hoyIso());
    placa = null;
    pagina = 1;
    cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Mis despachos',
      subtitulo: 'Despachos de sus vehículos',
      nav: Rutas.misDespachos,
      hijos: [
        _FiltrosAsociado(
          desde: desde,
          hasta: hasta,
          placa: placa,
          placas: placas,
          alCambiarPlaca: (p) {
            placa = p;
            pagina = 1;
            cargar();
          },
          alCambiar: () {
            pagina = 1;
            cargar();
          },
        ),
        Cargar<Pagina<Despacho>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return Vacio(
                icono: Icons.location_on_outlined,
                titulo: 'Sin despachos',
                texto: 'No hay despachos registrados${placa == null ? '' : ' para $placa'} entre ${desde.text} y ${hasta.text}.',
                textoBoton: 'Limpiar filtros',
                alTocar: limpiar,
              );
            }
            return Column(children: [
              Tarjeta(
                pad: 0,
                hijos: [
                  for (final d in p.items)
                    FilaLista(
                      inicio: SizedBox(
                        width: 40,
                        child: Column(children: [
                          Text('${d.numeroPasajeros}', style: archivo(15)),
                          Text('pas.', style: plex(10, c: C.tenue)),
                        ]),
                      ),
                      titulo: '${fechaVista(d.fecha)} · ${horaVista(d.hora)}',
                      sub: '${d.ruta} · ${d.placaVehiculo}',
                      derecha: d.estado == 'CANCELADO' ? const ChipEstado('Cancelado', tipo: 'mal') : null,
                    ),
                ],
              ),
              Paginacion(
                  pagina: p.pagina,
                  paginas: p.paginas,
                  alCambiar: (n) {
                    pagina = n;
                    cargar();
                  }),
            ]);
          },
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S37MiCuenta extends StatelessWidget {
  const S37MiCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Mi cuenta',
      nav: Rutas.miCuenta,
      hijos: [
        Tarjeta(hijos: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Sesion.username, style: archivo(16)),
                Text('CC ${Sesion.identificacion} · ${Sesion.rol}', style: plex(12, c: C.tenue)),
                Text('${Sesion.empresa}${Sesion.nit.isEmpty ? '' : ' · NIT ${Sesion.nit}'}', style: plex(12, c: C.tenue)),
              ]),
            ),
            Avatar(iniciales(Sesion.username.replaceAll('.', ' '))),
          ]),
        ]),
        const Seccion('Sesión activa'),
        TarjetaDatos({
          'Rol recibido': Sesion.rol,
          'Inicio de sesión': Sesion.inicio == null ? '—' : fechaHoraVista(Sesion.inicio!.toIso8601String()),
          'Token expira': Sesion.expira == null ? '—' : fechaHoraVista(Sesion.expira!.toIso8601String()),
        }),
        const Alerta(tipo: 'info', texto: 'Al cerrar sesión se borra el token y los datos de autenticación del dispositivo.'),
        const SizedBox(height: 10),
        Btn('Cerrar sesión', tipo: 'peligro', icono: Icons.logout, alTocar: () {
          Sesion.cerrar();
          Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (r) => false);
        }),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S38SesionExpirada extends StatelessWidget {
  const S38SesionExpirada({super.key});

  Widget gris(double ancho) {
    return Container(
      height: 12,
      width: ancho,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: C.borde, borderRadius: BorderRadius.circular(6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: C.fondo,
          appBar: AppBar(backgroundColor: C.verde, toolbarHeight: 70, automaticallyImplyLeading: false),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: C.borde, borderRadius: BorderRadius.circular(14)),
              ),
              Tarjeta(hijos: [gris(160), gris(220), const SizedBox(height: 10), gris(180), gris(240)]),
            ],
          ),
        ),
        Container(color: Colors.black45),
        Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: C.advertencia.withAlpha(30), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_clock_outlined, color: C.advertencia),
                  ),
                  const SizedBox(height: 12),
                  Text('Su sesión expiró', style: archivo(17)),
                  const SizedBox(height: 6),
                  Text('Por seguridad debe iniciar sesión de nuevo para continuar.',
                      textAlign: TextAlign.center, style: plex(13, c: C.medio)),
                  const SizedBox(height: 16),
                  Btn('Iniciar sesión', alTocar: () => Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (r) => false)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatosAsociado {
  final List<VehiculoAsociado> vehiculos;
  final Map<String, String> sancionados;
  _DatosAsociado(this.vehiculos, this.sancionados);
}
