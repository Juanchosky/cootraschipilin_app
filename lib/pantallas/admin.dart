import 'package:flutter/material.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../models/requests.dart';
import '../services/sitram_service.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/////////////////////////////////////////////////////////////////

class S20Tarifas extends StatefulWidget {
  const S20Tarifas({super.key});

  @override
  State<S20Tarifas> createState() => _S20TarifasState();
}

class _S20TarifasState extends State<S20Tarifas> {
  int pagina = 1;
  bool? activo = true;
  Future<Pagina<Tarifa>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.tarifas(pagina: pagina, activo: activo);
    });
  }

  Widget tarjeta(Tarifa t) {
    return GestureDetector(
      onTap: () async {
        await ir(context, Rutas.detalleTarifa, t.id);
        cargar();
      },
      child: Tarjeta(
        hijos: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tarifa #${t.id}', style: archivo(16, w: FontWeight.w600)),
                Text('Registrada el ${fechaHoraVista(t.fechaRegistro)}', style: plex(12, c: C.tenue)),
              ]),
            ),
            ChipEstado(t.activo ? 'Activa' : 'Inactiva', tipo: t.activo ? 'ok' : 'gris'),
          ]),
          const Divider(height: 22, color: C.borde),
          for (final c in {
            'Aportes gastos varios': t.aportesGastosVarios,
            'Fondo de reposición': t.fondoReposicion,
            'Aporte social del socio': t.aporteSocialSocio,
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(c.key, style: plex(12.5, c: C.medio))),
                Text(pesos(c.value), style: plex(12.5, w: FontWeight.w600)),
              ]),
            ),
          Row(children: [
            Text(pesos(t.total), style: archivo(22, c: t.activo ? C.verde : C.texto)),
            const SizedBox(width: 8),
            Text('Total', style: plex(12, c: C.tenue)),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Administración',
      tabs: tabsAdmin,
      tabActual: Rutas.tarifas,
      nav: Rutas.tarifas,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.registrarTarifa) == true) cargar();
      }),
      hijos: [
        Filtros(['Activas', 'Inactivas', 'Todas'], alCambiar: (i) {
          activo = [true, false, null][i];
          pagina = 1;
          cargar();
        }),
        Cargar<Pagina<Tarifa>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            if (p.items.isEmpty) {
              return const Vacio(icono: Icons.payments_outlined, titulo: 'Sin tarifas', texto: 'Registre una tarifa con el botón +.');
            }
            return Column(children: [
              for (final t in p.items) tarjeta(t),
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

class S21RegistrarTarifa extends StatefulWidget {
  const S21RegistrarTarifa({super.key});

  @override
  State<S21RegistrarTarifa> createState() => _S21RegistrarTarifaState();
}

class _S21RegistrarTarifaState extends State<S21RegistrarTarifa> {
  final gastos = TextEditingController();
  final fondo = TextEditingController();
  final aporte = TextEditingController();
  bool activo = true;
  bool guardando = false;

  double _n(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(' ', '')) ?? 0;
  double get total => _n(gastos) + _n(fondo) + _n(aporte);

  Future<void> guardar() async {
    if (faltanCampos(context, {'Aportes gastos varios': gastos.text, 'Fondo de reposición': fondo.text, 'Aporte social': aporte.text})) {
      return;
    }
    setState(() => guardando = true);
    try {
      await Sitram.crearTarifa(TarifaRequest(_n(gastos), _n(fondo), _n(aporte), activo));
      if (!mounted) return;
      aviso(context, 'Tarifa registrada por ${pesos(total)}');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Registrar tarifa',
      atras: true,
      hijos: [
        const Seccion('Componentes'),
        Campo('Aportes gastos varios', requerido: true, control: gastos, icono: Icons.attach_money,
            teclado: TextInputType.number, alCambiar: (_) => setState(() {})),
        Campo('Fondo de reposición', requerido: true, control: fondo, icono: Icons.attach_money,
            teclado: TextInputType.number, alCambiar: (_) => setState(() {})),
        Campo('Aporte social del socio', requerido: true, control: aporte, icono: Icons.attach_money,
            teclado: TextInputType.number, alCambiar: (_) => setState(() {})),
        Tarjeta(
          color: C.verdeHondo,
          borde: C.verdeHondo,
          hijos: [
            Text('TOTAL CALCULADO', style: archivo(10.5, c: Colors.white70, espacio: 1)),
            Text(pesos(total), style: archivo(26, c: Colors.white)),
            Text('Se recalcula al cambiar cualquier componente.', style: plex(11.5, c: Colors.white60)),
          ],
        ),
        TarjetaSwitch(
          titulo: 'Activar esta tarifa',
          sub: 'Queda disponible para vehículos y planillas.',
          valor: activo,
          alCambiar: (v) => setState(() => activo = v),
        ),
      ],
      abajo: BotonesForm(ok: guardando ? 'Guardando...' : 'Guardar', alGuardar: guardando ? null : guardar),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S22DetalleTarifa extends StatefulWidget {
  final int id;
  const S22DetalleTarifa({super.key, required this.id});

  @override
  State<S22DetalleTarifa> createState() => _S22DetalleTarifaState();
}

class _S22DetalleTarifaState extends State<S22DetalleTarifa> {
  Future<Tarifa>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.tarifa(widget.id);
    });
  }

  void inactivar() {
    confirmar(context,
        titulo: '¿Inactivar tarifa?',
        texto: 'La tarifa queda en el histórico y no se podrá usar en planillas nuevas.',
        ok: 'Sí, inactivar', alAceptar: () async {
      try {
        await Sitram.inactivarTarifa(widget.id);
        if (!mounted) return;
        aviso(context, 'Tarifa inactivada');
        cargar();
      } catch (e) {
        if (mounted) aviso(context, '$e', error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Tarifa #${widget.id}',
      atras: true,
      hijos: [
        Cargar<Tarifa>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (t) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(
                color: C.verdeHondo,
                borde: C.verdeHondo,
                hijos: [
                  Text('TOTAL', style: archivo(10.5, c: Colors.white70, espacio: 1)),
                  Text(pesos(t.total), style: archivo(30, c: Colors.white)),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ChipEstado(t.activo ? 'Activa' : 'Inactiva', tipo: t.activo ? 'ok' : 'gris'),
                  ),
                ],
              ),
              const Seccion('Componentes'),
              TarjetaDatos({
                'Aportes gastos varios': pesos(t.aportesGastosVarios),
                'Fondo de reposición': pesos(t.fondoReposicion),
                'Aporte social del socio': pesos(t.aporteSocialSocio),
                'Total': pesos(t.total),
              }),
              const Seccion('Registro'),
              TarjetaDatos({
                'ID': 'TR-${t.id}',
                'Fecha de registro': fechaHoraVista(t.fechaRegistro),
                'Última actualización': fechaHoraVista(t.ultimaActualizacion),
              }),
              if (t.activo) ...[
                const Alerta(tipo: 'warn', texto: 'Inactivar esta tarifa afecta a los vehículos que la usan. Registre primero la nueva tarifa.'),
                Btn('Inactivar tarifa', tipo: 'peligro', alTocar: inactivar),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S30Empresas extends StatefulWidget {
  const S30Empresas({super.key});

  @override
  State<S30Empresas> createState() => _S30EmpresasState();
}

class _S30EmpresasState extends State<S30Empresas> {
  int pagina = 1;
  int filtro = 0;
  String buscar = '';
  Future<Pagina<Empresa>>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.empresas(pagina: pagina);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Administración',
      tabs: tabsAdmin,
      tabActual: Rutas.empresas,
      nav: Rutas.tarifas,
      fab: Fab(alTocar: () async {
        if (await ir(context, Rutas.registrarEmpresa) == true) cargar();
      }),
      hijos: [
        Buscador(hint: 'Buscar por razón social o NIT', alBuscar: (t) => setState(() => buscar = t.trim().toLowerCase())),
        Filtros(['Activas', 'Inactivas', 'Todas'], alCambiar: (i) => setState(() => filtro = i)),
        Cargar<Pagina<Empresa>>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (p) {
            final lista = p.items.where((e) {
              if (filtro == 0 && !e.activo) return false;
              if (filtro == 1 && e.activo) return false;
              return buscar.isEmpty || e.razonSocial.toLowerCase().contains(buscar) || e.nit.contains(buscar);
            }).toList();
            if (lista.isEmpty) {
              return const Vacio(icono: Icons.business_outlined, titulo: 'Sin empresas', texto: 'No hay empresas con ese filtro.');
            }
            return Column(children: [
              Tarjeta(
                pad: 0,
                hijos: [
                  for (final e in lista)
                    FilaLista(
                      inicio: Caja(iniciales(e.razonSocial)),
                      titulo: e.razonSocial,
                      sub: 'NIT ${e.nit}',
                      derecha: ChipEstado(e.activo ? 'Activa' : 'Inactiva', tipo: e.activo ? 'ok' : 'gris'),
                      alTocar: () async {
                        await ir(context, Rutas.detalleEmpresa, e.id);
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

class S31RegistrarEmpresa extends StatefulWidget {
  const S31RegistrarEmpresa({super.key});

  @override
  State<S31RegistrarEmpresa> createState() => _S31RegistrarEmpresaState();
}

class _S31RegistrarEmpresaState extends State<S31RegistrarEmpresa> {
  int paso = 1;
  final razon = TextEditingController();
  final nit = TextEditingController();
  final gIdentificacion = TextEditingController();
  final gNombres = TextEditingController();
  final gUsername = TextEditingController();
  bool guardando = false;

  void continuar() {
    if (faltanCampos(context, {'Razón social': razon.text, 'NIT': nit.text})) return;
    setState(() => paso = 2);
  }

  Future<void> guardar() async {
    if (faltanCampos(context, {'Identificación': gIdentificacion.text, 'Nombres': gNombres.text, 'Username': gUsername.text})) return;
    setState(() => guardando = true);
    try {
      final c = await Sitram.crearEmpresa(EmpresaRequest(
        razonSocial: razon.text.trim(),
        nit: nit.text.trim(),
        gerenteIdentificacion: gIdentificacion.text.trim(),
        gerenteNombres: gNombres.text.trim(),
        gerenteUsername: gUsername.text.trim(),
      ));
      if (!mounted) return;
      await mostrarCredencial(context, 'Empresa registrada', c.username, c.password);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Registrar empresa',
      subtitulo: 'Paso $paso de 2',
      atras: true,
      hijos: [
        Row(children: [
          for (int i = 1; i <= 2; i++)
            Expanded(
              child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), color: i <= paso ? C.verde : C.borde),
            ),
        ]),
        const SizedBox(height: 12),
        if (paso == 1) ...[
          const Seccion('Datos de la empresa'),
          Campo('Razón social', requerido: true, control: razon),
          Campo('NIT', requerido: true, control: nit, hint: '901 442 118-3'),
        ] else ...[
          Tarjeta(hijos: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Paso 1 · Datos de la empresa', style: plex(12.5, w: FontWeight.w600)),
                  Text('${razon.text} · NIT ${nit.text}', style: plex(11, c: C.tenue)),
                ]),
              ),
              const Icon(Icons.check_circle_outline, color: C.exito, size: 18),
              TextButton(
                onPressed: () => setState(() => paso = 1),
                child: Text('Editar', style: plex(12, w: FontWeight.w600, c: C.verde)),
              ),
            ]),
          ]),
          const Seccion('Primer gerente'),
          Text('Este usuario administrará la empresa y podrá registrar a los demás usuarios.', style: plex(12, c: C.medio)),
          const SizedBox(height: 12),
          Campo('Identificación', requerido: true, control: gIdentificacion, teclado: TextInputType.number),
          Campo('Nombres', requerido: true, control: gNombres),
          Campo('Username', requerido: true, control: gUsername, ayuda: 'Se usará para iniciar sesión. No podrá cambiarse después.'),
          const Alerta(tipo: 'info', texto: 'La contraseña inicial se genera automáticamente y deberá cambiarse en el primer ingreso.'),
        ],
      ],
      abajo: paso == 1
          ? Btn('Continuar', alTocar: continuar)
          : Row(children: [
              Expanded(child: Btn('Volver', tipo: 'contorno', alTocar: () => setState(() => paso = 1))),
              const SizedBox(width: 12),
              Expanded(child: Btn(guardando ? 'Guardando...' : 'Registrar', alTocar: guardando ? null : guardar)),
            ]),
    );
  }
}

/////////////////////////////////////////////////////////////////

class S32DetalleEmpresa extends StatefulWidget {
  final int id;
  const S32DetalleEmpresa({super.key, required this.id});

  @override
  State<S32DetalleEmpresa> createState() => _S32DetalleEmpresaState();
}

class _S32DetalleEmpresaState extends State<S32DetalleEmpresa> {
  Future<Empresa>? futuro;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      futuro = Sitram.empresa(widget.id);
    });
  }

  Future<void> editar(Empresa e) async {
    final razon = TextEditingController(text: e.razonSocial);
    final nit = TextEditingController(text: e.nit);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Editar empresa', style: archivo(17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Campo('Razón social', control: razon),
          Campo('NIT', control: nit),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Sitram.actualizarEmpresa(e.id, razon.text.trim(), nit.text.trim());
      if (!mounted) return;
      aviso(context, 'Datos actualizados');
      cargar();
    } catch (x) {
      if (mounted) aviso(context, '$x', error: true);
    }
  }

  void cambiarEstado(Empresa e) {
    confirmar(context,
        titulo: e.activo ? '¿Inactivar empresa?' : '¿Activar empresa?',
        texto: e.activo ? 'Los usuarios de la empresa no podrán iniciar sesión.' : 'Los usuarios podrán volver a ingresar.',
        ok: 'Sí, continuar', alAceptar: () async {
      try {
        await Sitram.cambiarEstadoEmpresa(e.id, !e.activo);
        if (!mounted) return;
        aviso(context, 'Estado actualizado');
        cargar();
      } catch (x) {
        if (mounted) aviso(context, '$x', error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Detalle de empresa',
      atras: true,
      hijos: [
        Cargar<Empresa>(
          futuro: futuro,
          alReintentar: cargar,
          contenido: (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tarjeta(hijos: [
                Row(children: [
                  Caja(iniciales(e.razonSocial)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.razonSocial, style: archivo(15))),
                  ChipEstado(e.activo ? 'Activa' : 'Inactiva', tipo: e.activo ? 'ok' : 'gris'),
                ]),
              ]),
              const Seccion('Datos de la empresa'),
              TarjetaDatos({
                'ID': 'EM-${e.id}',
                'Razón social': e.razonSocial,
                'NIT': e.nit,
                'Versión de seguridad': 'v${e.versionSeguridad}',
              }),
              const Seccion('Trazabilidad'),
              TarjetaDatos({
                'Fecha de registro': fechaHoraVista(e.fechaRegistro),
                'Última actualización': fechaHoraVista(e.ultimaActualizacion),
              }),
              Btn('Editar razón social / NIT', alTocar: () => editar(e)),
              Btn(e.activo ? 'Inactivar empresa' : 'Activar empresa',
                  tipo: e.activo ? 'peligro' : 'contorno', alTocar: () => cambiarEstado(e)),
            ],
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class S33RegistrarUsuario extends StatefulWidget {
  const S33RegistrarUsuario({super.key});

  @override
  State<S33RegistrarUsuario> createState() => _S33RegistrarUsuarioState();
}

class _S33RegistrarUsuarioState extends State<S33RegistrarUsuario> {
  final identificacion = TextEditingController();
  final nombres = TextEditingController();
  final username = TextEditingController();
  final clave = TextEditingController();
  String rol = 'ASISTENTE';
  bool activo = true;
  bool guardando = false;

  static const roles = {
    'GERENTE': 'Operación completa. Puede sancionar conductores.',
    'ASISTENTE': 'Operación diaria. Puede sancionar conductores.',
  };

  bool get claveValida {
    final t = clave.text;
    return t.length >= 12 && t.contains(RegExp(r'[A-Z]')) && t.contains(RegExp(r'[a-z]')) && t.contains(RegExp(r'[0-9]'));
  }

  Future<void> guardar() async {
    if (faltanCampos(context, {
      'Identificación': identificacion.text,
      'Nombres': nombres.text,
      'Username': username.text,
      'Contraseña': clave.text,
    })) return;
    if (!claveValida) {
      aviso(context, 'La contraseña necesita 12 caracteres, mayúscula, minúscula y número.', error: true);
      return;
    }
    setState(() => guardando = true);
    try {
      await Sitram.registrarUsuario(UsuarioRequest(
        identificacion: identificacion.text.trim(),
        nombres: nombres.text.trim(),
        username: username.text.trim(),
        password: clave.text,
        rol: rol,
        activo: activo,
      ));
      if (!mounted) return;
      aviso(context, 'Usuario ${username.text.trim()} registrado como ${capital(rol)}');
      for (final c in [identificacion, nombres, username, clave]) {
        c.clear();
      }
    } catch (e) {
      if (mounted) aviso(context, '$e', error: true);
    }
    if (mounted) setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      titulo: 'Administración',
      tabs: tabsAdmin,
      tabActual: Rutas.usuarios,
      nav: Rutas.tarifas,
      hijos: [
        const Seccion('Datos del usuario'),
        Campo('Identificación', requerido: true, control: identificacion, teclado: TextInputType.number),
        Campo('Nombres', requerido: true, control: nombres),
        Campo('Username', requerido: true, control: username),
        Campo('Contraseña',
            requerido: true,
            control: clave,
            clave: true,
            alCambiar: (_) => setState(() {}),
            error: clave.text.isNotEmpty && !claveValida ? 'Mínimo 12 caracteres con mayúscula, minúscula y número.' : null),
        const Seccion('Rol'),
        Tarjeta(
          pad: 0,
          hijos: [
            for (final r in roles.entries)
              ListTile(
                onTap: () => setState(() => rol = r.key),
                title: Text(r.key, style: plex(13, w: FontWeight.w600)),
                subtitle: Text(r.value, style: plex(12, c: C.medio)),
                trailing: Icon(rol == r.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: rol == r.key ? C.verde : C.tenue),
              ),
          ],
        ),
        TarjetaSwitch(
          titulo: 'Usuario activo',
          sub: 'Puede iniciar sesión desde ya.',
          valor: activo,
          alCambiar: (v) => setState(() => activo = v),
        ),
        Btn(guardando ? 'Registrando...' : 'Registrar', alTocar: guardando ? null : guardar),
      ],
    );
  }
}
