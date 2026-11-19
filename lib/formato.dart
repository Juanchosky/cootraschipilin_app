
String dosDig(int n) => n.toString().padLeft(2, '0');

String isoFecha(DateTime d) => '${d.year}-${dosDig(d.month)}-${dosDig(d.day)}';

String hoyIso() => isoFecha(DateTime.now());

String fechaVista(String? iso) {
  if (iso == null || iso.length < 10) return '—';
  final p = iso.substring(0, 10).split('-');
  if (p.length != 3) return iso;
  return '${p[2]}/${p[1]}/${p[0]}';
}

String? isoDeVista(String texto) {
  final p = texto.trim().split('/');
  if (p.length != 3) return null;
  return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
}

String fechaHoraVista(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final l = d.toLocal();
  return '${dosDig(l.day)}/${dosDig(l.month)}/${l.year} ${dosDig(l.hour)}:${dosDig(l.minute)}';
}

String horaVista(String? h) {
  if (h == null || h.length < 5) return '—';
  final hh = int.tryParse(h.substring(0, 2)) ?? 0;
  final mm = h.substring(3, 5);
  final h12 = hh % 12 == 0 ? 12 : hh % 12;
  return '$h12:$mm ${hh < 12 ? 'a. m.' : 'p. m.'}';
}

String pesos(num valor) {
  final s = valor.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '\$ $buf';
}

String iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0][0].toUpperCase();
  return (partes[0][0] + partes[partes.length > 2 ? partes.length - 2 : 1][0]).toUpperCase();
}

String capital(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1).toLowerCase().replaceAll('_', ' ');

int diasHasta(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return 0;
  final hoy = DateTime.now();
  return d.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
}

String? fechaHoraConZona(String fecha, String hora) {
  final f = isoDeVista(fecha);
  if (f == null || hora.length < 5) return null;
  final d = DateTime.tryParse('${f}T${hora.substring(0, 5)}:00');
  if (d == null) return null;
  final z = d.timeZoneOffset;
  final signo = z.isNegative ? '-' : '+';
  final horas = dosDig(z.inHours.abs());
  final minutos = dosDig(z.inMinutes.abs() % 60);
  return '${f}T${hora.substring(0, 5)}:00$signo$horas:$minutos';
}

String horaActual() {
  final h = DateTime.now();
  return '${dosDig(h.hour)}:${dosDig(h.minute)}';
}
