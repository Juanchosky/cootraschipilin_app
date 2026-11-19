
typedef Json = Map<String, dynamic>;

String _s(Json j, String k) => j[k] == null ? '' : '${j[k]}';
String? _n(Json j, String k) => j[k] == null ? null : '${j[k]}';
bool _b(Json j, String k) => j[k] == true;
int _i(Json j, String k) => j[k] is int ? j[k] as int : int.tryParse('${j[k]}') ?? 0;
double _d(Json j, String k) => j[k] is num ? (j[k] as num).toDouble() : double.tryParse('${j[k]}') ?? 0;

class Pagina<T> {
  final List<T> items;
  final int total;
  final int paginas;
  final int pagina;
  Pagina(this.items, this.total, this.paginas, this.pagina);
}

Pagina<T> paginaDe<T>(dynamic respuesta, T Function(Json) fromJson) {
  final data = (respuesta as Json)['data'] as Json;
  final items = (data['items'] as List).map((e) => fromJson(e as Json)).toList();
  final p = (data['pagination'] ?? <String, dynamic>{}) as Json;
  return Pagina<T>(
    items,
    p['totalItems'] is int ? p['totalItems'] as int : items.length,
    p['totalPages'] is int && p['totalPages'] > 0 ? p['totalPages'] as int : 1,
    p['page'] is int ? p['page'] as int : 1,
  );
}

T unoDe<T>(dynamic respuesta, T Function(Json) fromJson) {
  return fromJson((respuesta as Json)['data'] as Json);
}

List<T> listaDe<T>(dynamic respuesta, T Function(Json) fromJson) {
  return ((respuesta as Json)['data'] as List).map((e) => fromJson(e as Json)).toList();
}

class LoginRespuesta {
  final String token, identificacion, username, rol, empresa, nit;
  final int expiraEn;
  final bool requiereCambioPassword;

  LoginRespuesta.fromJson(Json j)
      : token = _s(j, 'token'),
        identificacion = _s(j, 'identificacion'),
        username = _s(j, 'username'),
        rol = _s(j, 'rol'),
        expiraEn = _i(j, 'expiraEn'),
        requiereCambioPassword = _b(j, 'requiereCambioPassword'),
        empresa = j['empresa'] is Map ? _s(j['empresa'] as Json, 'razonSocial') : '',
        nit = j['empresa'] is Map ? _s(j['empresa'] as Json, 'nit') : '';
}

class Asociado {
  final String identificacion, nombres, username, estadoCredencial, celular, correo;
  final String? fechaNacimiento, fechaIngreso, fechaRegistro, ultimaActualizacion;
  final bool activo;

  Asociado.fromJson(Json j)
      : identificacion = _s(j, 'identificacion'),
        nombres = _s(j, 'nombres'),
        username = _s(j, 'username'),
        estadoCredencial = _s(j, 'estadoCredencial'),
        celular = _s(j, 'celular'),
        correo = _s(j, 'correo'),
        fechaNacimiento = _n(j, 'fechaNacimiento'),
        fechaIngreso = _n(j, 'fechaIngreso'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion'),
        activo = _b(j, 'activo');
}

class Conductor {
  final String identificacion, nombres, numeroLicencia, categoriaLicencia, celular, correo;
  final String? fechaNacimiento, vigenciaLicencia, fechaRegistro, ultimaActualizacion;
  final bool activo;

  Conductor.fromJson(Json j)
      : identificacion = _s(j, 'identificacion'),
        nombres = _s(j, 'nombres'),
        numeroLicencia = _s(j, 'numeroLicencia'),
        categoriaLicencia = _s(j, 'categoriaLicencia'),
        celular = _s(j, 'celular'),
        correo = _s(j, 'correo'),
        fechaNacimiento = _n(j, 'fechaNacimiento'),
        vigenciaLicencia = _n(j, 'vigenciaLicencia'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion'),
        activo = _b(j, 'activo');
}

class Vehiculo {
  final String placa, identificacionConductor, tipo, marca, modelo, tarjetaPropiedad;
  final int capacidadPasajeros;
  final int? tarifaId;
  final double tarifaTotal;
  final bool activo;
  final String? vigenciaSoat, vigenciaTrm, fechaIngreso, fechaRegistro, ultimaActualizacion;

  Vehiculo.fromJson(Json j)
      : placa = _s(j, 'placa'),
        identificacionConductor = _s(j, 'identificacionConductor'),
        tipo = _s(j, 'tipo'),
        marca = _s(j, 'marca'),
        modelo = _s(j, 'modelo'),
        tarjetaPropiedad = _s(j, 'tarjetaPropiedad'),
        capacidadPasajeros = _i(j, 'capacidadPasajeros'),
        tarifaId = j['tarifa'] is Map ? _i(j['tarifa'] as Json, 'id') : null,
        tarifaTotal = j['tarifa'] is Map ? _d(j['tarifa'] as Json, 'total') : 0,
        activo = _b(j, 'activo'),
        vigenciaSoat = _n(j, 'vigenciaSoat'),
        vigenciaTrm = _n(j, 'vigenciaTrm'),
        fechaIngreso = _n(j, 'fechaIngreso'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion');

  bool get tieneConductor => identificacionConductor.isNotEmpty;
}

class Tarifa {
  final int id;
  final double aportesGastosVarios, fondoReposicion, aporteSocialSocio, total;
  final bool activo;
  final String? fechaRegistro, ultimaActualizacion;

  Tarifa.fromJson(Json j)
      : id = _i(j, 'id'),
        aportesGastosVarios = _d(j, 'aportesGastosVarios'),
        fondoReposicion = _d(j, 'fondoReposicion'),
        aporteSocialSocio = _d(j, 'aporteSocialSocio'),
        total = _d(j, 'total'),
        activo = _b(j, 'activo'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion');
}

class Afiliacion {
  final int id;
  final String identificacionAsociado, placaVehiculo, estado;
  final String? fechaAfiliacion, fechaFinAfiliacion, fechaRegistro, ultimaActualizacion;

  Afiliacion.fromJson(Json j)
      : id = _i(j, 'id'),
        identificacionAsociado = _s(j, 'identificacionAsociado'),
        placaVehiculo = _s(j, 'placaVehiculo'),
        estado = _s(j, 'estado'),
        fechaAfiliacion = _n(j, 'fechaAfiliacion'),
        fechaFinAfiliacion = _n(j, 'fechaFinAfiliacion'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion');
}

class Planilla {
  final int numero;
  final int? tarifaId;
  final String placaVehiculo, tipo, estado, registradoPor, estadoPago, conductorId, conductorNombre;
  final String? fecha, hora, fechaRegistro, fechaPago;
  final double valorPagado;

  Planilla.fromJson(Json j)
      : numero = _i(j, 'numero'),
        tarifaId = j['tarifaId'] == null ? null : _i(j, 'tarifaId'),
        placaVehiculo = _s(j, 'placaVehiculo'),
        tipo = _s(j, 'tipo'),
        estado = _s(j, 'estado'),
        registradoPor = _s(j, 'registradoPor'),
        estadoPago = _s(j, 'estadoPago'),
        conductorId = j['conductor'] is Map
            ? '${(j['conductor'] as Json)['Identificacion'] ?? (j['conductor'] as Json)['identificacion'] ?? ''}'
            : '',
        conductorNombre = j['conductor'] is Map
            ? '${(j['conductor'] as Json)['Nombre del conductor'] ?? (j['conductor'] as Json)['nombre'] ?? ''}'
            : '',
        fecha = _n(j, 'fecha'),
        hora = _n(j, 'hora'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        fechaPago = _n(j, 'fechaPago'),
        valorPagado = _d(j, 'valorPagado');
}

class PlanillaMasivaRespuesta {
  final int totalSolicitadas, totalRegistradas, totalRechazadas;
  final List<String> rechazos;

  PlanillaMasivaRespuesta.fromJson(Json j)
      : totalSolicitadas = _i(j, 'totalSolicitadas'),
        totalRegistradas = _i(j, 'totalRegistradas'),
        totalRechazadas = _i(j, 'totalRechazadas'),
        rechazos = ((j['rechazadas'] ?? []) as List)
            .map((r) => '${(r as Json)['placaVehiculo']}: ${r['motivo']}')
            .toList();
}

class Despacho {
  final int id, numeroPasajeros;
  final String ruta, placaVehiculo, estado, registradoPor, canceladoPor, motivoCancelacion;
  final String? hora, fecha, fechaRegistro, fechaCancelacion;

  Despacho.fromJson(Json j)
      : id = _i(j, 'id'),
        numeroPasajeros = _i(j, 'numeroPasajeros'),
        ruta = _s(j, 'ruta'),
        placaVehiculo = _s(j, 'placaVehiculo'),
        estado = _s(j, 'estado'),
        registradoPor = _s(j, 'registradoPor'),
        canceladoPor = _s(j, 'canceladoPor'),
        motivoCancelacion = _s(j, 'motivoCancelacion'),
        hora = _n(j, 'hora'),
        fecha = _n(j, 'fecha'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        fechaCancelacion = _n(j, 'fechaCancelacion');
}

class Sancion {
  final int id;
  final String identificacionConductor, nombresConductor, motivo, fechaInicio, fechaFin, estado;
  final String? fechaRegistro, ultimaActualizacion;

  Sancion.fromJson(Json j)
      : id = _i(j, 'id'),
        identificacionConductor = _s(j, 'identificacionConductor'),
        nombresConductor = _s(j, 'nombresConductor'),
        motivo = _s(j, 'motivo'),
        fechaInicio = _s(j, 'fechaInicio'),
        fechaFin = _s(j, 'fechaFin'),
        estado = _s(j, 'estado'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion');

  bool vigenteEn(String fechaIso) {
    return estado == 'ACTIVA' &&
        fechaInicio.compareTo(fechaIso) <= 0 &&
        (fechaFin.length >= 10 ? fechaFin.substring(0, 10) : fechaFin).compareTo(fechaIso) >= 0;
  }

  bool get programada => estado == 'ACTIVA' && fechaInicio.compareTo(DateTime.now().toIso8601String().substring(0, 10)) > 0;
}

class VehiculoAsociado {
  final String placa, identificacionConductor, tipo, marca, modelo;
  final String? fechaAfiliacion;
  final bool activo;

  VehiculoAsociado.fromJson(Json j)
      : placa = _s(j, 'placa'),
        identificacionConductor = _s(j, 'identificacionConductor'),
        tipo = _s(j, 'tipo'),
        marca = _s(j, 'marca'),
        modelo = _s(j, 'modelo'),
        fechaAfiliacion = _n(j, 'fechaAfiliacion'),
        activo = _b(j, 'activo');
}

class Empresa {
  final int id, versionSeguridad;
  final String razonSocial, nit;
  final bool activo;
  final String? fechaRegistro, ultimaActualizacion;

  Empresa.fromJson(Json j)
      : id = _i(j, 'id'),
        versionSeguridad = _i(j, 'versionSeguridad'),
        razonSocial = _s(j, 'razonSocial'),
        nit = _s(j, 'nit'),
        activo = _b(j, 'activo'),
        fechaRegistro = _n(j, 'fechaRegistro'),
        ultimaActualizacion = _n(j, 'ultimaFechaActualizacion');
}

class Credencial {
  final String username, password;
  final String? expiraEn;

  Credencial(this.username, this.password, this.expiraEn);

  factory Credencial.deAsociado(Json j) =>
      Credencial(_s(j, 'username'), _s(j, 'passwordTemporal'), _n(j, 'expiraEn'));

  factory Credencial.deEmpresa(Json j) => Credencial(
        j['gerente'] is Map ? _s(j['gerente'] as Json, 'username') : '',
        _s(j, 'passwordTemporal'),
        _n(j, 'expiraEn'),
      );
}

class Pago {
  final int id, numeroPlanilla;
  final double valorPagado;
  final String registradoPor;
  final String? fechaPago, fechaRegistro;

  Pago.fromJson(Json j)
      : id = _i(j, 'id'),
        numeroPlanilla = _i(j, 'numeroPlanilla'),
        valorPagado = _d(j, 'valorPagado'),
        registradoPor = _s(j, 'registradoPor'),
        fechaPago = _n(j, 'fechaPago'),
        fechaRegistro = _n(j, 'fechaRegistro');
}

class Mantenimiento {
  final int id;
  final String placaVehiculo, motivo, estadoVehiculoIngreso, observacionesIngreso, observaciones, estado, registradoPor, salidaRegistradaPor;
  final String? fechaIngreso, fechaSalida, fechaRegistro;

  Mantenimiento.fromJson(Json j)
      : id = _i(j, 'id'),
        placaVehiculo = _s(j, 'placaVehiculo'),
        motivo = _s(j, 'motivo'),
        estadoVehiculoIngreso = _s(j, 'estadoVehiculoIngreso'),
        observacionesIngreso = _s(j, 'observacionesIngreso'),
        observaciones = _s(j, 'observaciones'),
        estado = _s(j, 'estado'),
        registradoPor = _s(j, 'registradoPor'),
        salidaRegistradaPor = _s(j, 'salidaRegistradaPor'),
        fechaIngreso = _n(j, 'fechaIngreso'),
        fechaSalida = _n(j, 'fechaSalida'),
        fechaRegistro = _n(j, 'fechaRegistro');

  bool get abierto => estado == 'EN_MANTENIMIENTO';
}
