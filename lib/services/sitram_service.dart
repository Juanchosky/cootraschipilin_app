import '../config.dart';
import '../formato.dart';
import '../models/modelos.dart';
import '../models/requests.dart';
import 'api_service.dart';
import 'sesion.dart';

class ErrorApi implements Exception {
  final String mensaje;
  ErrorApi(this.mensaje);
  @override
  String toString() => mensaje;
}

class Sitram {

  static Future<T> _llamar<T>(Future<ApiResponse<T>> Function() peticion) async {
    ApiResponse<T> r;
    try {
      r = await peticion();
    } on ApiException catch (e) {
      throw ErrorApi(e.message);
    }
    if (!r.isSuccess) throw ErrorApi(_mensaje(r));
    final datos = r.data;
    if (datos == null) throw ErrorApi('El servidor no devolvió datos.');
    return datos;
  }

  static String _mensaje(ApiResponse r) {
    final d = r.rawData;
    if (d is Map) {
      if (d['errors'] is Map) {
        final lista = (d['errors'] as Map).values.expand((v) => v is List ? v : [v]).join('\n');
        if (lista.isNotEmpty) return lista;
      }
      if (d['message'] != null) return '${d['message']}';
      if (d['title'] != null) return '${d['title']}';
    }
    if (r.statusCode == 403) return 'Su rol no tiene permiso para esta acción.';
    if (r.statusCode == 404) return 'El registro no existe.';
    return r.message ?? 'Error del servidor (${r.statusCode}).';
  }

  static Map<String, dynamic> _q(Map<String, dynamic> m) {
    m.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    return m;
  }

  static String _id(String v) => Uri.encodeComponent(v);

  static Future<LoginRespuesta> login(String usuario, String clave) => _llamar(() => api.post<LoginRespuesta>(
        '/api/auth/login',
        body: LoginRequest(usuario, clave).toJson(),
        parser: (d) => LoginRespuesta.fromJson(d as Json),
      ));

  static Future<LoginRespuesta> cambiarPassword(String nueva, String confirmacion) => _llamar(() => api.post<LoginRespuesta>(
        '/api/auth/cambiar-password',
        body: CambiarPasswordRequest(nueva, confirmacion).toJson(),
        headers: {'Authorization': 'Bearer ${Sesion.tokenCambio}'},
        parser: (d) => LoginRespuesta.fromJson(d as Json),
      ));

  static Future<dynamic> registrarUsuario(UsuarioRequest req) => _llamar(() => api.post<dynamic>(
        '/api/auth/registrar',
        body: req.toJson(),
      ));

  static Future<Pagina<Asociado>> asociados({int pagina = 1, int tam = tamPagina, String? nombres, bool? activo}) =>
      _llamar(() => api.get<Pagina<Asociado>>('/api/asociados',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'nombres': nombres, 'activo': activo}),
          parser: (d) => paginaDe(d, Asociado.fromJson)));

  static Future<Asociado> asociado(String id) =>
      _llamar(() => api.get<Asociado>('/api/asociados/${_id(id)}', parser: (d) => unoDe(d, Asociado.fromJson)));

  static Future<Asociado> crearAsociado(AsociadoRequest req) =>
      _llamar(() => api.post<Asociado>('/api/asociados', body: req.toJson(), parser: (d) => unoDe(d, Asociado.fromJson)));

  static Future<Asociado> actualizarAsociado(String id, AsociadoRequest req) =>
      _llamar(() => api.put<Asociado>('/api/asociados/${_id(id)}', body: req.toJson(), parser: (d) => unoDe(d, Asociado.fromJson)));

  static Future<Credencial> credencialTemporal(String id) => _llamar(() => api.post<Credencial>(
      '/api/asociados/${_id(id)}/credencial-temporal',
      parser: (d) => unoDe(d, Credencial.deAsociado)));

  static Future<Pagina<Conductor>> conductores({int pagina = 1, int tam = tamPagina, String? nombres, bool? activo}) =>
      _llamar(() => api.get<Pagina<Conductor>>('/api/conductores',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'nombres': nombres, 'activo': activo}),
          parser: (d) => paginaDe(d, Conductor.fromJson)));

  static Future<Conductor> conductor(String id) =>
      _llamar(() => api.get<Conductor>('/api/conductores/${_id(id)}', parser: (d) => unoDe(d, Conductor.fromJson)));

  static Future<Conductor> crearConductor(ConductorRequest req) =>
      _llamar(() => api.post<Conductor>('/api/conductores', body: req.toJson(), parser: (d) => unoDe(d, Conductor.fromJson)));

  static Future<Conductor> actualizarConductor(String id, ConductorRequest req) =>
      _llamar(() => api.put<Conductor>('/api/conductores/${_id(id)}', body: req.toJson(), parser: (d) => unoDe(d, Conductor.fromJson)));

  static Future<Pagina<Vehiculo>> vehiculos({int pagina = 1, int tam = tamPagina, String? placa, String? tipo}) =>
      _llamar(() => api.get<Pagina<Vehiculo>>('/api/vehiculos',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'placa': placa, 'tipo': tipo}),
          parser: (d) => paginaDe(d, Vehiculo.fromJson)));

  static Future<Vehiculo> vehiculo(String placa) =>
      _llamar(() => api.get<Vehiculo>('/api/vehiculos/${_id(placa)}', parser: (d) => unoDe(d, Vehiculo.fromJson)));

  static Future<Vehiculo> crearVehiculo(VehiculoRequest req) =>
      _llamar(() => api.post<Vehiculo>('/api/vehiculos', body: req.toJson(), parser: (d) => unoDe(d, Vehiculo.fromJson)));

  static Future<Vehiculo> actualizarVehiculo(String placa, ActualizarVehiculoRequest req) =>
      _llamar(() => api.put<Vehiculo>('/api/vehiculos/${_id(placa)}', body: req.toJson(), parser: (d) => unoDe(d, Vehiculo.fromJson)));

  static Future<Pagina<Afiliacion>> afiliaciones({int pagina = 1, String? asociado, String? vehiculo, String? estado}) =>
      _llamar(() => api.get<Pagina<Afiliacion>>('/api/afiliaciones',
          queryParameters: _q({'page': pagina, 'pageSize': tamPagina, 'asociado': asociado, 'vehiculo': vehiculo, 'estado': estado}),
          parser: (d) => paginaDe(d, Afiliacion.fromJson)));

  static Future<Afiliacion> afiliacion(int id) =>
      _llamar(() => api.get<Afiliacion>('/api/afiliaciones/$id', parser: (d) => unoDe(d, Afiliacion.fromJson)));

  static Future<Afiliacion> crearAfiliacion(AfiliacionRequest req) =>
      _llamar(() => api.post<Afiliacion>('/api/afiliaciones', body: req.toJson(), parser: (d) => unoDe(d, Afiliacion.fromJson)));

  static Future<Afiliacion> actualizarAfiliacion(int id, AfiliacionRequest req) =>
      _llamar(() => api.put<Afiliacion>('/api/afiliaciones/$id', body: req.toJson(), parser: (d) => unoDe(d, Afiliacion.fromJson)));

  static Future<Afiliacion> finalizarAfiliacion(int id, String fechaFin) => _llamar(() => api.delete<Afiliacion>(
      '/api/afiliaciones/$id',
      body: {'fechaFinAfiliacion': fechaFin},
      parser: (d) => unoDe(d, Afiliacion.fromJson)));

  static Future<Pagina<Tarifa>> tarifas({int pagina = 1, int tam = tamPagina, bool? activo}) =>
      _llamar(() => api.get<Pagina<Tarifa>>('/api/tarifas',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'activo': activo}),
          parser: (d) => paginaDe(d, Tarifa.fromJson)));

  static Future<Tarifa> tarifa(int id) =>
      _llamar(() => api.get<Tarifa>('/api/tarifas/$id', parser: (d) => unoDe(d, Tarifa.fromJson)));

  static Future<Tarifa> crearTarifa(TarifaRequest req) =>
      _llamar(() => api.post<Tarifa>('/api/tarifas', body: req.toJson(), parser: (d) => unoDe(d, Tarifa.fromJson)));

  static Future<Tarifa> inactivarTarifa(int id) =>
      _llamar(() => api.delete<Tarifa>('/api/tarifas/$id', parser: (d) => unoDe(d, Tarifa.fromJson)));

  static Future<Pagina<Planilla>> planillas({int pagina = 1, int tam = tamPagina, String? fecha, String? vehiculo, String? estado}) =>
      _llamar(() => api.get<Pagina<Planilla>>('/api/planillas',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'fecha': fecha, 'vehiculo': vehiculo, 'estado': estado}),
          parser: (d) => paginaDe(d, Planilla.fromJson)));

  static Future<Planilla> planilla(int numero) =>
      _llamar(() => api.get<Planilla>('/api/planillas/$numero', parser: (d) => unoDe(d, Planilla.fromJson)));

  static Future<Planilla> crearPlanilla(PlanillaRequest req) =>
      _llamar(() => api.post<Planilla>('/api/planillas', body: req.toJson(), parser: (d) => unoDe(d, Planilla.fromJson)));

  static Future<PlanillaMasivaRespuesta> crearPlanillasMasivas(PlanillaMasivaRequest req) => _llamar(() => api.post<PlanillaMasivaRespuesta>(
      '/api/planillas/masivas',
      body: req.toJson(),
      parser: (d) => unoDe(d, PlanillaMasivaRespuesta.fromJson)));

  static Future<Planilla> anularPlanilla(int numero) =>
      _llamar(() => api.delete<Planilla>('/api/planillas/$numero', parser: (d) => unoDe(d, Planilla.fromJson)));

  static Future<Pago> registrarPago(int numeroPlanilla, [String? fechaPago]) => _llamar(() => api.post<Pago>(
      '/api/pagos',
      body: RegistrarPagoRequest(numeroPlanilla, fechaPago ?? hoyIso()).toJson(),
      parser: (d) => unoDe(d, Pago.fromJson)));

  static Future<Pagina<Pago>> pagos({int pagina = 1, int? numeroPlanilla, String? placa, String? desde, String? hasta}) =>
      _llamar(() => api.get<Pagina<Pago>>('/api/pagos',
          queryParameters: _q({'page': pagina, 'pageSize': tamPagina, 'numeroPlanilla': numeroPlanilla, 'placa': placa, 'desde': desde, 'hasta': hasta}),
          parser: (d) => paginaDe(d, Pago.fromJson)));

  static Future<Pago> pago(int id) =>
      _llamar(() => api.get<Pago>('/api/pagos/$id', parser: (d) => unoDe(d, Pago.fromJson)));

  static Future<Pagina<Mantenimiento>> mantenimientos({int pagina = 1, int tam = tamPagina, String? placa, String? estado}) =>
      _llamar(() => api.get<Pagina<Mantenimiento>>('/api/mantenimientos',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'placa': placa, 'estado': estado}),
          parser: (d) => paginaDe(d, Mantenimiento.fromJson)));

  static Future<Mantenimiento> mantenimiento(int id) =>
      _llamar(() => api.get<Mantenimiento>('/api/mantenimientos/$id', parser: (d) => unoDe(d, Mantenimiento.fromJson)));

  static Future<Mantenimiento> registrarIngreso(MantenimientoRequest req) => _llamar(() => api.post<Mantenimiento>(
      '/api/mantenimientos', body: req.toJson(), parser: (d) => unoDe(d, Mantenimiento.fromJson)));

  static Future<Mantenimiento> registrarSalida(int id, SalidaMantenimientoRequest req) => _llamar(() => api.put<Mantenimiento>(
      '/api/mantenimientos/$id', body: req.toJson(), parser: (d) => unoDe(d, Mantenimiento.fromJson)));

  static Future<Set<String>> placasEnTaller() async {
    final p = await mantenimientos(estado: 'EN_MANTENIMIENTO', tam: 100);
    return p.items.where((m) => m.abierto).map((m) => m.placaVehiculo.toUpperCase()).toSet();
  }

  static Future<Pagina<Despacho>> despachos({int pagina = 1, String? fecha, String? vehiculo, String? ruta}) =>
      _llamar(() => api.get<Pagina<Despacho>>('/api/despachos',
          queryParameters: _q({'page': pagina, 'pageSize': tamPagina, 'fecha': fecha, 'vehiculo': vehiculo, 'ruta': ruta}),
          parser: (d) => paginaDe(d, Despacho.fromJson)));

  static Future<Despacho> despacho(int id) =>
      _llamar(() => api.get<Despacho>('/api/despachos/$id', parser: (d) => unoDe(d, Despacho.fromJson)));

  static Future<Despacho> crearDespacho(DespachoRequest req) =>
      _llamar(() => api.post<Despacho>('/api/despachos', body: req.toJson(), parser: (d) => unoDe(d, Despacho.fromJson)));

  static Future<Despacho> cancelarDespacho(int id, String motivo) => _llamar(() => api.delete<Despacho>(
      '/api/despachos/$id',
      body: {'motivo': motivo},
      parser: (d) => unoDe(d, Despacho.fromJson)));

  static Future<Pagina<Sancion>> sanciones({int pagina = 1, int tam = tamPagina, String? conductor, String? estado}) =>
      _llamar(() => api.get<Pagina<Sancion>>('/api/sanciones',
          queryParameters: _q({'page': pagina, 'pageSize': tam, 'conductor': conductor, 'estado': estado}),
          parser: (d) => paginaDe(d, Sancion.fromJson)));

  static Future<Sancion> sancion(int id) =>
      _llamar(() => api.get<Sancion>('/api/sanciones/$id', parser: (d) => unoDe(d, Sancion.fromJson)));

  static Future<Sancion> crearSancion(SancionRequest req) =>
      _llamar(() => api.post<Sancion>('/api/sanciones', body: req.toJson(), parser: (d) => unoDe(d, Sancion.fromJson)));

  static Future<Sancion> actualizarSancion(int id, ActualizarSancionRequest req) =>
      _llamar(() => api.put<Sancion>('/api/sanciones/$id', body: req.toJson(), parser: (d) => unoDe(d, Sancion.fromJson)));

  static Future<List<Sancion>> sancionesActivas() async {
    final p = await sanciones(estado: 'ACTIVA', tam: 100);
    return p.items;
  }

  static Future<Map<String, String>> sancionadosEn(String fechaIso) async {
    final activas = await sancionesActivas();
    return {
      for (final s in activas)
        if (s.vigenteEn(fechaIso)) s.identificacionConductor: s.fechaFin,
    };
  }

  static Future<List<VehiculoAsociado>> misVehiculos() => _llamar(() => api.get<List<VehiculoAsociado>>(
      '/api/mi-cuenta/vehiculos',
      parser: (d) => listaDe(d, VehiculoAsociado.fromJson)));

  static Future<Pagina<Planilla>> misViajes({int pagina = 1, String? desde, String? hasta, String? placa}) =>
      _llamar(() => api.get<Pagina<Planilla>>('/api/mi-cuenta/viajes',
          queryParameters: _q({'page': pagina, 'pageSize': tamPagina, 'desde': desde, 'hasta': hasta, 'placa': placa}),
          parser: (d) => paginaDe(d, Planilla.fromJson)));

  static Future<Pagina<Despacho>> misDespachos({int pagina = 1, String? desde, String? hasta, String? placa, String? ruta}) =>
      _llamar(() => api.get<Pagina<Despacho>>('/api/mi-cuenta/despachos',
          queryParameters: _q({'page': pagina, 'pageSize': tamPagina, 'desde': desde, 'hasta': hasta, 'placa': placa, 'ruta': ruta}),
          parser: (d) => paginaDe(d, Despacho.fromJson)));

  static Future<Pagina<Empresa>> empresas({int pagina = 1}) => _llamar(() => api.get<Pagina<Empresa>>(
      '/api/plataforma/empresas',
      queryParameters: {'page': pagina, 'pageSize': tamPagina},
      parser: (d) => paginaDe(d, Empresa.fromJson)));

  static Future<Empresa> empresa(int id) =>
      _llamar(() => api.get<Empresa>('/api/plataforma/empresas/$id', parser: (d) => unoDe(d, Empresa.fromJson)));

  static Future<Credencial> crearEmpresa(EmpresaRequest req) => _llamar(() => api.post<Credencial>(
      '/api/plataforma/empresas',
      body: req.toJson(),
      parser: (d) => unoDe(d, Credencial.deEmpresa)));

  static Future<Empresa> actualizarEmpresa(int id, String razonSocial, String nit) => _llamar(() => api.put<Empresa>(
      '/api/plataforma/empresas/$id',
      body: {'razonSocial': razonSocial, 'nit': nit},
      parser: (d) => unoDe(d, Empresa.fromJson)));

  static Future<Empresa> cambiarEstadoEmpresa(int id, bool activo) => _llamar(() => api.patch<Empresa>(
      '/api/plataforma/empresas/$id/estado',
      body: {'activo': activo},
      parser: (d) => unoDe(d, Empresa.fromJson)));
}
