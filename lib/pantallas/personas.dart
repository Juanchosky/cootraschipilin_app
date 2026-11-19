import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../models/requests.dart';
import '../services/sesion.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

String _credencial(String estado) {
  switch (estado) {
    case 'ACTIVA':
      return 'Credencial activa';
    case 'TEMPORAL':
      return 'Credencial temporal';
    default:
      return 'Sin credencial';
  }
}

////////////////////////////////////////////////////////////////

class S05Asociados extends StatefulWidget {
  const S05Asociados({super.key});

  @override
  State<S05Asociados> createState() => _S05AsociadosState();
}

class _S05AsociadosState extends State<S05Asociados> {
  int pagina = 1;
  bool? activo = true;
  String? buscar;
  Future<Pagina<Asociado>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro =
        Sitram.asociados(pagina: pagina, nombres: buscar, activo: activo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Personas',
      tabs: tabsPersonas,
      tabActual: Rutas.asociados,
      nav: Rutas.asociados,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.nuevoAsociado) == true) cargar();
      }),
      hijos: [
        Buscador(
            hint: 'Buscar por nombre',
            alBuscar: (t) {
              buscar = t;
              pagina = 1;
              cargar();
            }),
        Filtros(['Activos', 'Inactivos', 'Todos'], alCambiar: (i) {
          activo = [true, false, null][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Asociado>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(
                  icono: Icons.search,
                  titulo: 'Ningún asociado coincide',
                  texto: 'Pruebe con otro nombre o filtro.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mostrando ${p.items.length} de ${p.total} asociados',
                    style: plex(12, c: C.medio)),
                const SizedBox(height: 8),
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final a in p.items)
                      FilaLista(
                        inicio: Avatar(iniciales(a.nombres)),
                        titulo: a.nombres,
                        sub:
                            'CC ${a.identificacion} · Ingresó ${fechaVista(a.fechaIngreso)}',
                        derecha: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ChipEstado(a.activo ? 'Activo' : 'Inactivo',
                                tipo: a.activo ? 'ok' : 'gris'),
                            const SizedBox(height: 4),
                            Text(_credencial(a.estadoCredencial),
                                style: plex(10.5, c: C.tenue)),
                          ],
                        ),
                        alTocar: () async {
                          await ir(context, Rutas.detalleAsociado, a.identificacion);
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

class S06FormAsociado extends StatefulWidget {
  final Asociado? asociado;
  const S06FormAsociado({super.key, this.asociado});

  @override
  State<S06FormAsociado> createState() => _S06FormAsociadoState();
}

class _S06FormAsociadoState extends State<S06FormAsociado> {
  late final a = widget.asociado;
  late final identificacion =
      TextEditingController(text: a?.identificacion ?? '');
  late final nombres = TextEditingController(text: a?.nombres ?? '');
  late final nacimiento = TextEditingController(
      text:
          a == null ? '' : fechaVista(a!.fechaNacimiento).replaceAll('—', ''));
  late final celular = TextEditingController(text: a?.celular ?? '');
  late final correo = TextEditingController(text: a?.correo ?? '');
  late final ingreso = TextEditingController(
      text: fechaVista(a?.fechaIngreso ?? hoyIso()).replaceAll('—', ''));
  late bool activo = a?.activo ?? true;
  bool guardando = false;

  bool get esEdicion => a != null;

  Future<void> guardar() async {
    if (faltanCampos(context, {
      'Identificación': identificacion.text,
      'Nombres': nombres.text
    })) return;
    setState(() => guardando = true);
    final req = AsociadoRequest(
      identificacion: esEdicion ? null : identificacion.text.trim(),
      nombres: nombres.text.trim(),
      activo: activo,
      celular: celular.text.trim(),
      correo: correo.text.trim(),
      fechaNacimiento: isoDeVista(nacimiento.text),
      fechaIngreso: isoDeVista(ingreso.text),
    );
    try {
      if (esEdicion) {
        await Sitram.actualizarAsociado(a!.identificacion, req);
      } else {
        await Sitram.crearAsociado(req);
      }
      if (!mounted) return;
      aviso(context, esEdicion ? 'Cambios guardados' : 'Asociado registrado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: esEdicion ? 'Editar asociado' : 'Registrar asociado',
      atras: true,
      hijos: [
        const Seccion('Datos personales'),
        Campo('Identificación',
            requerido: true,
            control: identificacion,
            soloLectura: esEdicion,
            teclado: TextInputType.number),
        Campo('Nombres', requerido: true, control: nombres),
        Campo('Fecha de nacimiento',
            control: nacimiento,
            sufijo: Icons.calendar_today_outlined,
            alTocar: () => elegirFecha(context, nacimiento)),
        const Seccion('Contacto'),
        Campo('Celular', control: celular, teclado: TextInputType.phone),
        Campo('Correo', control: correo, teclado: TextInputType.emailAddress),
        const Seccion('Vinculación'),
        Campo('Fecha de ingreso',
            control: ingreso,
            sufijo: Icons.calendar_today_outlined,
            alTocar: () => elegirFecha(context, ingreso)),
        TarjetaSwitch(
          titulo: 'Asociado activo',
          sub: 'Puede afiliar vehículos desde su registro.',
          valor: activo,
          alCambiar: (v) => setState(() => activo = v),
        ),
      ],
      abajo: BotonesForm(
          ok: guardando ? 'Guardando...' : 'Guardar',
          alGuardar: guardando ? null : guardar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S07DetalleAsociado extends StatefulWidget {
  final String id;
  const S07DetalleAsociado({super.key, required this.id});

  @override
  State<S07DetalleAsociado> createState() => _S07DetalleAsociadoState();
}

class _S07DetalleAsociadoState extends State<S07DetalleAsociado> {
  Future<Asociado>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.asociado(widget.id);
    });
  }

  Future<void> generarCredencial(Asociado a) async {
    await confirmar(context,
        titulo: '¿Generar credencial temporal?',
        texto:
            'Se creará una clave temporal para que ${a.nombres} ingrese a la app. Si ya tenía una, la anterior deja de servir.',
        ok: 'Generar', alAceptar: () async {
      try {
        final c = await Sitram.credencialTemporal(a.identificacion);
        if (!mounted) return;
        await mostrarCredencial(
            context, 'Credencial generada', c.username, c.password);
        cargar();
      } catch (e) {
        if (mounted) aviso(context, '$e', error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de asociado',
      atras: true,
      hijos: [
        Cargar<Asociado>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (a) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(
                hijos: [
                  Row(
                    children: [
                      Avatar(iniciales(a.nombres)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.nombres, style: archivo(16)),
                            Text(
                                '${a.username.isEmpty ? 'Sin usuario' : a.username} · Ingresó ${fechaVista(a.fechaIngreso)}',
                                style: plex(12, c: C.tenue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    ChipEstado(a.activo ? 'Activo' : 'Inactivo',
                        tipo: a.activo ? 'ok' : 'gris'),
                    const SizedBox(width: 6),
                    ChipEstado(_credencial(a.estadoCredencial),
                        tipo: a.estadoCredencial == 'ACTIVA' ? 'ok' : 'warn'),
                  ]),
                ],
              ),
              const Seccion('Identificación'),
              TarjetaDatos({
                'Identificación': a.identificacion,
                'Nombres': a.nombres,
                'Username': a.username.isEmpty ? '—' : a.username,
                'Fecha de nacimiento': fechaVista(a.fechaNacimiento),
              }),
              const Seccion('Contacto'),
              TarjetaDatos({
                'Celular': a.celular.isEmpty ? '—' : a.celular,
                'Correo': a.correo.isEmpty ? '—' : a.correo,
              }),
              const Seccion('Trazabilidad'),
              TarjetaDatos({
                'Fecha de ingreso': fechaVista(a.fechaIngreso),
                'Registro': fechaHoraVista(a.fechaRegistro),
                'Última actualización': fechaHoraVista(a.ultimaActualizacion),
              }),
              Btn('Editar asociado', alTocar: () async {
                if (await ir(context, Rutas.nuevoAsociado, a) == true) cargar();
              }),
              if (Sesion.esGerente)
                Btn('Generar credencial temporal',
                    tipo: 'contorno', alTocar: () => generarCredencial(a)),
            ],
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S08Conductores extends StatefulWidget {
  const S08Conductores({super.key});

  @override
  State<S08Conductores> createState() => _S08ConductoresState();
}

class _S08ConductoresState extends State<S08Conductores> {
  int pagina = 1;
  int filtro = 0;
  String? buscar;
  Future<_DatosConductores>? futuro;

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

  Future<_DatosConductores> _traer() async {
    bool? activo;
    if (filtro == 0) activo = true;
    if (filtro == 1) activo = false;
    int tam = tamPaginaLocal;
    if (filtro == 2) tam = 100;
    Pagina<Conductor> conductores = await Sitram.conductores(pagina: pagina, nombres: buscar, activo: activo, tam: tam);
    Map<String, String> sancionados = await Sitram.sancionadosEn(hoyIso());
    return _DatosConductores(conductores, sancionados);
  }

  static const tamPaginaLocal = 20;

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Personas',
      tabs: tabsPersonas,
      tabActual: Rutas.conductores,
      nav: Rutas.asociados,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.nuevoConductor) == true) cargar();
      }),
      hijos: [
        Buscador(
            hint: 'Buscar por nombres',
            alBuscar: (t) {
              buscar = t;
              pagina = 1;
              cargar();
            }),
        Filtros(['Activos', 'Inactivos', 'Sancionados', 'Todos'],
            alCambiar: (i) {
          filtro = i;
          pagina = 1;
          cargar();
        }),
        Cargar<_DatosConductores>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (datos) {
            final sancionados = datos.sancionados;
            var lista = datos.conductores.items;
            if (filtro == 2)
              lista = lista
                  .where((c) => sancionados.containsKey(c.identificacion))
                  .toList();
            if (lista.isEmpty) {
              return const Vacio(
                  icono: Icons.person_search_outlined,
                  titulo: 'Sin conductores',
                  texto: 'No hay conductores con ese filtro.');
            }
            return Column(
              children: [
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final c in lista)
                      FilaLista(
                        marcada: sancionados.containsKey(c.identificacion),
                        inicio: Avatar(iniciales(c.nombres),
                            alerta: sancionados.containsKey(c.identificacion)),
                        titulo: c.nombres,
                        sub:
                            'CC ${c.identificacion} · Licencia ${c.categoriaLicencia}',
                        extra: sancionados.containsKey(c.identificacion)
                            ? 'Sancionado hasta ${fechaVista(sancionados[c.identificacion])}'
                            : null,
                        derecha: sancionados.containsKey(c.identificacion)
                            ? const ChipEstado('Sancionado', tipo: 'mal')
                            : ChipEstado(c.activo ? 'Activo' : 'Inactivo',
                                tipo: c.activo ? 'ok' : 'gris'),
                        alTocar: () async {
                          await ir(context, Rutas.detalleConductor, c.identificacion);
                          cargar();
                        },
                      ),
                  ],
                ),
                if (filtro != 2)
                  Paginacion(
                      pagina: datos.conductores.pagina,
                      paginas: datos.conductores.paginas,
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

class S09FormConductor extends StatefulWidget {
  final Conductor? conductor;
  const S09FormConductor({super.key, this.conductor});

  @override
  State<S09FormConductor> createState() => _S09FormConductorState();
}

class _S09FormConductorState extends State<S09FormConductor> {
  late final c = widget.conductor;
  late final identificacion =
      TextEditingController(text: c?.identificacion ?? '');
  late final nombres = TextEditingController(text: c?.nombres ?? '');
  late final nacimiento = TextEditingController(
      text:
          c == null ? '' : fechaVista(c!.fechaNacimiento).replaceAll('—', ''));
  late final licencia = TextEditingController(text: c?.numeroLicencia ?? '');
  late final vigencia = TextEditingController(
      text:
          c == null ? '' : fechaVista(c!.vigenciaLicencia).replaceAll('—', ''));
  late final celular = TextEditingController(text: c?.celular ?? '');
  late final correo = TextEditingController(text: c?.correo ?? '');
  late String? categoria = c?.categoriaLicencia;
  late bool activo = c?.activo ?? true;
  bool guardando = false;

  bool get esEdicion => c != null;
  static const categorias = ['B1', 'B2', 'B3', 'C1', 'C2', 'C3'];

  Future<void> guardar() async {
    if (faltanCampos(context, {
      'Identificación': identificacion.text,
      'Nombres': nombres.text,
      'Número de licencia': licencia.text,
      'Categoría': categoria ?? '',
      'Vigencia': vigencia.text,
    })) return;
    setState(() => guardando = true);
    final req = ConductorRequest(
      identificacion: esEdicion ? null : identificacion.text.trim(),
      nombres: nombres.text.trim(),
      fechaNacimiento: isoDeVista(nacimiento.text),
      activo: activo,
      numeroLicencia: licencia.text.trim(),
      categoriaLicencia: categoria!,
      vigenciaLicencia: isoDeVista(vigencia.text) ?? '',
      celular: celular.text.trim(),
      correo: correo.text.trim(),
    );
    try {
      if (esEdicion) {
        await Sitram.actualizarConductor(c!.identificacion, req);
      } else {
        await Sitram.crearConductor(req);
      }
      if (!mounted) return;
      aviso(context, esEdicion ? 'Cambios guardados' : 'Conductor registrado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: esEdicion ? 'Editar conductor' : 'Registrar conductor',
      atras: true,
      hijos: [
        const Seccion('Datos personales'),
        Campo('Identificación',
            requerido: true,
            control: identificacion,
            soloLectura: esEdicion,
            teclado: TextInputType.number),
        Campo('Nombres', requerido: true, control: nombres),
        Campo('Fecha de nacimiento',
            control: nacimiento,
            sufijo: Icons.calendar_today_outlined,
            alTocar: () => elegirFecha(context, nacimiento)),
        TarjetaSwitch(
          titulo: 'Conductor activo',
          sub: 'Puede asignarse a vehículos.',
          valor: activo,
          alCambiar: (v) => setState(() => activo = v),
        ),
        const Seccion('Licencia de conducción'),
        Campo('Número de licencia', requerido: true, control: licencia),
        Dos(
          CampoLista<String>('Categoría',
              requerido: true,
              valor: categoria,
              opciones: [for (final k in categorias) Opcion(k, k)],
              alCambiar: (v) => setState(() => categoria = v)),
          Campo('Vigencia',
              requerido: true,
              control: vigencia,
              sufijo: Icons.calendar_today_outlined,
              alTocar: () => elegirFecha(context, vigencia)),
        ),
        Text('La categoría C2 habilita servicio público de pasajeros y mixto.',
            style: plex(11, c: C.medio)),
        const SizedBox(height: 10),
        const Seccion('Contacto'),
        Campo('Celular', control: celular, teclado: TextInputType.phone),
        Campo('Correo',
            control: correo,
            hint: 'correo@ejemplo.com',
            teclado: TextInputType.emailAddress),
      ],
      abajo: BotonesForm(
          ok: guardando ? 'Guardando...' : 'Guardar',
          alGuardar: guardando ? null : guardar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S10DetalleConductor extends StatefulWidget {
  final String id;
  const S10DetalleConductor({super.key, required this.id});

  @override
  State<S10DetalleConductor> createState() => _S10DetalleConductorState();
}

class _S10DetalleConductorState extends State<S10DetalleConductor> {
  Future<_DatosConductor>? futuro;

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

  Future<_DatosConductor> _traer() async {
    Conductor c = await Sitram.conductor(widget.id);
    Pagina<Sancion> pagina = await Sitram.sanciones(conductor: widget.id, estado: 'ACTIVA', tam: 50);
    List<Sancion> sanciones = [];
    for (Sancion x in pagina.items) {
      if (x.identificacionConductor == c.identificacion) sanciones.add(x);
    }
    return _DatosConductor(c, sanciones);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de conductor',
      atras: true,
      hijos: [
        Cargar<_DatosConductor>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (d) {
            Conductor c = d.conductor;
            String hoy = hoyIso();
            List<Sancion> vigente = [];
            List<Sancion> programadas = [];
            for (Sancion s in d.sanciones) {
              if (s.vigenteEn(hoy)) vigente.add(s);
              if (s.programada) programadas.add(s);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Tarjeta(hijos: [
                  Row(children: [
                    Avatar(iniciales(c.nombres), alerta: vigente.isNotEmpty),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nombres, style: archivo(16)),
                            Text('CC ${c.identificacion}',
                                style: plex(12, c: C.tenue)),
                          ]),
                    ),
                  ]),
                ]),
                if (vigente.isNotEmpty)
                  Alerta(
                    titulo: 'No disponible para trabajar',
                    texto:
                        'Sanción vigente del ${fechaVista(vigente.first.fechaInicio)} al ${fechaVista(vigente.first.fechaFin)} '
                        'por «${vigente.first.motivo}». No puede asignarse a planillas.',
                  ),
                if (vigente.isEmpty && programadas.isNotEmpty)
                  Alerta(
                    tipo: 'warn',
                    titulo: 'Sanción programada',
                    texto:
                        'Desde el ${fechaVista(programadas.first.fechaInicio)} hasta el ${fechaVista(programadas.first.fechaFin)}.',
                  ),
                const Seccion('Datos personales'),
                TarjetaDatos({
                  'Identificación': c.identificacion,
                  'Nombres': c.nombres,
                  'Fecha de nacimiento': fechaVista(c.fechaNacimiento),
                  'Estado': ChipEstado(c.activo ? 'Activo' : 'Inactivo',
                      tipo: c.activo ? 'ok' : 'gris'),
                }),
                const Seccion('Licencia de conducción'),
                TarjetaDatos({
                  'Número': c.numeroLicencia,
                  'Categoría': c.categoriaLicencia,
                  'Vigencia': fechaVista(c.vigenciaLicencia),
                }),
                const Seccion('Contacto y trazabilidad'),
                TarjetaDatos({
                  'Celular': c.celular.isEmpty ? '—' : c.celular,
                  'Correo': c.correo.isEmpty ? '—' : c.correo,
                  'Registro': fechaHoraVista(c.fechaRegistro),
                  'Última actualización': fechaHoraVista(c.ultimaActualizacion),
                }),
                Btn('Editar conductor', alTocar: () async {
                  if (await ir(context, Rutas.nuevoConductor, c) == true) cargar();
                }),
                Btn('Ver historial de sanciones',
                    tipo: 'contorno',
                    alTocar: () => ir(context, Rutas.sanciones, c.identificacion)),
                Btn('Sancionar conductor', tipo: 'peligro', alTocar: () async {
                  if (await ir(context, Rutas.registrarSancion, c.identificacion) == true)
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

class ChipSancion {
  final String texto;
  final String tipo;
  ChipSancion(this.texto, this.tipo);
}

ChipSancion chipSancion(Sancion s) {
  if (s.estado == 'ACTIVA') {
    if (s.vigenteEn(hoyIso())) return ChipSancion('Vigente', 'mal');
    if (s.programada) return ChipSancion('Programada', 'warn');
    return ChipSancion('Activa', 'warn');
  }
  return ChipSancion(capital(s.estado), 'gris');
}

/////////////////////////////////////////////////////////////////

class S11Sanciones extends StatefulWidget {
  final String? conductor;
  const S11Sanciones({super.key, this.conductor});

  @override
  State<S11Sanciones> createState() => _S11SancionesState();
}

class _S11SancionesState extends State<S11Sanciones> {
  int pagina = 1;
  String? estado;
  late String? buscar = widget.conductor;
  Future<Pagina<Sancion>>? futuro;

  bool get esHistorial => widget.conductor != null;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro =
        Sitram.sanciones(pagina: pagina, conductor: buscar, estado: estado);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: esHistorial ? 'Historial de sanciones' : 'Personas',
      atras: esHistorial,
      tabs: esHistorial ? null : tabsPersonas,
      tabActual: Rutas.sanciones,
      nav: esHistorial ? null : Rutas.asociados,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.registrarSancion, widget.conductor) == true) cargar();
      }),
      hijos: [
        if (!esHistorial)
          Buscador(
              hint: 'Buscar conductor (nombre o identificación)',
              alBuscar: (t) {
                buscar = t;
                pagina = 1;
                cargar();
              }),
        Filtros(['Todas', 'Activas', 'Cumplidas', 'Anuladas'], alCambiar: (i) {
          estado = [null, 'ACTIVA', 'CUMPLIDA', 'ANULADA'][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Sancion>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(
                  icono: Icons.shield_outlined,
                  titulo: 'Sin sanciones',
                  texto: 'No hay sanciones con ese filtro.');
            }
            return Column(
              children: [
                Tarjeta(
                  pad: 0,
                  hijos: [
                    for (final s in p.items)
                      FilaLista(
                        marcada: s.estado == 'ACTIVA',
                        colorMarca: chipSancion(s).tipo == 'mal'
                            ? C.error
                            : C.advertencia,
                        titulo: s.nombresConductor.isEmpty
                            ? 'CC ${s.identificacionConductor}'
                            : s.nombresConductor,
                        sub:
                            'CC ${s.identificacionConductor}\n${fechaVista(s.fechaInicio)} → ${fechaVista(s.fechaFin)} · ${s.motivo}',
                        derecha: ChipEstado(chipSancion(s).texto,
                            tipo: chipSancion(s).tipo),
                        alTocar: () async {
                          await ir(context, Rutas.detalleSancion, s.id);
                          cargar();
                        },
                      ),
                  ],
                ),
                Text(
                    'El historial conserva las sanciones cumplidas y anuladas.',
                    textAlign: TextAlign.center,
                    style: plex(12, c: C.medio)),
                const SizedBox(height: 8),
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

class S12RegistrarSancion extends StatefulWidget {
  final String? conductor;
  const S12RegistrarSancion({super.key, this.conductor});

  @override
  State<S12RegistrarSancion> createState() => _S12RegistrarSancionState();
}

class _S12RegistrarSancionState extends State<S12RegistrarSancion> {
  Future<List<Conductor>>? futuro;
  late String? conductor = widget.conductor;
  final inicio = TextEditingController(text: fechaVista(hoyIso()));
  final fin = TextEditingController(text: fechaVista(hoyIso()));
  final motivo = TextEditingController();
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargar();
    inicio.addListener(() => setState(() {}));
    fin.addListener(() => setState(() {}));
    motivo.addListener(() => setState(() {}));
  }

  void cargar() {
    setState(() {
      futuro = _traer();
    });
  }

  Future<List<Conductor>> _traer() async {
    Pagina<Conductor> pagina = await Sitram.conductores(tam: 100);
    return pagina.items;
  }

  String? get errorFechas {
    final a = isoDeVista(inicio.text), b = isoDeVista(fin.text);
    if (a == null || b == null) return null;
    return b.compareTo(a) < 0
        ? 'La fecha final debe ser igual o posterior a la inicial.'
        : null;
  }

  bool get valido =>
      conductor != null &&
      motivo.text.trim().isNotEmpty &&
      errorFechas == null &&
      fin.text.isNotEmpty;

  Future<void> guardar() async {
    setState(() => guardando = true);
    try {
      await Sitram.crearSancion(SancionRequest(
        identificacionConductor: conductor!,
        motivo: motivo.text.trim(),
        fechaInicio: isoDeVista(inicio.text)!,
        fechaFin: isoDeVista(fin.text)!,
      ));
      if (!mounted) return;
      aviso(context, 'Sanción registrada');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Registrar sanción',
      atras: true,
      hijos: [
        Cargar<List<Conductor>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (lista) => CampoLista<String>(
            'Conductor',
            requerido: true,
            valor: conductor,
            opciones: [
              for (final c in lista) Opcion(c.identificacion, '${c.nombres} — CC ${c.identificacion}')
            ],
            alCambiar: (v) => setState(() => conductor = v),
          ),
        ),
        const Seccion('Periodo de la sanción'),
        Dos(
          Campo('Fecha inicial',
              requerido: true,
              control: inicio,
              sufijo: Icons.calendar_today_outlined,
              alTocar: () => elegirFecha(context, inicio)),
          Campo('Fecha final',
              requerido: true,
              control: fin,
              sufijo: Icons.calendar_today_outlined,
              error: errorFechas,
              alTocar: () => elegirFecha(context, fin)),
        ),
        Campo('Motivo de la sanción',
            requerido: true,
            control: motivo,
            hint: 'Ej: Incumplimiento de horario de despacho',
            lineas: 3),
        const Alerta(
            tipo: 'warn',
            texto:
                'Durante el periodo el conductor no podrá asignarse a planillas.'),
      ],
      abajo: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotonesForm(
              ok: guardando ? 'Guardando...' : 'Registrar sanción',
              alGuardar: valido && !guardando ? guardar : null),
          if (!valido)
            Text(
                'El botón se habilita con conductor, periodo y motivo válidos.',
                style: plex(11, c: C.tenue)),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S13DetalleSancion extends StatefulWidget {
  final int id;
  const S13DetalleSancion({super.key, required this.id});

  @override
  State<S13DetalleSancion> createState() => _S13DetalleSancionState();
}

class _S13DetalleSancionState extends State<S13DetalleSancion> {
  Future<Sancion>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.sancion(widget.id);
    });
  }

  void cambiarEstado(String estado, String pregunta) {
    confirmar(context,
        titulo: pregunta,
        texto: 'La sanción dejará de bloquear al conductor.',
        ok: 'Sí, continuar', alAceptar: () async {
      try {
        await Sitram.actualizarSancion(
            widget.id, ActualizarSancionRequest(estado: estado));
        if (!mounted) return;
        aviso(context, 'Sanción actualizada');
        cargar();
      } catch (e) {
        if (mounted) aviso(context, '$e', error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de sanción',
      atras: true,
      hijos: [
        Cargar<Sancion>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (s) {
            final chip = chipSancion(s);
            final rojo = chip.tipo == 'mal';
            final dias = diasHasta(s.fechaFin);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Tarjeta(
                  color: rojo ? const Color(0xFFFBE9E7) : Colors.white,
                  borde: rojo ? const Color(0xFFF2C4BE) : C.borde,
                  hijos: [
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ESTADO',
                                  style: archivo(10.5,
                                      c: rojo ? C.error : C.medio, espacio: 1)),
                              Text(chip.texto,
                                  style:
                                      archivo(22, c: rojo ? C.error : C.texto)),
                              if (rojo)
                                Text('Faltan $dias días para finalizar',
                                    style: plex(12, c: C.error)),
                            ]),
                      ),
                      Icon(
                          rojo
                              ? Icons.warning_amber_rounded
                              : Icons.shield_outlined,
                          color: rojo ? C.error : C.tenue,
                          size: 30),
                    ]),
                  ],
                ),
                const Seccion('Conductor'),
                TarjetaDatos({
                  'Nombres':
                      s.nombresConductor.isEmpty ? '—' : s.nombresConductor,
                  'Identificación': s.identificacionConductor
                }),
                const Seccion('Periodo y motivo'),
                TarjetaDatos({
                  'Fecha inicial': fechaVista(s.fechaInicio),
                  'Fecha final': fechaVista(s.fechaFin),
                  'Motivo': s.motivo,
                }),
                const Seccion('Trazabilidad'),
                TarjetaDatos({
                  'Fecha de registro': fechaHoraVista(s.fechaRegistro),
                  'Última actualización': fechaHoraVista(s.ultimaActualizacion),
                }),
                Btn('Ver conductor',
                    tipo: 'contorno',
                    alTocar: () =>
                        ir(context, Rutas.detalleConductor, s.identificacionConductor)),
                if (s.estado == 'ACTIVA') ...[
                  Btn('Marcar como cumplida',
                      alTocar: () =>
                          cambiarEstado('CUMPLIDA', '¿Marcar como cumplida?')),
                  Btn('Anular sanción',
                      tipo: 'peligro',
                      alTocar: () =>
                          cambiarEstado('ANULADA', '¿Anular la sanción?')),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DatosConductores {
  final Pagina<Conductor> conductores;
  final Map<String, String> sancionados;
  _DatosConductores(this.conductores, this.sancionados);
}

class _DatosConductor {
  final Conductor conductor;
  final List<Sancion> sanciones;
  _DatosConductor(this.conductor, this.sanciones);
}
