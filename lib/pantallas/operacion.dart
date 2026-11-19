import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../models/requests.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

String _ultimos3(String placa) => placa.length >= 3 ? placa.substring(placa.length - 3) : placa;

/////////////////////////////////////////////////////////////////

class S14Vehiculos extends StatefulWidget {
  const S14Vehiculos({super.key});

  @override
  State<S14Vehiculos> createState() => _S14VehiculosState();
}

class _S14VehiculosState extends State<S14Vehiculos> {
  int pagina = 1;
  String? placa;
  String? tipo;
  Future<Pagina<Vehiculo>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.vehiculos(pagina: pagina, placa: placa, tipo: tipo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Operación',
      tabs: tabsOperacion,
      tabActual: Rutas.vehiculos,
      nav: Rutas.vehiculos,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.nuevoVehiculo) == true) cargar();
      }),
      hijos: [
        Buscador(
            hint: 'Buscar por placa',
            alBuscar: (t) {
              placa = t;
              pagina = 1;
              cargar();
            }),
        Filtros(['Todos', 'Campero', 'Microbús', 'Buseta', 'Camioneta'], alCambiar: (i) {
          tipo = [null, 'CAMPERO', 'MICROBUS', 'BUSETA', 'CAMIONETA'][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Vehiculo>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(icono: Icons.directions_bus_outlined, titulo: 'Sin vehículos', texto: 'No hay vehículos con ese filtro.');
            }
            return Column(
              children: [
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final v in p.items)
                      FilaLista(
                        inicio: Caja(_ultimos3(v.placa)),
                        titulo: '${v.placa} · ${capital(v.tipo)}',
                        sub: '${v.marca} ${v.modelo} · ${v.capacidadPasajeros} pasajeros'
                            '${v.tieneConductor ? '' : ' · sin conductor'}',
                        derecha: ChipEstado(v.activo ? 'Activo' : 'Inactivo', tipo: v.activo ? 'ok' : 'gris'),
                        alTocar: () async {
                          await ir(context, Rutas.detalleVehiculo, v.placa);
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

class _OpcionesVehiculo {
  final List<Tarifa> tarifas;
  final List<Conductor> conductores;
  final Map<String, String> sancionados;
  _OpcionesVehiculo(this.tarifas, this.conductores, this.sancionados);
}

/////////////////////////////////////////////////////////////////

class S15FormVehiculo extends StatefulWidget {
  final Vehiculo? vehiculo;
  const S15FormVehiculo({super.key, this.vehiculo});

  @override
  State<S15FormVehiculo> createState() => _S15FormVehiculoState();
}

class _S15FormVehiculoState extends State<S15FormVehiculo> {
  late final v = widget.vehiculo;
  late final placa = TextEditingController(text: v?.placa ?? '');
  late final marca = TextEditingController(text: v?.marca ?? '');
  late final modelo = TextEditingController(text: v?.modelo ?? '');
  late final capacidad = TextEditingController(text: v == null ? '' : '${v!.capacidadPasajeros}');
  late final tarjeta = TextEditingController(text: v?.tarjetaPropiedad ?? '');
  late final soat = TextEditingController(text: v == null ? '' : fechaVista(v!.vigenciaSoat).replaceAll('—', ''));
  late final trm = TextEditingController(text: v == null ? '' : fechaVista(v!.vigenciaTrm).replaceAll('—', ''));
  late final ingreso = TextEditingController(text: fechaVista(v?.fechaIngreso ?? hoyIso()).replaceAll('—', ''));
  late String? tipo = v?.tipo;
  late int? tarifaId = v?.tarifaId;
  late String conductor = v?.identificacionConductor ?? '';
  late bool activo = v?.activo ?? true;
  bool guardando = false;
  Future<_OpcionesVehiculo>? futuro;

  bool get esEdicion => v != null;
  static const tipos = ['CAMPERO', 'MICROBUS', 'BUSETA', 'CAMIONETA'];

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

  Future<_OpcionesVehiculo> _traer() async {
    Pagina<Tarifa> tarifas = await Sitram.tarifas(activo: true, tam: 100);
    List<Conductor> conductores = [];
    Map<String, String> sancionados = {};
    if (esEdicion) {
      Pagina<Conductor> pagina = await Sitram.conductores(activo: true, tam: 100);
      conductores = pagina.items;
      sancionados = await Sitram.sancionadosEn(hoyIso());
    }
    return _OpcionesVehiculo(tarifas.items, conductores, sancionados);
  }

  Future<void> guardar() async {
    if (!esEdicion &&
        faltanCampos(context, {
          'Placa': placa.text,
          'Tipo': tipo ?? '',
          'Marca': marca.text,
          'Modelo': modelo.text,
          'Capacidad': capacidad.text,
          'Tarjeta de propiedad': tarjeta.text,
          'Tarifa': tarifaId == null ? '' : 'ok',
          'Vigencia SOAT': soat.text,
          'Vigencia TRM': trm.text,
        })) return;
    setState(() => guardando = true);
    try {
      if (esEdicion) {
        await Sitram.actualizarVehiculo(
            v!.placa,
            ActualizarVehiculoRequest(
              identificacionConductor: conductor,
              activo: activo,
              vigenciaSoat: isoDeVista(soat.text),
              vigenciaTrm: isoDeVista(trm.text),
              fechaIngreso: isoDeVista(ingreso.text),
              tarifaId: tarifaId,
            ));
      } else {
        await Sitram.crearVehiculo(VehiculoRequest(
          placa: placa.text.trim().toUpperCase(),
          tipo: tipo!,
          marca: marca.text.trim(),
          modelo: modelo.text.trim(),
          capacidadPasajeros: int.tryParse(capacidad.text.trim()) ?? 0,
          tarjetaPropiedad: tarjeta.text.trim(),
          tarifaId: tarifaId!,
          activo: activo,
          vigenciaSoat: isoDeVista(soat.text)!,
          vigenciaTrm: isoDeVista(trm.text)!,
          fechaIngreso: isoDeVista(ingreso.text),
        ));
      }
      if (!mounted) return;
      aviso(context, esEdicion ? 'Vehículo actualizado' : 'Vehículo registrado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: esEdicion ? 'Editar vehículo' : 'Registrar vehículo',
      atras: true,
      hijos: [
        Cargar<_OpcionesVehiculo>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (op) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Seccion('Identificación'),
              Dos(
                Campo('Placa', requerido: true, control: placa, soloLectura: esEdicion, hint: 'ABC123'),
                CampoLista<String>('Tipo',
                    requerido: true,
                    valor: tipo,
                    opciones: [
                      for (final t in tipos) Opcion(t, capital(t)),
                      if (tipo != null && !tipos.contains(tipo)) Opcion(tipo!, capital(tipo!)),
                    ],
                    alCambiar: esEdicion ? null : (x) => setState(() => tipo = x)),
              ),
              Dos(
                Campo('Marca', requerido: true, control: marca, soloLectura: esEdicion),
                Campo('Modelo', requerido: true, control: modelo, soloLectura: esEdicion, teclado: TextInputType.number),
              ),
              Campo('Capacidad de pasajeros',
                  requerido: true, control: capacidad, soloLectura: esEdicion, teclado: TextInputType.number),
              const Seccion('Asignación'),
              if (esEdicion)
                CampoLista<String>(
                  'Conductor',
                  valor: conductor,
                  opciones: [
                    const Opcion('', 'Sin conductor'),
                    for (final c in op.conductores)
                      Opcion(
                        c.identificacion,
                        op.sancionados.containsKey(c.identificacion)
                            ? '${c.nombres} · sancionado hasta ${fechaVista(op.sancionados[c.identificacion])}'
                            : c.nombres,
                        !op.sancionados.containsKey(c.identificacion) || c.identificacion == conductor,
                      ),
                  ],
                  alCambiar: (x) => setState(() => conductor = x ?? ''),
                  ayuda: 'Los conductores con sanción vigente aparecen deshabilitados. '
                      'Para asignar conductor el vehículo debe tener una afiliación activa.',
                )
              else
                Text('El conductor se asigna después de registrar la afiliación del vehículo.',
                    style: plex(11.5, c: C.medio)),
              if (!esEdicion) const SizedBox(height: 12),
              CampoLista<int>('Tarifa',
                  requerido: true,
                  valor: tarifaId,
                  opciones: [for (final t in op.tarifas) Opcion(t.id, 'Tarifa #${t.id} · ${pesos(t.total)}')],
                  alCambiar: (x) => setState(() => tarifaId = x),
                  ayuda: op.tarifas.isEmpty ? 'No hay tarifas activas. Registre una en Admin.' : null),
              const Seccion('Documentación'),
              Campo('Tarjeta de propiedad', requerido: true, control: tarjeta, soloLectura: esEdicion),
              Dos(
                Campo('Vigencia SOAT',
                    requerido: true, control: soat, sufijo: Icons.calendar_today_outlined, alTocar: () => elegirFecha(context, soat)),
                Campo('Vigencia TRM',
                    requerido: true, control: trm, sufijo: Icons.calendar_today_outlined, alTocar: () => elegirFecha(context, trm)),
              ),
              Campo('Fecha de ingreso',
                  control: ingreso, sufijo: Icons.calendar_today_outlined, alTocar: () => elegirFecha(context, ingreso)),
              TarjetaSwitch(
                titulo: 'Vehículo activo',
                sub: 'Puede operar y recibir planillas.',
                valor: activo,
                alCambiar: (x) => setState(() => activo = x),
              ),
            ],
          ),
        ),
      ],
      abajo: BotonesForm(ok: guardando ? 'Guardando...' : 'Guardar', alGuardar: guardando ? null : guardar),
    );
  }
}

class _DetalleVehiculo {
  final Vehiculo v;
  final Conductor? conductor;
  final Sancion? sancion;
  final Mantenimiento? taller;
  _DetalleVehiculo(this.v, this.conductor, this.sancion, this.taller);
}

/////////////////////////////////////////////////////////////////

class S16DetalleVehiculo extends StatefulWidget {
  final String placa;
  const S16DetalleVehiculo({super.key, required this.placa});

  @override
  State<S16DetalleVehiculo> createState() => _S16DetalleVehiculoState();
}

class _S16DetalleVehiculoState extends State<S16DetalleVehiculo> {
  Future<_DetalleVehiculo>? futuro;

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

  Future<_DetalleVehiculo> _traer() async {
    final v = await Sitram.vehiculo(widget.placa);
    Pagina<Mantenimiento> mantenimientos = await Sitram.mantenimientos(placa: v.placa, estado: 'EN_MANTENIMIENTO', tam: 5);
    Mantenimiento? taller;
    for (Mantenimiento m in mantenimientos.items) {
      if (m.abierto) {
        taller = m;
        break;
      }
    }
    if (!v.tieneConductor) return _DetalleVehiculo(v, null, null, taller);
    Conductor conductor = await Sitram.conductor(v.identificacionConductor);
    Pagina<Sancion> sanciones = await Sitram.sanciones(conductor: v.identificacionConductor, estado: 'ACTIVA', tam: 50);
    String hoy = hoyIso();
    Sancion? vigente;
    for (Sancion s in sanciones.items) {
      if (s.identificacionConductor == v.identificacionConductor && s.vigenteEn(hoy)) {
        vigente = s;
        break;
      }
    }
    return _DetalleVehiculo(v, conductor, vigente, taller);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: widget.placa,
      subtitulo: 'Detalle de vehículo',
      atras: true,
      hijos: [
        Cargar<_DetalleVehiculo>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (d) {
            final v = d.v;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (d.taller != null)
                  GestureDetector(
                    onTap: () async {
                      await ir(context, Rutas.detalleMantenimiento, d.taller!.id);
                      cargar();
                    },
                    child: Alerta(
                      tipo: 'warn',
                      titulo: 'En mantenimiento',
                      texto: 'Ingresó el ${fechaHoraVista(d.taller!.fechaIngreso)} por «${d.taller!.motivo}». '
                          'No puede recibir planillas ni despachos. Toque para registrar la salida.',
                    ),
                  ),
                const Seccion('Información general'),
                TarjetaDatos({
                  'Placa': v.placa,
                  'Tipo': capital(v.tipo),
                  'Marca y modelo': '${v.marca} ${v.modelo}',
                  'Capacidad': '${v.capacidadPasajeros} pasajeros',
                  'Estado': ChipEstado(v.activo ? 'Activo' : 'Inactivo', tipo: v.activo ? 'ok' : 'gris'),
                }),
                const Seccion('Conductor asignado'),
                if (d.conductor == null)
                  const Alerta(tipo: 'warn', texto: 'Este vehículo no tiene conductor asignado. No se le pueden generar planillas.')
                else
                  Tarjeta(
                    borde: d.sancion != null ? C.error : C.borde,
                    hijos: [
                      InkWell(
                        onTap: () => ir(context, Rutas.detalleConductor, d.conductor!.identificacion),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d.conductor!.nombres, style: plex(14, w: FontWeight.w600)),
                              Text('CC ${d.conductor!.identificacion} · Licencia ${d.conductor!.categoriaLicencia}',
                                  style: plex(12, c: C.tenue)),
                            ]),
                          ),
                          d.sancion != null
                              ? const ChipEstado('Sancionado', tipo: 'mal')
                              : const Icon(Icons.chevron_right, color: C.tenue),
                        ]),
                      ),
                      if (d.sancion != null) ...[
                        const SizedBox(height: 10),
                        Alerta(
                            texto: 'Sancionado hasta el ${fechaVista(d.sancion!.fechaFin)}. '
                                'Asigne otro conductor para operar este vehículo.'),
                      ],
                    ],
                  ),
                const Seccion('Documentación'),
                TarjetaDatos({
                  'Tarjeta de propiedad': v.tarjetaPropiedad,
                  'Vigencia SOAT': fechaVista(v.vigenciaSoat),
                  'Vigencia TRM': fechaVista(v.vigenciaTrm),
                }),
                const Seccion('Tarifa y fechas'),
                TarjetaDatos({
                  'Tarifa': v.tarifaId == null ? '—' : '#${v.tarifaId} · ${pesos(v.tarifaTotal)}',
                  'Fecha de ingreso': fechaVista(v.fechaIngreso),
                  'Registro': fechaHoraVista(v.fechaRegistro),
                  'Última actualización': fechaHoraVista(v.ultimaActualizacion),
                }),
                Btn('Editar vehículo', alTocar: () async {
                  if (await ir(context, Rutas.nuevoVehiculo, v) == true) cargar();
                }),
                if (d.taller == null)
                  Btn('Registrar ingreso a mantenimiento', tipo: 'contorno', alTocar: () async {
                    if (await ir(context, Rutas.ingresoTaller, v.placa) == true) cargar();
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

class S17Afiliaciones extends StatefulWidget {
  const S17Afiliaciones({super.key});

  @override
  State<S17Afiliaciones> createState() => _S17AfiliacionesState();
}

class _S17AfiliacionesState extends State<S17Afiliaciones> {
  int pagina = 1;
  String? estado = 'ACTIVA';
  String? buscar;
  Future<Pagina<Afiliacion>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    final t = buscar?.trim() ?? '';
    final esNumero = RegExp(r'^\d+$').hasMatch(t);
    setState(() {
      futuro = Sitram.afiliaciones(
          pagina: pagina,
          estado: estado,
          asociado: esNumero ? t : null,
          vehiculo: esNumero ? null : t.toUpperCase(),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Operación',
      tabs: tabsOperacion,
      tabActual: Rutas.afiliaciones,
      nav: Rutas.vehiculos,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.nuevaAfiliacion) == true) cargar();
      }),
      hijos: [
        Buscador(
            hint: 'Placa o identificación del asociado',
            alBuscar: (t) {
              buscar = t;
              pagina = 1;
              cargar();
            }),
        Filtros(['Activa', 'Inactiva', 'Suspendida', 'Finalizada', 'Todas'], alCambiar: (i) {
          estado = ['ACTIVA', 'INACTIVA', 'SUSPENDIDA', 'FINALIZADA', null][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Afiliacion>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(icono: Icons.link_off, titulo: 'Sin afiliaciones', texto: 'No hay afiliaciones con ese filtro.');
            }
            return Column(
              children: [
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final a in p.items)
                      FilaLista(
                        inicio: Caja(_ultimos3(a.placaVehiculo)),
                        titulo: '${a.placaVehiculo} · CC ${a.identificacionAsociado}',
                        sub: a.fechaFinAfiliacion == null
                            ? 'Desde ${fechaVista(a.fechaAfiliacion)} · sin fecha de fin'
                            : '${fechaVista(a.fechaAfiliacion)} → ${fechaVista(a.fechaFinAfiliacion)}',
                        derecha: ChipEstado(capital(a.estado), tipo: tipoDe(capital(a.estado))),
                        alTocar: () async {
                          await ir(context, Rutas.detalleAfiliacion, a.id);
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

class S18FormAfiliacion extends StatefulWidget {
  final Afiliacion? afiliacion;
  const S18FormAfiliacion({super.key, this.afiliacion});

  @override
  State<S18FormAfiliacion> createState() => _S18FormAfiliacionState();
}

class _S18FormAfiliacionState extends State<S18FormAfiliacion> {
  late final a = widget.afiliacion;
  late String? asociado = a?.identificacionAsociado;
  late String? placa = a?.placaVehiculo;
  late String estado = a?.estado ?? 'ACTIVA';
  late final fechaAfiliacion = TextEditingController(text: fechaVista(a?.fechaAfiliacion ?? hoyIso()));
  late final fechaFin = TextEditingController(text: a?.fechaFinAfiliacion == null ? '' : fechaVista(a!.fechaFinAfiliacion));
  bool guardando = false;
  Future<_OpcionesAfiliacion>? futuro;

  bool get esEdicion => a != null;

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

  Future<_OpcionesAfiliacion> _traer() async {
    Pagina<Asociado> asociados = await Sitram.asociados(activo: true, tam: 100);
    Pagina<Vehiculo> vehiculos = await Sitram.vehiculos(tam: 100);
    return _OpcionesAfiliacion(asociados.items, vehiculos.items);
  }

  Future<void> guardar() async {
    if (faltanCampos(context, {'Asociado': asociado ?? '', 'Vehículo': placa ?? '', 'Fecha de afiliación': fechaAfiliacion.text})) {
      return;
    }
    setState(() => guardando = true);
    final req = AfiliacionRequest(
      identificacionAsociado: asociado!,
      placaVehiculo: placa!,
      fechaAfiliacion: isoDeVista(fechaAfiliacion.text)!,
      fechaFinAfiliacion: fechaFin.text.isEmpty ? null : isoDeVista(fechaFin.text),
      estado: estado,
    );
    try {
      if (esEdicion) {
        await Sitram.actualizarAfiliacion(a!.id, req);
      } else {
        await Sitram.crearAfiliacion(req);
      }
      if (!mounted) return;
      aviso(context, esEdicion ? 'Afiliación actualizada' : 'Afiliación registrada');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: esEdicion ? 'Editar afiliación' : 'Registrar afiliación',
      atras: true,
      hijos: [
        Cargar<_OpcionesAfiliacion>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (op) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoLista<String>('Asociado',
                  requerido: true,
                  valor: asociado,
                  opciones: [
                    for (final x in op.asociados) Opcion(x.identificacion, '${x.nombres} — CC ${x.identificacion}'),
                    if (asociado != null && !op.asociados.any((x) => x.identificacion == asociado)) Opcion(asociado!, 'CC $asociado'),
                  ],
                  alCambiar: (x) => setState(() => asociado = x)),
              CampoLista<String>('Vehículo',
                  requerido: true,
                  valor: placa,
                  opciones: [for (final x in op.vehiculos) Opcion(x.placa, '${x.placa} — ${x.marca} ${x.modelo}')],
                  alCambiar: (x) => setState(() => placa = x)),
              const Seccion('Vigencia'),
              Dos(
                Campo('Fecha de afiliación',
                    requerido: true,
                    control: fechaAfiliacion,
                    sufijo: Icons.calendar_today_outlined,
                    alTocar: () => elegirFecha(context, fechaAfiliacion)),
                Campo('Fecha de fin',
                    control: fechaFin,
                    hint: 'Sin definir',
                    sufijo: Icons.calendar_today_outlined,
                    alTocar: () => elegirFecha(context, fechaFin)),
              ),
              Text('Dejar la fecha de fin vacía deja la afiliación abierta hasta que se finalice.', style: plex(11, c: C.medio)),
              const SizedBox(height: 12),
              CampoLista<String>('Estado',
                  requerido: true,
                  valor: estado,
                  opciones: const [
                    Opcion('ACTIVA', 'Activa'),
                    Opcion('INACTIVA', 'Inactiva'),
                    Opcion('SUSPENDIDA', 'Suspendida'),
                  ],
                  alCambiar: (x) => setState(() => estado = x ?? 'ACTIVA')),
              const Seccion('Resumen'),
              TarjetaDatos({
                'Asociado': asociado ?? '—',
                'Vehículo': placa ?? '—',
                'Estado': ChipEstado(capital(estado), tipo: tipoDe(capital(estado))),
              }),
            ],
          ),
        ),
      ],
      abajo: BotonesForm(ok: guardando ? 'Guardando...' : 'Guardar', alGuardar: guardando ? null : guardar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S19DetalleAfiliacion extends StatefulWidget {
  final int id;
  const S19DetalleAfiliacion({super.key, required this.id});

  @override
  State<S19DetalleAfiliacion> createState() => _S19DetalleAfiliacionState();
}

class _S19DetalleAfiliacionState extends State<S19DetalleAfiliacion> {
  Future<Afiliacion>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.afiliacion(widget.id);
    });
  }

  void finalizar(Afiliacion a) {
    confirmar(context,
        titulo: '¿Finalizar afiliación?',
        texto: 'El vehículo ${a.placaVehiculo} dejará de estar afiliado desde hoy. El historial se conserva.',
        ok: 'Sí, finalizar', alAceptar: () async {
      try {
        await Sitram.finalizarAfiliacion(a.id, hoyIso());
        if (!mounted) return;
        aviso(context, 'Afiliación finalizada');
        cargar();
      } catch (e) {
        if (mounted) aviso(context, '$e', error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de afiliación',
      atras: true,
      hijos: [
        Cargar<Afiliacion>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (a) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TarjetaDatos({
                'ID': 'AF-${a.id}',
                'Asociado': 'CC ${a.identificacionAsociado}',
                'Vehículo': a.placaVehiculo,
                'Estado': ChipEstado(capital(a.estado), tipo: tipoDe(capital(a.estado))),
              }),
              const Seccion('Vigencia'),
              TarjetaDatos({
                'Fecha de afiliación': fechaVista(a.fechaAfiliacion),
                'Fecha de fin': a.fechaFinAfiliacion == null ? 'Sin definir' : fechaVista(a.fechaFinAfiliacion),
                'Registro': fechaHoraVista(a.fechaRegistro),
                'Última actualización': fechaHoraVista(a.ultimaActualizacion),
              }),
              Btn('Ver asociado', tipo: 'contorno', alTocar: () => ir(context, Rutas.detalleAsociado, a.identificacionAsociado)),
              Btn('Ver vehículo', tipo: 'contorno', alTocar: () => ir(context, Rutas.detalleVehiculo, a.placaVehiculo)),
              if (a.estado != 'FINALIZADA') ...[
                Btn('Editar afiliación', alTocar: () async {
                  if (await ir(context, Rutas.nuevaAfiliacion, a) == true) cargar();
                }),
                Btn('Finalizar afiliación', tipo: 'peligro', alTocar: () => finalizar(a)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OpcionesAfiliacion {
  final List<Asociado> asociados;
  final List<Vehiculo> vehiculos;
  _OpcionesAfiliacion(this.asociados, this.vehiculos);
}
