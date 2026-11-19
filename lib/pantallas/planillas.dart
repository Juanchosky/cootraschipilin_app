import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../models/requests.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

const _tiposPlanilla = [
  Opcion('VIAJE', 'Viaje'),
  Opcion('DESPACHO', 'Despacho'),
  Opcion('ESPECIAL', 'Especial'),
];

class _OpcionesPlanilla {
  final List<Vehiculo> vehiculos;
  final List<Tarifa> tarifas;
  final List<Sancion> sanciones;
  final Map<String, String> nombres;
  final Set<String> enTaller;
  _OpcionesPlanilla(this.vehiculos, this.tarifas, this.sanciones, this.nombres,
      this.enTaller);

  Sancion? sancionDe(String conductor, String fechaIso) {
    for (final s in sanciones) {
      if (s.identificacionConductor == conductor && s.vigenteEn(fechaIso))
        return s;
    }
    return null;
  }
}

Future<_OpcionesPlanilla> _traerOpciones() async {
  Pagina<Vehiculo> vehiculos = await Sitram.vehiculos(tam: 100);
  Pagina<Tarifa> tarifas = await Sitram.tarifas(activo: true, tam: 100);
  List<Sancion> sanciones = await Sitram.sancionesActivas();
  Pagina<Conductor> conductores = await Sitram.conductores(tam: 100);
  Set<String> enTaller = await Sitram.placasEnTaller();

  List<Vehiculo> activos = [];
  for (Vehiculo v in vehiculos.items) {
    if (v.activo) activos.add(v);
  }
  Map<String, String> nombres = {};
  for (Conductor c in conductores.items) {
    nombres[c.identificacion] = c.nombres;
  }
  return _OpcionesPlanilla(
      activos, tarifas.items, sanciones, nombres, enTaller);
}

/////////////////////////////////////////////////////////////////

class S23Planillas extends StatefulWidget {
  const S23Planillas({super.key});

  @override
  State<S23Planillas> createState() => _S23PlanillasState();
}

class _S23PlanillasState extends State<S23Planillas> {
  int pagina = 1;
  String? estado;
  String? placa;
  final fecha = TextEditingController();
  Future<Pagina<Planilla>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.planillas(
        pagina: pagina,
        fecha: fecha.text.isEmpty ? null : isoDeVista(fecha.text),
        vehiculo: placa?.toUpperCase(),
        estado: estado,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Operación',
      tabs: tabsOperacion,
      tabActual: Rutas.planillas,
      nav: Rutas.vehiculos,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.nuevaPlanilla) == true) cargar();
      }),
      hijos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Campo('Fecha',
                  control: fecha,
                  hint: 'Todas',
                  sufijo: Icons.calendar_today_outlined, alTocar: () async {
                await elegirFecha(context, fecha);
                pagina = 1;
                cargar();
              }),
            ),
            if (fecha.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: IconButton(
                  tooltip: 'Quitar fecha',
                  icon: const Icon(Icons.close, color: C.tenue),
                  onPressed: () {
                    fecha.clear();
                    pagina = 1;
                    cargar();
                  },
                ),
              ),
          ],
        ),
        Buscador(
            hint: 'Buscar por placa',
            alBuscar: (t) {
              placa = t;
              pagina = 1;
              cargar();
            }),
        Filtros(['Todas', 'Activas', 'Finalizadas', 'Anuladas'],
            alCambiar: (i) {
          estado = [null, 'ACTIVA', 'FINALIZADA', 'ANULADA'][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Planilla>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (p.items.isEmpty)
                const Vacio(
                    icono: Icons.description_outlined,
                    titulo: 'Sin planillas',
                    texto: 'No hay planillas con esos filtros.')
              else
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final x in p.items)
                      FilaLista(
                        titulo: 'Nº ${x.numero} · ${x.placaVehiculo}',
                        sub:
                            '${fechaVista(x.fecha)} ${horaVista(x.hora)} · ${x.conductorNombre} · ${capital(x.tipo)}\n'
                            'Pago ${capital(x.estadoPago).toLowerCase()}',
                        derecha: ChipEstado(capital(x.estado),
                            tipo: tipoDe(capital(x.estado))),
                        alTocar: () async {
                          await ir(context, Rutas.detallePlanilla, x.numero);
                          cargar();
                        },
                      ),
                  ],
                ),
              Btn('Generación masiva', tipo: 'contorno', alTocar: () async {
                if (await ir(context, Rutas.generacionMasiva) == true) cargar();
              }),
              Paginacion(
                  pagina: p.pagina,
                  paginas: p.paginas,
                  alCambiar: (n) {
                    pagina = n;
                    cargar();
                  }),
            ],
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S24NuevaPlanilla extends StatefulWidget {
  const S24NuevaPlanilla({super.key});

  @override
  State<S24NuevaPlanilla> createState() => _S24NuevaPlanillaState();
}

/////////////////////////////////////////////////////////////////

class _S24NuevaPlanillaState extends State<S24NuevaPlanilla> {
  Future<_OpcionesPlanilla>? futuro;
  _OpcionesPlanilla? op;
  final fecha = TextEditingController(text: fechaVista(hoyIso()));
  String? placa;
  String tipo = 'VIAJE';
  int? tarifaId;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargar();
    fecha.addListener(() => setState(() {}));
  }

  void cargar() {
    setState(() {
      futuro = _traer();
    });
  }

  Future<_OpcionesPlanilla> _traer() async {
    _OpcionesPlanilla o = await _traerOpciones();
    op = o;
    return o;
  }

  Vehiculo? get vehiculo {
    if (op == null || placa == null) return null;
    for (final v in op!.vehiculos) {
      if (v.placa == placa) return v;
    }
    return null;
  }

  Sancion? get sancion {
    final v = vehiculo;
    final f = isoDeVista(fecha.text);
    if (v == null || !v.tieneConductor || f == null) return null;
    return op!.sancionDe(v.identificacionConductor, f);
  }

  bool get enTaller =>
      vehiculo != null && op!.enTaller.contains(vehiculo!.placa.toUpperCase());

  bool get puedeGuardar =>
      vehiculo != null &&
      vehiculo!.tieneConductor &&
      sancion == null &&
      !enTaller &&
      tarifaId != null;

  Future<void> guardar() async {
    setState(() => guardando = true);
    try {
      final p = await Sitram.crearPlanilla(PlanillaRequest(
        fecha: isoDeVista(fecha.text)!,
        placaVehiculo: placa!,
        tipo: tipo,
        tarifaId: tarifaId,
      ));
      if (!mounted) return;
      aviso(context, 'Planilla Nº ${p.numero} creada');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  Widget tarjetaConductor() {
    final v = vehiculo;
    if (v == null) return const SizedBox();
    if (enTaller) {
      return const Alerta(
        tipo: 'warn',
        titulo: 'Vehículo en mantenimiento',
        texto:
            'No se le pueden crear planillas hasta que se registre la salida del taller.',
      );
    }
    if (!v.tieneConductor) {
      return const Alerta(
        tipo: 'warn',
        titulo: 'Vehículo sin conductor',
        texto: 'Asigne un conductor al vehículo antes de crear la planilla.',
      );
    }
    final s = sancion;
    final nombre = op!.nombres[v.identificacionConductor] ??
        'CC ${v.identificacionConductor}';
    return Tarjeta(
      borde: s != null ? C.error : C.borde,
      hijos: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: plex(13.5, w: FontWeight.w600)),
              Text(
                s != null
                    ? 'Sancionado hasta ${fechaVista(s.fechaFin)}'
                    : 'Conductor disponible',
                style: plex(12,
                    w: FontWeight.w600, c: s != null ? C.error : C.exito),
              ),
            ]),
          ),
          Avatar(iniciales(nombre), alerta: s != null),
        ]),
        if (s != null) ...[
          const SizedBox(height: 10),
          const Alerta(
            titulo: 'No se puede crear la planilla',
            texto:
                'El conductor asignado a este vehículo tiene sanción vigente. Asigne otro conductor o elija otro vehículo.',
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Nueva planilla',
      atras: true,
      hijos: [
        Cargar<_OpcionesPlanilla>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (o) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Campo('Fecha',
                  requerido: true,
                  control: fecha,
                  sufijo: Icons.calendar_today_outlined,
                  alTocar: () => elegirFecha(context, fecha)),
              CampoLista<String>('Vehículo',
                  requerido: true,
                  valor: placa,
                  opciones: [
                    for (final v in o.vehiculos)
                      Opcion(v.placa,
                          '${v.placa} — ${capital(v.tipo)}${o.enTaller.contains(v.placa.toUpperCase()) ? ' · en mantenimiento' : ''}'),
                  ],
                  alCambiar: (x) => setState(() {
                        placa = x;
                        tarifaId = vehiculo?.tarifaId ?? tarifaId;
                      })),
              tarjetaConductor(),
              CampoLista<String>('Tipo',
                  requerido: true,
                  valor: tipo,
                  opciones: _tiposPlanilla,
                  alCambiar: (x) => setState(() => tipo = x ?? 'VIAJE'),
                  ayuda: 'Opciones: VIAJE · DESPACHO · ESPECIAL'),
              CampoLista<int>('Tarifa',
                  requerido: true,
                  valor: tarifaId,
                  opciones: [
                    for (final t in o.tarifas)
                      Opcion(t.id, 'Tarifa #${t.id} · ${pesos(t.total)}')
                  ],
                  alCambiar: (x) => setState(() => tarifaId = x)),
              const Campo('Estado', valor: 'Activa', soloLectura: true),
            ],
          ),
        ),
      ],
      abajo: BotonesForm(
          ok: guardando ? 'Guardando...' : 'Guardar',
          alGuardar: puedeGuardar && !guardando ? guardar : null),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S25GeneracionMasiva extends StatefulWidget {
  const S25GeneracionMasiva({super.key});

  @override
  State<S25GeneracionMasiva> createState() => _S25GeneracionMasivaState();
}

class _S25GeneracionMasivaState extends State<S25GeneracionMasiva> {
  Future<_OpcionesPlanilla>? futuro;
  _OpcionesPlanilla? op;
  final fecha = TextEditingController(text: fechaVista(hoyIso()));
  String tipo = 'VIAJE';
  int? tarifaId;
  final marcadas = <String>{};
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargar();
    fecha.addListener(
        () => setState(() => marcadas.removeWhere((p) => !disponible(p))));
  }

  void cargar() {
    setState(() {
      futuro = _traer();
    });
  }

  Future<_OpcionesPlanilla> _traer() async {
    _OpcionesPlanilla o = await _traerOpciones();
    op = o;
    marcadas.clear();
    for (Vehiculo v in o.vehiculos) {
      if (disponible(v.placa)) marcadas.add(v.placa);
    }
    return o;
  }

  String? motivoBloqueo(Vehiculo v) {
    if (op != null && op!.enTaller.contains(v.placa.toUpperCase()))
      return 'En mantenimiento';
    if (!v.tieneConductor) return 'Sin conductor asignado';
    final f = isoDeVista(fecha.text) ?? hoyIso();
    final s = op?.sancionDe(v.identificacionConductor, f);
    if (s != null) {
      final nombre = op!.nombres[v.identificacionConductor] ?? 'Conductor';
      return '$nombre · sancionado hasta ${fechaVista(s.fechaFin)}';
    }
    return null;
  }

  bool disponible(String placa) {
    if (op == null) return false;
    final v = op!.vehiculos.where((x) => x.placa == placa);
    return v.isNotEmpty && motivoBloqueo(v.first) == null;
  }

  Future<void> generar() async {
    setState(() => guardando = true);
    try {
      final r = await Sitram.crearPlanillasMasivas(PlanillaMasivaRequest(
        fecha: isoDeVista(fecha.text)!,
        tipo: tipo,
        placasVehiculos: marcadas.toList(),
        tarifaId: tarifaId,
      ));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
              'Registradas ${r.totalRegistradas} de ${r.totalSolicitadas}',
              style: archivo(17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.rechazos.isEmpty)
                Text('Todas las planillas se generaron.', style: plex(13)),
              if (r.rechazos.isNotEmpty) ...[
                Text('Rechazadas (${r.totalRechazadas}):',
                    style: plex(13, w: FontWeight.w600, c: C.error)),
                const SizedBox(height: 6),
                for (final x in r.rechazos) Text('• $x', style: plex(12.5)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Listo'))
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Generación masiva',
      atras: true,
      hijos: [
        Cargar<_OpcionesPlanilla>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (o) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Dos(
                Campo('Fecha',
                    requerido: true,
                    control: fecha,
                    sufijo: Icons.calendar_today_outlined,
                    alTocar: () => elegirFecha(context, fecha)),
                CampoLista<String>('Tipo',
                    requerido: true,
                    valor: tipo,
                    opciones: _tiposPlanilla,
                    alCambiar: (x) => setState(() => tipo = x ?? 'VIAJE')),
              ),
              CampoLista<int?>('Tarifa',
                  valor: tarifaId,
                  hint: 'La tarifa de cada vehículo',
                  opciones: [
                    const Opcion(null, 'La tarifa de cada vehículo'),
                    for (final t in o.tarifas)
                      Opcion(t.id, 'Tarifa #${t.id} · ${pesos(t.total)}'),
                  ],
                  alCambiar: (x) => setState(() => tarifaId = x)),
              Seccion('Vehículos',
                  derecha: GestureDetector(
                    onTap: () => setState(() => marcadas.addAll(
                        o.vehiculos.map((v) => v.placa).where(disponible))),
                    child: Text('Seleccionar todos',
                        style: plex(12, w: FontWeight.w600, c: C.verde)),
                  )),
              if (o.vehiculos.isEmpty)
                const Vacio(
                    titulo: 'Sin vehículos activos',
                    texto: 'Registre vehículos para generar planillas.')
              else
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final v in o.vehiculos)
                      CheckboxListTile(
                        value: marcadas.contains(v.placa),
                        activeColor: C.verde,
                        onChanged: motivoBloqueo(v) != null
                            ? null
                            : (x) => setState(() {
                                  if (x == true) {
                                    marcadas.add(v.placa);
                                  } else {
                                    marcadas.remove(v.placa);
                                  }
                                }),
                        title: Text(v.placa,
                            style: plex(13.5,
                                w: FontWeight.w600,
                                c: motivoBloqueo(v) == null
                                    ? C.texto
                                    : C.tenue)),
                        subtitle: Text(
                          motivoBloqueo(v) ??
                              (o.nombres[v.identificacionConductor] ??
                                  'CC ${v.identificacionConductor}'),
                          style: plex(12,
                              c: motivoBloqueo(v) == null ? C.tenue : C.error),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
      abajo: Btn(
          guardando ? 'Generando...' : 'Generar planillas (${marcadas.length})',
          alTocar: marcadas.isEmpty || guardando ? null : generar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S26DetallePlanilla extends StatefulWidget {
  final int numero;
  const S26DetallePlanilla({super.key, required this.numero});

  @override
  State<S26DetallePlanilla> createState() => _S26DetallePlanillaState();
}

class _S26DetallePlanillaState extends State<S26DetallePlanilla> {
  Future<Planilla>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.planilla(widget.numero);
    });
  }

  void anular() {
    confirmar(context,
        titulo: '¿Anular la planilla?',
        texto:
            'La planilla queda ANULADA. Se conservan el historial y los pagos.',
        ok: 'Sí, anular', alAceptar: () async {
      try {
        await Sitram.anularPlanilla(widget.numero);
        if (!mounted) return;
        aviso(context, 'Planilla anulada');
        cargar();
      } catch (e) {
        if (mounted) aviso(context, '$e', error: true);
      }
    });
  }

  Future<void> pagar() async {
    try {
      await Sitram.registrarPago(widget.numero);
      if (!mounted) return;
      aviso(context, 'Pago registrado');
      cargar();
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Planilla Nº ${widget.numero}',
      atras: true,
      hijos: [
        Cargar<Planilla>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(hijos: [
                Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ESTADO',
                              style: archivo(10.5, c: C.medio, espacio: 1)),
                          Text(capital(p.estado), style: archivo(20)),
                        ]),
                  ),
                  ChipEstado(capital(p.estado),
                      tipo: tipoDe(capital(p.estado))),
                ]),
              ]),
              const Seccion('Datos de la planilla'),
              TarjetaDatos({
                'Número': '${p.numero}',
                'Fecha': fechaVista(p.fecha),
                'Hora': horaVista(p.hora),
                'Tipo': capital(p.tipo),
                'Vehículo': p.placaVehiculo,
                'Conductor':
                    p.conductorNombre.isEmpty ? '—' : p.conductorNombre,
                'Tarifa': p.tarifaId == null ? '—' : '#${p.tarifaId}',
              }),
              const Seccion('Pago'),
              TarjetaDatos({
                'Estado del pago': ChipEstado(capital(p.estadoPago),
                    tipo: tipoDe(capital(p.estadoPago))),
                'Valor pagado': pesos(p.valorPagado),
                'Fecha de pago': fechaVista(p.fechaPago),
              }),
              const Seccion('Trazabilidad'),
              TarjetaDatos({
                'Registró': p.registradoPor,
                'Fecha de registro': fechaHoraVista(p.fechaRegistro)
              }),
              Btn('Ver vehículo',
                  tipo: 'contorno',
                  alTocar: () => ir(context, Rutas.detalleVehiculo, p.placaVehiculo)),
              if (p.estado != 'ANULADA' && p.estadoPago != 'PAGADA')
                Btn('Registrar pago de hoy', alTocar: pagar),
              if (p.estado != 'ANULADA')
                Btn('Anular planilla', tipo: 'peligro', alTocar: anular),
            ],
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S27Despachos extends StatefulWidget {
  const S27Despachos({super.key});

  @override
  State<S27Despachos> createState() => _S27DespachosState();
}

class _S27DespachosState extends State<S27Despachos> {
  int pagina = 1;
  String? ruta;
  final fecha = TextEditingController();
  Future<Pagina<Despacho>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.despachos(
        pagina: pagina,
        fecha: fecha.text.isEmpty ? null : isoDeVista(fecha.text),
        ruta: ruta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Operación',
      tabs: tabsOperacion,
      tabActual: Rutas.despachos,
      nav: Rutas.vehiculos,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.registrarDespacho) == true) cargar();
      }),
      hijos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Campo('Fecha',
                  control: fecha,
                  hint: 'Todas',
                  sufijo: Icons.calendar_today_outlined, alTocar: () async {
                await elegirFecha(context, fecha);
                pagina = 1;
                cargar();
              }),
            ),
            if (fecha.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: IconButton(
                  icon: const Icon(Icons.close, color: C.tenue),
                  onPressed: () {
                    fecha.clear();
                    pagina = 1;
                    cargar();
                  },
                ),
              ),
          ],
        ),
        Buscador(
            hint: 'Buscar por ruta',
            alBuscar: (t) {
              ruta = t;
              pagina = 1;
              cargar();
            }),
        Cargar<Pagina<Despacho>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(
                  icono: Icons.location_on_outlined,
                  titulo: 'Sin despachos',
                  texto: 'No hay despachos con esos filtros.');
            }
            return Column(
              children: [
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final d in p.items)
                      FilaLista(
                        inicio: SizedBox(
                          width: 54,
                          child: Column(children: [
                            Text('${d.numeroPasajeros}', style: archivo(15)),
                            Text('pasajeros', style: plex(10, c: C.tenue)),
                          ]),
                        ),
                        titulo: d.ruta,
                        sub:
                            '${d.placaVehiculo} · ${fechaVista(d.fecha)} ${horaVista(d.hora)}',
                        derecha: d.estado == 'CANCELADO'
                            ? const ChipEstado('Cancelado', tipo: 'mal')
                            : const Icon(Icons.chevron_right, color: C.tenue),
                        alTocar: () async {
                          await ir(context, Rutas.detalleDespacho, d.id);
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
              ],
            );
          },
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S28RegistrarDespacho extends StatefulWidget {
  const S28RegistrarDespacho({super.key});

  @override
  State<S28RegistrarDespacho> createState() => _S28RegistrarDespachoState();
}

class _S28RegistrarDespachoState extends State<S28RegistrarDespacho> {
  Future<List<Vehiculo>>? futuro;
  List<Vehiculo> vehiculos = [];
  Set<String> enTaller = {};
  final ruta = TextEditingController();
  final fecha = TextEditingController(text: fechaVista(hoyIso()));
  final hora = TextEditingController(text: '06:00');
  final pasajeros = TextEditingController();
  String? placa;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargar();
    for (final c in [ruta, fecha, hora, pasajeros]) {
      c.addListener(() => setState(() {}));
    }
  }

  void cargar() {
    setState(() {
      futuro = _traer();
    });
  }

  Future<List<Vehiculo>> _traer() async {
    Pagina<Vehiculo> pagina = await Sitram.vehiculos(tam: 100);
    enTaller = await Sitram.placasEnTaller();
    vehiculos = [];
    for (Vehiculo v in pagina.items) {
      if (v.activo) vehiculos.add(v);
    }
    return vehiculos;
  }

  Vehiculo? get vehiculo {
    for (final v in vehiculos) {
      if (v.placa == placa) return v;
    }
    return null;
  }

  String? get errorPasajeros {
    final n = int.tryParse(pasajeros.text);
    final v = vehiculo;
    if (pasajeros.text.isEmpty) return null;
    if (n == null || n <= 0) return 'Escriba un número válido.';
    if (v != null && n > v.capacidadPasajeros)
      return 'Supera la capacidad del vehículo (${v.capacidadPasajeros}).';
    return null;
  }

  Future<void> guardar() async {
    if (faltanCampos(context, {
      'Ruta': ruta.text,
      'Vehículo': placa ?? '',
      'Número de pasajeros': pasajeros.text
    })) return;
    if (errorPasajeros != null) return;
    setState(() => guardando = true);
    try {
      await Sitram.crearDespacho(DespachoRequest(
        ruta: ruta.text.trim(),
        placaVehiculo: placa!,
        fecha: isoDeVista(fecha.text)!,
        hora: '${hora.text}:00',
        numeroPasajeros: int.parse(pasajeros.text),
      ));
      if (!mounted) return;
      aviso(context, 'Despacho registrado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final v = vehiculo;
    return Base(
      titulo: 'Registrar despacho',
      atras: true,
      hijos: [
        Campo('Ruta',
            requerido: true, control: ruta, hint: 'Ej: Corozal – Sincelejo'),
        Cargar<List<Vehiculo>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (lista) => CampoLista<String>('Vehículo',
              requerido: true,
              valor: placa,
              opciones: [
                for (final x in lista)
                  Opcion(
                    x.placa,
                    enTaller.contains(x.placa.toUpperCase())
                        ? '${x.placa} · en mantenimiento'
                        : '${x.placa} — ${capital(x.tipo)}',
                    !enTaller.contains(x.placa.toUpperCase()),
                  ),
              ],
              alCambiar: (x) => setState(() => placa = x)),
        ),
        Dos(
          Campo('Fecha',
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
        Campo('Número de pasajeros',
            requerido: true,
            control: pasajeros,
            teclado: TextInputType.number,
            error: errorPasajeros,
            ayuda: v == null
                ? null
                : 'Capacidad del vehículo: ${v.capacidadPasajeros} pasajeros.'),
        const Seccion('Resumen del despacho'),
        TarjetaDatos({
          'Ruta': ruta.text.isEmpty ? '—' : ruta.text,
          'Vehículo': placa ?? '—',
          'Salida': '${fecha.text} · ${horaVista('${hora.text}:00')}',
          'Pasajeros': v == null
              ? pasajeros.text
              : '${pasajeros.text} de ${v.capacidadPasajeros}',
        }),
      ],
      abajo: BotonesForm(
          ok: guardando ? 'Guardando...' : 'Guardar',
          alGuardar: guardando ? null : guardar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S29DetalleDespacho extends StatefulWidget {
  final int id;
  const S29DetalleDespacho({super.key, required this.id});

  @override
  State<S29DetalleDespacho> createState() => _S29DetalleDespachoState();
}

class _S29DetalleDespachoState extends State<S29DetalleDespacho> {
  Future<Despacho>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.despacho(widget.id);
    });
  }

  Future<void> cancelar() async {
    final motivo = await pedirTexto(context,
        titulo: 'Cancelar despacho',
        etiqueta: 'Motivo',
        ok: 'Cancelar despacho');
    if (motivo == null || !mounted) return;
    if (motivo.isEmpty) {
      aviso(context, 'El motivo es obligatorio', error: true);
      return;
    }
    try {
      await Sitram.cancelarDespacho(widget.id, motivo);
      if (!mounted) return;
      aviso(context, 'Despacho cancelado');
      cargar();
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de despacho',
      atras: true,
      hijos: [
        Cargar<Despacho>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(
                color: C.verde,
                borde: C.verde,
                hijos: [
                  Text('RUTA',
                      style: archivo(10.5, c: Colors.white70, espacio: 1)),
                  Text(d.ruta, style: archivo(20, c: Colors.white)),
                  const SizedBox(height: 10),
                  Row(children: [
                    for (final x in {
                      'Salida': horaVista(d.hora),
                      'Pasajeros': '${d.numeroPasajeros}',
                      'Vehículo': d.placaVehiculo
                    }.entries)
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x.key, style: plex(11, c: Colors.white70)),
                              Text(x.value,
                                  style: archivo(14, c: Colors.white)),
                            ]),
                      ),
                  ]),
                ],
              ),
              if (d.estado == 'CANCELADO')
                Alerta(
                  titulo: 'Despacho cancelado',
                  texto:
                      '${d.motivoCancelacion}\nPor ${d.canceladoPor} el ${fechaHoraVista(d.fechaCancelacion)}',
                ),
              const Seccion('Datos del despacho'),
              TarjetaDatos({
                'ID': 'DP-${d.id}',
                'Ruta': d.ruta,
                'Vehículo': d.placaVehiculo,
                'Fecha': fechaVista(d.fecha),
                'Hora': horaVista(d.hora),
                'Número de pasajeros': '${d.numeroPasajeros}',
                'Estado': ChipEstado(capital(d.estado),
                    tipo: tipoDe(capital(d.estado))),
              }),
              const Seccion('Registro'),
              TarjetaDatos({
                'Fecha de registro': fechaHoraVista(d.fechaRegistro),
                'Registró': d.registradoPor
              }),
              Btn('Ver vehículo',
                  tipo: 'contorno',
                  alTocar: () => ir(context, Rutas.detalleVehiculo, d.placaVehiculo)),
              if (d.estado == 'REGISTRADO')
                Btn('Cancelar despacho', tipo: 'peligro', alTocar: cancelar),
            ],
          ),
        ),
      ],
    );
  }
}
