import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../models/requests.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/////////////////////////////////////////////////////////////////

class S39Pagos extends StatefulWidget {
  const S39Pagos({super.key});

  @override
  State<S39Pagos> createState() => _S39PagosState();
}

class _S39PagosState extends State<S39Pagos> {
  int pagina = 1;
  String? buscar;
  final desde = TextEditingController();
  final hasta = TextEditingController();
  Future<Pagina<Pago>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    final t = buscar?.trim() ?? '';
    final numero = int.tryParse(t);
    setState(() {
      futuro = Sitram.pagos(
        pagina: pagina,
        numeroPlanilla: numero,
        placa: numero == null ? t.toUpperCase() : null,
        desde: desde.text.isEmpty ? null : isoDeVista(desde.text),
        hasta: hasta.text.isEmpty ? null : isoDeVista(hasta.text),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Operación',
      tabs: tabsOperacion,
      tabActual: Rutas.pagos,
      nav: Rutas.vehiculos,
      hijos: [
        Buscador(
            hint: 'Número de planilla o placa',
            alBuscar: (t) {
              buscar = t;
              pagina = 1;
              cargar();
            }),
        Dos(
          Campo('Pagos desde',
              control: desde,
              hint: 'Todas',
              sufijo: Icons.calendar_today_outlined, alTocar: () async {
            await elegirFecha(context, desde);
            pagina = 1;
            cargar();
          }),
          Campo('Hasta',
              control: hasta,
              hint: 'Todas',
              sufijo: Icons.calendar_today_outlined, alTocar: () async {
            await elegirFecha(context, hasta);
            pagina = 1;
            cargar();
          }),
        ),
        if (desde.text.isNotEmpty || hasta.text.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                desde.clear();
                hasta.clear();
                pagina = 1;
                cargar();
              },
              child: Text('Quitar fechas',
                  style: plex(12, w: FontWeight.w600, c: C.verde)),
            ),
          ),
        Cargar<Pagina<Pago>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(
                  icono: Icons.payments_outlined,
                  titulo: 'Sin pagos',
                  texto:
                      'Los pagos se registran desde el detalle de cada planilla.');
            }
            final suma = p.items.fold<double>(0, (s, x) => s + x.valorPagado);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                      child: Indicador(
                          'Pagos', '${p.total}', 'con estos filtros')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Indicador(
                          'Recaudado', pesos(suma), 'en esta página',
                          oscuro: true)),
                ]),
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final x in p.items)
                      FilaLista(
                        inicio: const Caja('\$'),
                        titulo: 'Planilla Nº ${x.numeroPlanilla}',
                        sub:
                            'Pagada el ${fechaVista(x.fechaPago)} · ${x.registradoPor}',
                        derecha: Text(pesos(x.valorPagado),
                            style: plex(13, w: FontWeight.w700, c: C.verde)),
                        alTocar: () => ir(context, Rutas.detallePago, x.id),
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

class S40DetallePago extends StatefulWidget {
  final int id;
  const S40DetallePago({super.key, required this.id});

  @override
  State<S40DetallePago> createState() => _S40DetallePagoState();
}

class _S40DetallePagoState extends State<S40DetallePago> {
  Future<Pago>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.pago(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de pago',
      atras: true,
      hijos: [
        Cargar<Pago>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(
                color: C.verdeHondo,
                borde: C.verdeHondo,
                hijos: [
                  Text('VALOR PAGADO',
                      style: archivo(10.5, c: Colors.white70, espacio: 1)),
                  Text(pesos(p.valorPagado),
                      style: archivo(30, c: Colors.white)),
                  Text('Tomado del total de la tarifa de la planilla',
                      style: plex(11.5, c: Colors.white60)),
                ],
              ),
              const Seccion('Datos del pago'),
              TarjetaDatos({
                'ID': 'PG-${p.id}',
                'Planilla': 'Nº ${p.numeroPlanilla}',
                'Fecha de pago': fechaVista(p.fechaPago),
              }),
              const Seccion('Registro'),
              TarjetaDatos({
                'Registró': p.registradoPor,
                'Fecha de registro': fechaHoraVista(p.fechaRegistro)
              }),
              Btn('Ver planilla',
                  tipo: 'contorno',
                  alTocar: () => ir(context, Rutas.detallePlanilla, p.numeroPlanilla)),
            ],
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S41Mantenimientos extends StatefulWidget {
  const S41Mantenimientos({super.key});

  @override
  State<S41Mantenimientos> createState() => _S41MantenimientosState();
}

class _S41MantenimientosState extends State<S41Mantenimientos> {
  int pagina = 1;
  String? estado = 'EN_MANTENIMIENTO';
  String? placa;
  Future<Pagina<Mantenimiento>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.mantenimientos(
          pagina: pagina, placa: placa?.toUpperCase(), estado: estado);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Operación',
      tabs: tabsOperacion,
      tabActual: Rutas.mantenimientos,
      nav: Rutas.vehiculos,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.ingresoTaller) == true) cargar();
      }),
      hijos: [
        Buscador(
            hint: 'Buscar por placa',
            alBuscar: (t) {
              placa = t;
              pagina = 1;
              cargar();
            }),
        Filtros(['En taller', 'Finalizados', 'Todos'], alCambiar: (i) {
          estado = ['EN_MANTENIMIENTO', 'FINALIZADO', null][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Mantenimiento>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(
                  icono: Icons.build_outlined,
                  titulo: 'Sin mantenimientos',
                  texto: 'No hay vehículos con ese filtro.');
            }
            return Column(children: [
              Tarjeta(
                pad: 0,
                hijos: [
                  for (final m in p.items)
                    FilaLista(
                      marcada: m.abierto,
                      colorMarca: C.advertencia,
                      inicio: const Caja('MT'),
                      titulo: '${m.placaVehiculo} · ${m.motivo}',
                      sub: m.abierto
                          ? 'Ingresó ${fechaHoraVista(m.fechaIngreso)}'
                          : '${fechaHoraVista(m.fechaIngreso)} → ${fechaHoraVista(m.fechaSalida)}',
                      derecha: m.abierto
                          ? const ChipEstado('En taller', tipo: 'warn')
                          : const ChipEstado('Finalizado', tipo: 'gris'),
                      alTocar: () async {
                        await ir(context, Rutas.detalleMantenimiento, m.id);
                        cargar();
                      },
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

class S42IngresoTaller extends StatefulWidget {
  final String? placa;
  const S42IngresoTaller({super.key, this.placa});

  @override
  State<S42IngresoTaller> createState() => _S42IngresoTallerState();
}

class _S42IngresoTallerState extends State<S42IngresoTaller> {
  Future<_OpcionesTaller>? futuro;
  late String? placa = widget.placa;
  final fecha = TextEditingController(text: fechaVista(hoyIso()));
  final hora = TextEditingController(text: horaActual());
  final motivo = TextEditingController();
  final estadoFisico = TextEditingController();
  final observaciones = TextEditingController();
  bool guardando = false;

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

  Future<_OpcionesTaller> _traer() async {
    Pagina<Vehiculo> vehiculos = await Sitram.vehiculos(tam: 100);
    Set<String> enTaller = await Sitram.placasEnTaller();
    return _OpcionesTaller(vehiculos.items, enTaller);
  }

  Future<void> guardar() async {
    if (faltanCampos(context, {
      'Vehículo': placa ?? '',
      'Motivo': motivo.text,
      'Estado del vehículo': estadoFisico.text,
    })) return;
    final cuando = fechaHoraConZona(fecha.text, hora.text);
    if (cuando == null) {
      aviso(context, 'Revise la fecha y la hora de ingreso', error: true);
      return;
    }
    setState(() => guardando = true);
    try {
      await Sitram.registrarIngreso(MantenimientoRequest(
        placaVehiculo: placa!,
        fechaIngreso: cuando,
        motivo: motivo.text.trim(),
        estadoVehiculoIngreso: estadoFisico.text.trim(),
        observaciones: observaciones.text.trim().isEmpty
            ? null
            : observaciones.text.trim(),
      ));
      if (!mounted) return;
      aviso(context, 'Ingreso al taller registrado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Ingreso a mantenimiento',
      atras: true,
      hijos: [
        Cargar<_OpcionesTaller>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (d) => CampoLista<String>('Vehículo',
              requerido: true,
              valor: placa,
              opciones: [
                for (final v in d.vehiculos)
                  Opcion(
                      v.placa,
                      d.enTaller.contains(v.placa.toUpperCase())
                          ? '${v.placa} · ya está en el taller'
                          : '${v.placa} — ${capital(v.tipo)}',
                      !d.enTaller.contains(v.placa.toUpperCase())),
              ],
              alCambiar: (x) => setState(() => placa = x)),
        ),
        Dos(
          Campo('Fecha de ingreso',
              requerido: true,
              control: fecha,
              sufijo: Icons.calendar_today_outlined,
              alTocar: () => elegirFecha(context, fecha)),
          Campo('Hora',
              requerido: true,
              control: hora,
              sufijo: Icons.schedule,
              alTocar: () => elegirHora(context, hora)),
        ),
        Campo('Motivo',
            requerido: true, control: motivo, hint: 'Ej: Revisión de frenos'),
        Campo('Estado del vehículo al ingresar',
            requerido: true,
            control: estadoFisico,
            hint: 'Ej: Ruido al frenar'),
        Campo('Observaciones', control: observaciones, lineas: 3),
        const Alerta(
            tipo: 'warn',
            texto:
                'Mientras esté en mantenimiento, el vehículo no podrá recibir planillas ni despachos.'),
      ],
      abajo: BotonesForm(
          ok: guardando ? 'Guardando...' : 'Registrar ingreso',
          alGuardar: guardando ? null : guardar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S43DetalleMantenimiento extends StatefulWidget {
  final int id;
  const S43DetalleMantenimiento({super.key, required this.id});

  @override
  State<S43DetalleMantenimiento> createState() =>
      _S43DetalleMantenimientoState();
}

class _S43DetalleMantenimientoState extends State<S43DetalleMantenimiento> {
  Future<Mantenimiento>? futuro;
  final fecha = TextEditingController(text: fechaVista(hoyIso()));
  final hora = TextEditingController(text: horaActual());
  final observaciones = TextEditingController();
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.mantenimiento(widget.id);
    });
  }

  Future<void> registrarSalida() async {
    final cuando = fechaHoraConZona(fecha.text, hora.text);
    if (cuando == null) {
      aviso(context, 'Revise la fecha y la hora de salida', error: true);
      return;
    }
    setState(() => guardando = true);
    try {
      await Sitram.registrarSalida(
          widget.id,
          SalidaMantenimientoRequest(
              cuando,
              observaciones.text.trim().isEmpty
                  ? null
                  : observaciones.text.trim()));
      if (!mounted) return;
      aviso(context, 'Salida registrada. El vehículo puede volver a operar.');
      cargar();
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de mantenimiento',
      atras: true,
      hijos: [
        Cargar<Mantenimiento>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (m) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(
                color: m.abierto ? const Color(0xFFFFF4E0) : Colors.white,
                borde: m.abierto ? const Color(0xFFF0D7A8) : C.borde,
                hijos: [
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESTADO',
                                style: archivo(10.5,
                                    c: m.abierto ? C.advertencia : C.medio,
                                    espacio: 1)),
                            Text(m.abierto ? 'En mantenimiento' : 'Finalizado',
                                style: archivo(22,
                                    c: m.abierto ? C.advertencia : C.texto)),
                            if (m.abierto)
                              Text(
                                  'El vehículo ${m.placaVehiculo} está bloqueado para operar',
                                  style: plex(12, c: C.advertencia)),
                          ]),
                    ),
                    Icon(Icons.build_outlined,
                        color: m.abierto ? C.advertencia : C.tenue, size: 30),
                  ]),
                ],
              ),
              const Seccion('Ingreso'),
              TarjetaDatos({
                'Vehículo': m.placaVehiculo,
                'Fecha de ingreso': fechaHoraVista(m.fechaIngreso),
                'Motivo': m.motivo,
                'Estado al ingresar': m.estadoVehiculoIngreso,
                'Observaciones': m.observacionesIngreso.isEmpty
                    ? '—'
                    : m.observacionesIngreso,
                'Registró': m.registradoPor,
              }),
              if (!m.abierto) ...[
                const Seccion('Salida'),
                TarjetaDatos({
                  'Fecha de salida': fechaHoraVista(m.fechaSalida),
                  'Observaciones':
                      m.observaciones.isEmpty ? '—' : m.observaciones,
                  'Registró': m.salidaRegistradaPor.isEmpty
                      ? '—'
                      : m.salidaRegistradaPor,
                }),
              ],
              Btn('Ver vehículo',
                  tipo: 'contorno',
                  alTocar: () => ir(context, Rutas.detalleVehiculo, m.placaVehiculo)),
              if (m.abierto) ...[
                const Seccion('Registrar salida'),
                Dos(
                  Campo('Fecha de salida',
                      control: fecha,
                      sufijo: Icons.calendar_today_outlined,
                      alTocar: () => elegirFecha(context, fecha)),
                  Campo('Hora',
                      control: hora,
                      sufijo: Icons.schedule,
                      alTocar: () => elegirHora(context, hora)),
                ),
                Campo('Observaciones de salida',
                    control: observaciones,
                    hint: 'Ej: Prueba de funcionamiento satisfactoria',
                    lineas: 2),
                Btn(guardando ? 'Guardando...' : 'Registrar salida',
                    alTocar: guardando ? null : registrarSalida),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OpcionesTaller {
  final List<Vehiculo> vehiculos;
  final Set<String> enTaller;
  _OpcionesTaller(this.vehiculos, this.enTaller);
}
