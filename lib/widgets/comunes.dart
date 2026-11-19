import 'package:flutter/material.dart';
import '../formato.dart';
import '../rutas.dart';
import '../services/sesion.dart';
import '../tema.dart';

export '../rutas.dart';

Future<Object?> ir(BuildContext context, String ruta, [Object? argumentos]) =>
    Navigator.pushNamed(context, ruta, arguments: argumentos);

void cambiar(BuildContext context, String ruta) => Navigator.pushReplacementNamed(context, ruta);

void aviso(BuildContext context, String mensaje, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(mensaje),
    backgroundColor: error ? C.error : C.verdeHondo,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<void> confirmar(BuildContext context,
    {required String titulo, required String texto, required String ok, required VoidCallback alAceptar}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(titulo, style: archivo(17)),
      content: Text(texto, style: plex(13.5, c: C.medio)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancelar', style: plex(13.5, w: FontWeight.w600, c: C.medio)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            alAceptar();
          },
          child: Text(ok, style: plex(13.5, w: FontWeight.w700, c: C.error)),
        ),
      ],
    ),
  );
}

class Pestana {
  final String texto;
  final String ruta;
  const Pestana(this.texto, this.ruta);
}

class Opcion<T> {
  final T valor;
  final String texto;
  final bool activa;
  const Opcion(this.valor, this.texto, [this.activa = true]);
}

class BotonBarra {
  final String texto;
  final IconData icono;
  final String ruta;
  const BotonBarra(this.texto, this.icono, this.ruta);
}

const tabsPersonas = [
  Pestana('Asociados', Rutas.asociados),
  Pestana('Conductores', Rutas.conductores),
  Pestana('Sanciones', Rutas.sanciones),
];

const tabsOperacion = [
  Pestana('Vehículos', Rutas.vehiculos),
  Pestana('Afiliaciones', Rutas.afiliaciones),
  Pestana('Planillas', Rutas.planillas),
  Pestana('Despachos', Rutas.despachos),
  Pestana('Pagos', Rutas.pagos),
  Pestana('Mantenimiento', Rutas.mantenimientos),
];

List<Pestana> get tabsAdmin {
  List<Pestana> lista = [const Pestana('Tarifas', Rutas.tarifas)];
  if (Sesion.esAdmin) {
    lista.add(const Pestana('Empresas', Rutas.empresas));
  }
  lista.add(const Pestana('Usuarios', Rutas.usuarios));
  return lista;
}

class Base extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool atras;
  final List<Pestana>? tabs;
  final String? tabActual;
  final String? nav;
  final List<Widget> hijos;
  final Widget? fab;
  final Widget? abajo;

  const Base({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.atras = false,
    this.tabs,
    this.tabActual,
    this.nav,
    required this.hijos,
    this.fab,
    this.abajo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.fondo,
      body: Column(
        children: [
          Container(
            color: C.verde,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(atras ? 4 : 16, 10, 16, tabs == null ? 16 : 8),
                    child: Row(
                      children: [
                        if (atras)
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(titulo, style: archivo(19, w: FontWeight.w600, c: Colors.white)),
                              if (subtitulo != null)
                                Text(subtitulo!, style: plex(12, c: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tabs != null) _pestanas(context),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, fab != null ? 90 : 20),
              children: hijos,
            ),
          ),
          if (abajo != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SafeArea(top: false, child: abajo!),
            ),
        ],
      ),
      floatingActionButton: fab,
      bottomNavigationBar: nav == null ? null : BarraInferior(activo: nav!),
    );
  }

  Widget _pestanas(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final t in tabs!)
            InkWell(
              onTap: t.ruta == tabActual ? null : () => cambiar(context, t.ruta),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: t.ruta == tabActual ? C.ocre : Colors.transparent, width: 3),
                  ),
                ),
                child: Text(
                  t.texto,
                  style: plex(13,
                      w: t.ruta == tabActual ? FontWeight.w700 : FontWeight.w500,
                      c: t.ruta == tabActual ? Colors.white : Colors.white60),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BarraInferior extends StatelessWidget {
  final String activo;
  const BarraInferior({super.key, required this.activo});

  List<BotonBarra> botones() {
    if (Sesion.esAsociado) {
      return const [
        BotonBarra('Vehículos', Icons.directions_car_outlined, Rutas.misVehiculos),
        BotonBarra('Viajes', Icons.route_outlined, Rutas.misViajes),
        BotonBarra('Despachos', Icons.location_on_outlined, Rutas.misDespachos),
        BotonBarra('Mi cuenta', Icons.account_circle_outlined, Rutas.miCuenta),
      ];
    }
    List<BotonBarra> lista = [
      const BotonBarra('Inicio', Icons.home_outlined, Rutas.inicio),
      const BotonBarra('Personas', Icons.person_outline, Rutas.asociados),
      const BotonBarra('Operación', Icons.directions_bus_outlined, Rutas.vehiculos),
    ];
    if (Sesion.esGerente) {
      lista.add(const BotonBarra('Admin', Icons.description_outlined, Rutas.tarifas));
    }
    lista.add(const BotonBarra('Mi cuenta', Icons.account_circle_outlined, Rutas.miCuenta));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final items = botones();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: C.borde)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final it in items)
                Expanded(
                  child: InkWell(
                    onTap: it.ruta == activo
                        ? null
                        : () => Navigator.pushNamedAndRemoveUntil(context, it.ruta, (r) => false),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(it.icono, size: 22, color: it.ruta == activo ? C.verde : C.tenue),
                        const SizedBox(height: 3),
                        Text(it.texto,
                            style: plex(11,
                                w: it.ruta == activo ? FontWeight.w700 : FontWeight.w500,
                                c: it.ruta == activo ? C.verde : C.tenue)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Fab extends StatelessWidget {
  final VoidCallback alTocar;
  const Fab({super.key, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: C.ocre,
      foregroundColor: Colors.white,
      onPressed: alTocar,
      child: const Icon(Icons.add),
    );
  }
}

class Seccion extends StatelessWidget {
  final String texto;
  final Widget? derecha;
  const Seccion(this.texto, {super.key, this.derecha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(texto.toUpperCase(), style: archivo(11, c: C.medio, espacio: 1.1)),
          ),
          if (derecha != null) derecha!,
        ],
      ),
    );
  }
}

class Tarjeta extends StatelessWidget {
  final List<Widget> hijos;
  final double pad;
  final Color color;
  final Color borde;
  const Tarjeta({super.key, required this.hijos, this.pad = 14, this.color = Colors.white, this.borde = C.borde});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borde),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: hijos),
        ),
      ),
    );
  }
}

class TarjetaDatos extends StatelessWidget {
  final Map<String, Object> datos;
  const TarjetaDatos(this.datos, {super.key});

  @override
  Widget build(BuildContext context) {
    final claves = datos.keys.toList();
    return Tarjeta(
      pad: 0,
      hijos: [
        for (int i = 0; i < claves.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: i == claves.length - 1 ? null : const Border(bottom: BorderSide(color: C.borde)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claves[i], style: plex(12.5, c: C.tenue)),
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: datos[claves[i]] is Widget
                        ? datos[claves[i]] as Widget
                        : Text('${datos[claves[i]]}',
                            textAlign: TextAlign.right, style: plex(13, w: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class Campo extends StatelessWidget {
  final String etiqueta;
  final String? valor;
  final String? hint;
  final bool requerido;
  final bool lista;
  final bool clave;
  final bool foco;
  final IconData? icono;
  final IconData? sufijo;
  final String? error;
  final String? ayuda;
  final int lineas;
  final TextInputType? teclado;
  final ValueChanged<String>? alCambiar;
  final TextEditingController? control;
  final bool soloLectura;
  final VoidCallback? alTocar;

  const Campo(
    this.etiqueta, {
    super.key,
    this.valor,
    this.hint,
    this.requerido = false,
    this.lista = false,
    this.clave = false,
    this.foco = false,
    this.icono,
    this.sufijo,
    this.error,
    this.ayuda,
    this.lineas = 1,
    this.teclado,
    this.alCambiar,
    this.control,
    this.soloLectura = false,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final colorBorde = error != null ? C.error : (foco ? C.verde : C.borde);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(text: etiqueta, children: [
              if (requerido) TextSpan(text: ' *', style: plex(12, c: C.error)),
            ]),
            style: plex(11.5, w: FontWeight.w600, c: C.medio),
          ),
          const SizedBox(height: 6),
          if (lista)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorBorde),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(valor ?? hint ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: plex(13.5, c: valor == null ? C.tenue : C.texto)),
                  ),
                  const Icon(Icons.expand_more, color: C.tenue),
                ],
              ),
            )
          else
            TextFormField(
              controller: control,
              initialValue: control == null ? valor : null,
              obscureText: clave,
              maxLines: clave ? 1 : lineas,
              readOnly: soloLectura || alTocar != null,
              onTap: alTocar,
              keyboardType: teclado,
              onChanged: alCambiar,
              style: plex(13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: plex(13.5, c: C.tenue),
                filled: true,
                fillColor: soloLectura ? C.fondo : Colors.white,
                prefixIcon: icono == null ? null : Icon(icono, size: 18, color: C.tenue),
                suffixIcon: sufijo == null ? null : Icon(sufijo, size: 18, color: C.tenue),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorBorde, width: foco ? 2 : 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: error != null ? C.error : C.verde, width: 2),
                ),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(error!, style: plex(11, c: C.error)),
            ),
          if (ayuda != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(ayuda!, style: plex(11, c: C.medio)),
            ),
        ],
      ),
    );
  }
}

class Dos extends StatelessWidget {
  final Widget a, b;
  const Dos(this.a, this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
    );
  }
}

class ChipEstado extends StatelessWidget {
  final String texto;
  final String tipo;
  const ChipEstado(this.texto, {super.key, this.tipo = 'ok'});

  @override
  Widget build(BuildContext context) {
    Color color = C.exito;
    if (tipo == 'mal') color = C.error;
    if (tipo == 'warn') color = C.advertencia;
    if (tipo == 'gris') color = C.tenue;
    if (tipo == 'info') color = C.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(texto, style: plex(11, w: FontWeight.w600, c: color)),
        ],
      ),
    );
  }
}

String tipoDe(String estado) {
  switch (estado) {
    case 'Sancionado':
    case 'Vigente':
    case 'Anulada':
    case 'Cancelado':
      return 'mal';
    case 'Inactivo':
    case 'Inactiva':
    case 'Finalizada':
    case 'Cumplida':
      return 'gris';
    case 'SOAT por vencer':
    case 'Programada':
    case 'Suspendida':
    case 'Pendiente':
    case 'Temporal':
      return 'warn';
    default:
      return 'ok';
  }
}

class Alerta extends StatelessWidget {
  final String tipo;
  final String? titulo;
  final String texto;
  const Alerta({super.key, this.tipo = 'error', this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    Color color = C.error;
    IconData icono = Icons.warning_amber_rounded;
    if (tipo == 'warn') {
      color = C.advertencia;
      icono = Icons.error_outline;
    }
    if (tipo == 'info') {
      color = C.info;
      icono = Icons.info_outline;
    }
    if (tipo == 'ok') {
      color = C.exito;
      icono = Icons.check_circle_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) Text(titulo!, style: plex(13, w: FontWeight.w700, c: color)),
                Text(texto, style: plex(12.5, c: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Btn extends StatelessWidget {
  final String texto;
  final String tipo;
  final VoidCallback? alTocar;
  final IconData? icono;
  const Btn(this.texto, {super.key, this.tipo = 'primario', this.alTocar, this.icono});

  @override
  Widget build(BuildContext context) {
    Color fondo = C.verde;
    Color letra = Colors.white;
    Color borde = C.verde;
    if (tipo == 'acento') {
      fondo = C.ocre;
      borde = C.ocre;
    }
    if (tipo == 'contorno') {
      fondo = Colors.white;
      letra = C.verde;
    }
    if (tipo == 'peligro') {
      fondo = Colors.white;
      letra = C.error;
      borde = C.error;
    }
    if (tipo == 'fantasma') {
      fondo = Colors.transparent;
      letra = C.tenue;
      borde = Colors.transparent;
    }
    if (alTocar == null) {
      fondo = C.borde;
      letra = C.tenue;
      borde = C.borde;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Material(
          color: fondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borde, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: alTocar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(texto, style: plex(14, w: FontWeight.w600, c: letra)),
                if (icono != null) ...[
                  const SizedBox(width: 8),
                  Icon(icono, size: 18, color: letra),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BotonesForm extends StatelessWidget {
  final String ok;
  final VoidCallback? alGuardar;
  const BotonesForm({super.key, this.ok = 'Guardar', this.alGuardar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Btn('Cancelar', tipo: 'fantasma', alTocar: () => Navigator.pop(context))),
        const SizedBox(width: 12),
        Expanded(child: Btn(ok, alTocar: alGuardar)),
      ],
    );
  }
}

class Paginacion extends StatelessWidget {
  final int pagina;
  final int paginas;
  final ValueChanged<int> alCambiar;
  const Paginacion({super.key, required this.pagina, required this.paginas, required this.alCambiar});

  Widget _caja(String t, bool activa, VoidCallback? tocar) {
    return GestureDetector(
      onTap: tocar,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activa ? C.verde : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activa ? C.verde : C.borde),
        ),
        child: Text(t,
            style: plex(12, w: FontWeight.w600, c: activa ? Colors.white : (tocar == null ? C.borde : C.medio))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (paginas <= 1) return const SizedBox(height: 8);
    int desde = (pagina - 2).clamp(1, paginas).toInt();
    int hasta = (desde + 4).clamp(1, paginas).toInt();
    desde = (hasta - 4).clamp(1, paginas).toInt();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _caja('‹', false, pagina > 1 ? () => alCambiar(pagina - 1) : null),
          for (int i = desde; i <= hasta; i++) _caja('$i', i == pagina, i == pagina ? null : () => alCambiar(i)),
          _caja('›', false, pagina < paginas ? () => alCambiar(pagina + 1) : null),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String iniciales;
  final bool alerta;
  const Avatar(this.iniciales, {super.key, this.alerta = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: alerta ? C.ocre.withAlpha(40) : C.fondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(iniciales, style: archivo(13, c: alerta ? C.ocre : C.verde)),
    );
  }
}

class Caja extends StatelessWidget {
  final String texto;
  const Caja(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: C.fondo, borderRadius: BorderRadius.circular(10)),
      child: Text(texto, style: archivo(12, c: C.verde)),
    );
  }
}

class Buscador extends StatelessWidget {
  final String hint;
  final String? valor;
  final ValueChanged<String>? alBuscar;
  const Buscador({super.key, required this.hint, this.valor, this.alBuscar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: valor,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: alBuscar,
        style: plex(13.5),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: plex(13.5, c: C.tenue),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, size: 20, color: C.tenue),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.borde),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.verde, width: 2),
          ),
        ),
      ),
    );
  }
}

class Filtros extends StatefulWidget {
  final List<String> opciones;
  final int inicial;
  final ValueChanged<int>? alCambiar;
  const Filtros(this.opciones, {super.key, this.inicial = 0, this.alCambiar});

  @override
  State<Filtros> createState() => _FiltrosState();
}

class _FiltrosState extends State<Filtros> {
  late int sel = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < widget.opciones.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (sel == i) return;
                    setState(() => sel = i);
                    widget.alCambiar?.call(i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel == i ? C.verde : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel == i ? C.verde : C.borde),
                    ),
                    child: Text(widget.opciones[i],
                        style: plex(12.5, w: FontWeight.w600, c: sel == i ? Colors.white : C.texto)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FilaLista extends StatelessWidget {
  final Widget? inicio;
  final String titulo;
  final String? sub;
  final String? extra;
  final Widget? derecha;
  final bool marcada;
  final Color colorMarca;
  final VoidCallback? alTocar;

  const FilaLista({
    super.key,
    this.inicio,
    required this.titulo,
    this.sub,
    this.extra,
    this.derecha,
    this.marcada = false,
    this.colorMarca = C.error,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: marcada ? colorMarca : Colors.transparent, width: 3),
            bottom: const BorderSide(color: C.borde),
          ),
        ),
        child: Row(
          children: [
            if (inicio != null) ...[inicio!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: plex(14, w: FontWeight.w600)),
                  if (sub != null)
                    Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: plex(12, c: C.tenue)),
                  if (extra != null) Text(extra!, style: plex(12, w: FontWeight.w600, c: colorMarca)),
                ],
              ),
            ),
            if (derecha != null) ...[const SizedBox(width: 8), derecha!],
          ],
        ),
      ),
    );
  }
}

class TarjetaSwitch extends StatelessWidget {
  final String titulo;
  final String sub;
  final bool valor;
  final ValueChanged<bool> alCambiar;
  const TarjetaSwitch({super.key, required this.titulo, required this.sub, required this.valor, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      hijos: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: plex(13.5, w: FontWeight.w600)),
                  Text(sub, style: plex(11.5, c: C.tenue)),
                ],
              ),
            ),
            Switch(value: valor, activeTrackColor: C.verde, onChanged: alCambiar),
          ],
        ),
      ],
    );
  }
}

class Indicador extends StatelessWidget {
  final String titulo;
  final String numero;
  final String sub;
  final bool oscuro;
  const Indicador(this.titulo, this.numero, this.sub, {super.key, this.oscuro = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: oscuro ? C.verdeHondo : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: oscuro ? C.verdeHondo : C.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo.toUpperCase(),
              style: archivo(10.5, c: oscuro ? Colors.white70 : C.medio, espacio: 1)),
          const SizedBox(height: 4),
          Text(numero, style: archivo(26, c: oscuro ? Colors.white : C.texto)),
          Text(sub, style: plex(11, c: oscuro ? Colors.white60 : C.tenue)),
        ],
      ),
    );
  }
}

class CampoLista<T> extends StatelessWidget {
  final String etiqueta;
  final T? valor;
  final List<Opcion<T>> opciones;
  final ValueChanged<T?>? alCambiar;
  final bool requerido;
  final String? hint;
  final String? ayuda;

  const CampoLista(
    this.etiqueta, {
    super.key,
    required this.valor,
    required this.opciones,
    this.alCambiar,
    this.requerido = false,
    this.hint,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: C.borde),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(text: etiqueta, children: [
              if (requerido) TextSpan(text: ' *', style: plex(12, c: C.error)),
            ]),
            style: plex(11.5, w: FontWeight.w600, c: C.medio),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            value: opciones.any((o) => o.valor == valor) ? valor : null,
            isExpanded: true,
            hint: Text(hint ?? 'Seleccione', style: plex(13.5, c: C.tenue)),
            items: [
              for (final o in opciones)
                DropdownMenuItem<T>(
                  value: o.valor,
                  enabled: o.activa,
                  child: Text(o.texto,
                      overflow: TextOverflow.ellipsis, style: plex(13.5, c: o.activa ? C.texto : C.tenue)),
                ),
            ],
            onChanged: alCambiar,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: alCambiar == null ? C.fondo : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              enabledBorder: borde,
              disabledBorder: borde,
              focusedBorder: borde.copyWith(borderSide: const BorderSide(color: C.verde, width: 2)),
            ),
          ),
          if (ayuda != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(ayuda!, style: plex(11, c: C.medio)),
            ),
        ],
      ),
    );
  }
}

Future<void> elegirFecha(BuildContext context, TextEditingController c) async {
  final actual = DateTime.tryParse(isoDeVista(c.text) ?? '') ?? DateTime.now();
  final d = await showDatePicker(
    context: context,
    initialDate: actual,
    firstDate: DateTime(1940),
    lastDate: DateTime(2100),
  );
  if (d != null) c.text = fechaVista(isoFecha(d));
}

Future<void> elegirHora(BuildContext context, TextEditingController c) async {
  final p = c.text.split(':');
  final actual = p.length >= 2
      ? TimeOfDay(hour: int.tryParse(p[0]) ?? 6, minute: int.tryParse(p[1]) ?? 0)
      : const TimeOfDay(hour: 6, minute: 0);
  final t = await showTimePicker(context: context, initialTime: actual);
  if (t != null) c.text = '${dosDig(t.hour)}:${dosDig(t.minute)}';
}

bool faltanCampos(BuildContext context, Map<String, String> campos) {
  final vacios = campos.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key).toList();
  if (vacios.isEmpty) return false;
  aviso(context, 'Complete: ${vacios.join(', ')}', error: true);
  return true;
}

class Cargando extends StatelessWidget {
  const Cargando({super.key});

  Widget _barra(double ancho) {
    return Container(
      height: 12,
      width: ancho,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: C.borde, borderRadius: BorderRadius.circular(6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      hijos: [
        for (int i = 0; i < 3; i++) ...[
          _barra(170),
          _barra(240),
          if (i < 2) const Divider(height: 18, color: C.borde),
        ],
      ],
    );
  }
}

class Vacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  final String? textoBoton;
  final VoidCallback? alTocar;
  const Vacio({super.key, this.icono = Icons.inbox_outlined, required this.titulo, required this.texto, this.textoBoton, this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      pad: 26,
      hijos: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: C.fondo, shape: BoxShape.circle),
            child: Icon(icono, color: C.verde, size: 26),
          ),
        ),
        const SizedBox(height: 12),
        Text(titulo, textAlign: TextAlign.center, style: archivo(16)),
        const SizedBox(height: 6),
        Text(texto, textAlign: TextAlign.center, style: plex(12.5, c: C.medio)),
        if (textoBoton != null) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: alTocar,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: C.verde, width: 1.5)),
              child: Text(textoBoton!, style: plex(13, w: FontWeight.w600, c: C.verde)),
            ),
          ),
        ],
      ],
    );
  }
}

class ErrorVista extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;
  const ErrorVista({super.key, required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Vacio(
      icono: Icons.cloud_off_outlined,
      titulo: 'No se pudo cargar',
      texto: mensaje,
      textoBoton: 'Reintentar',
      alTocar: alReintentar,
    );
  }
}

class Cargar<T> extends StatelessWidget {
  final Future<T>? futuro;
  final Widget Function(T datos) contenido;
  final VoidCallback alReintentar;
  const Cargar({super.key, required this.futuro, required this.contenido, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Cargando();
        if (snap.hasError) return ErrorVista(mensaje: '${snap.error}', alReintentar: alReintentar);
        return contenido(snap.data as T);
      },
    );
  }
}

Future<void> mostrarCredencial(BuildContext context, String titulo, String usuario, String clave) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(titulo, style: archivo(17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anote estos datos, no se vuelven a mostrar.', style: plex(12.5, c: C.medio)),
          const SizedBox(height: 12),
          SelectableText('Usuario: $usuario', style: plex(14, w: FontWeight.w600)),
          SelectableText('Clave temporal: $clave', style: plex(14, w: FontWeight.w600)),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Listo'))],
    ),
  );
}

Future<String?> pedirTexto(BuildContext context, {required String titulo, required String etiqueta, String ok = 'Aceptar'}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(titulo, style: archivo(17)),
      content: TextField(
        controller: c,
        maxLines: 3,
        maxLength: 250,
        decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: Text(ok, style: plex(13.5, w: FontWeight.w700, c: C.error)),
        ),
      ],
    ),
  );
}
