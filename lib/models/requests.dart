
Map<String, dynamic> _limpio(Map<String, dynamic> m) {
  m.removeWhere((k, v) => v == null);
  return m;
}

class LoginRequest {
  final String username, password;
  LoginRequest(this.username, this.password);
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class CambiarPasswordRequest {
  final String nuevaPassword, confirmacionPassword;
  CambiarPasswordRequest(this.nuevaPassword, this.confirmacionPassword);
  Map<String, dynamic> toJson() => {
        'nuevaPassword': nuevaPassword,
        'confirmacionPassword': confirmacionPassword,
      };
}

class AsociadoRequest {
  final String? identificacion;
  final String nombres;
  final bool activo;
  final String? celular, correo, fechaNacimiento, fechaIngreso;
  AsociadoRequest({this.identificacion, required this.nombres, required this.activo, this.celular, this.correo, this.fechaNacimiento, this.fechaIngreso});
  Map<String, dynamic> toJson() => _limpio({
        'identificacion': identificacion,
        'nombres': nombres,
        'activo': activo,
        'celular': celular,
        'correo': correo,
        'fechaNacimiento': fechaNacimiento,
        'fechaIngreso': fechaIngreso,
      });
}

class ConductorRequest {
  final String? identificacion;
  final String nombres, numeroLicencia, categoriaLicencia, vigenciaLicencia;
  final bool activo;
  final String? fechaNacimiento, celular, correo;
  ConductorRequest({this.identificacion, required this.nombres, required this.numeroLicencia, required this.categoriaLicencia, required this.vigenciaLicencia, required this.activo, this.fechaNacimiento, this.celular, this.correo});
  Map<String, dynamic> toJson() => _limpio({
        'identificacion': identificacion,
        'nombres': nombres,
        'fechaNacimiento': fechaNacimiento,
        'activo': activo,
        'numeroLicencia': numeroLicencia,
        'categoriaLicencia': categoriaLicencia,
        'vigenciaLicencia': vigenciaLicencia,
        'celular': celular,
        'correo': correo,
      });
}

class VehiculoRequest {
  final String placa, tipo, marca, modelo, tarjetaPropiedad, vigenciaSoat, vigenciaTrm;
  final int capacidadPasajeros, tarifaId;
  final bool activo;
  final String? fechaIngreso;
  VehiculoRequest({required this.placa, required this.tipo, required this.marca, required this.modelo, required this.tarjetaPropiedad, required this.vigenciaSoat, required this.vigenciaTrm, required this.capacidadPasajeros, required this.tarifaId, required this.activo, this.fechaIngreso});
  Map<String, dynamic> toJson() => _limpio({
        'placa': placa,
        'tipo': tipo,
        'marca': marca,
        'modelo': modelo,
        'capacidadPasajeros': capacidadPasajeros,
        'tarjetaPropiedad': tarjetaPropiedad,
        'tarifaId': tarifaId,
        'activo': activo,
        'vigenciaSoat': vigenciaSoat,
        'vigenciaTrm': vigenciaTrm,
        'fechaIngreso': fechaIngreso,
      });
}

class ActualizarVehiculoRequest {
  final String? identificacionConductor, vigenciaSoat, vigenciaTrm, fechaIngreso;
  final bool activo;
  final int? tarifaId;
  ActualizarVehiculoRequest({this.identificacionConductor, required this.activo, this.vigenciaSoat, this.vigenciaTrm, this.fechaIngreso, this.tarifaId});
  Map<String, dynamic> toJson() => _limpio({
        'identificacionConductor': identificacionConductor,
        'activo': activo,
        'vigenciaSoat': vigenciaSoat,
        'vigenciaTrm': vigenciaTrm,
        'fechaIngreso': fechaIngreso,
        'tarifaId': tarifaId,
      });
}

class AfiliacionRequest {
  final String identificacionAsociado, placaVehiculo, fechaAfiliacion, estado;
  final String? fechaFinAfiliacion;
  AfiliacionRequest({required this.identificacionAsociado, required this.placaVehiculo, required this.fechaAfiliacion, required this.estado, this.fechaFinAfiliacion});
  Map<String, dynamic> toJson() => {
        'identificacionAsociado': identificacionAsociado,
        'placaVehiculo': placaVehiculo,
        'fechaAfiliacion': fechaAfiliacion,
        'fechaFinAfiliacion': fechaFinAfiliacion,
        'estado': estado,
      };
}

class TarifaRequest {
  final double aportesGastosVarios, fondoReposicion, aporteSocialSocio;
  final bool activo;
  TarifaRequest(this.aportesGastosVarios, this.fondoReposicion, this.aporteSocialSocio, this.activo);
  Map<String, dynamic> toJson() => {
        'aportesGastosVarios': aportesGastosVarios,
        'fondoReposicion': fondoReposicion,
        'aporteSocialSocio': aporteSocialSocio,
        'activo': activo,
      };
}

class PlanillaRequest {
  final String fecha, placaVehiculo, tipo, estado;
  final int? tarifaId;
  PlanillaRequest({required this.fecha, required this.placaVehiculo, required this.tipo, this.estado = 'ACTIVA', this.tarifaId});
  Map<String, dynamic> toJson() => _limpio({
        'fecha': fecha,
        'placaVehiculo': placaVehiculo,
        'tipo': tipo,
        'estado': estado,
        'tarifaId': tarifaId,
      });
}

class PlanillaMasivaRequest {
  final String fecha, tipo;
  final List<String> placasVehiculos;
  final int? tarifaId;
  PlanillaMasivaRequest({required this.fecha, required this.tipo, required this.placasVehiculos, this.tarifaId});
  Map<String, dynamic> toJson() => _limpio({
        'fecha': fecha,
        'placasVehiculos': placasVehiculos,
        'tipo': tipo,
        'tarifaId': tarifaId,
      });
}

class DespachoRequest {
  final String ruta, placaVehiculo, hora, fecha;
  final int numeroPasajeros;
  DespachoRequest({required this.ruta, required this.placaVehiculo, required this.hora, required this.fecha, required this.numeroPasajeros});
  Map<String, dynamic> toJson() => {
        'ruta': ruta,
        'placaVehiculo': placaVehiculo,
        'hora': hora,
        'fecha': fecha,
        'numeroPasajeros': numeroPasajeros,
      };
}

class SancionRequest {
  final String identificacionConductor, motivo, fechaInicio, fechaFin;
  SancionRequest({required this.identificacionConductor, required this.motivo, required this.fechaInicio, required this.fechaFin});
  Map<String, dynamic> toJson() => {
        'identificacionConductor': identificacionConductor,
        'motivo': motivo,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
      };
}

class ActualizarSancionRequest {
  final String estado;
  final String? motivo;
  ActualizarSancionRequest({required this.estado, this.motivo});
  Map<String, dynamic> toJson() => _limpio({'estado': estado, 'motivo': motivo});
}

class UsuarioRequest {
  final String identificacion, nombres, username, password, rol;
  final bool activo;
  UsuarioRequest({required this.identificacion, required this.nombres, required this.username, required this.password, required this.rol, required this.activo});
  Map<String, dynamic> toJson() => {
        'identificacion': identificacion,
        'nombres': nombres,
        'username': username,
        'password': password,
        'rol': rol,
        'activo': activo,
      };
}

class EmpresaRequest {
  final String razonSocial, nit, gerenteIdentificacion, gerenteNombres, gerenteUsername;
  EmpresaRequest({required this.razonSocial, required this.nit, required this.gerenteIdentificacion, required this.gerenteNombres, required this.gerenteUsername});
  Map<String, dynamic> toJson() => {
        'razonSocial': razonSocial,
        'nit': nit,
        'primerGerente': {
          'identificacion': gerenteIdentificacion,
          'nombres': gerenteNombres,
          'username': gerenteUsername,
        },
      };
}

class RegistrarPagoRequest {
  final int numeroPlanilla;
  final String fechaPago;
  RegistrarPagoRequest(this.numeroPlanilla, this.fechaPago);
  Map<String, dynamic> toJson() => {'numeroPlanilla': numeroPlanilla, 'fechaPago': fechaPago};
}

class MantenimientoRequest {
  final String placaVehiculo, fechaIngreso, motivo, estadoVehiculoIngreso;
  final String? observaciones;
  MantenimientoRequest({required this.placaVehiculo, required this.fechaIngreso, required this.motivo, required this.estadoVehiculoIngreso, this.observaciones});
  Map<String, dynamic> toJson() => _limpio({
        'placaVehiculo': placaVehiculo,
        'fechaIngreso': fechaIngreso,
        'motivo': motivo,
        'estadoVehiculoIngreso': estadoVehiculoIngreso,
        'observaciones': observaciones,
      });
}

class SalidaMantenimientoRequest {
  final String fechaSalida;
  final String? observaciones;
  SalidaMantenimientoRequest(this.fechaSalida, this.observaciones);
  Map<String, dynamic> toJson() => _limpio({'fechaSalida': fechaSalida, 'observaciones': observaciones});
}
