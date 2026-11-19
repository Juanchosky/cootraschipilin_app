import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import '../models/modelos.dart';
import '../rutas.dart';
import 'api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

ApiService api = prepararApi();

ApiService prepararApi([String? token]) {
  return ApiService(
    baseUrl: urlApi,
    defaultHeaders: token == null ? null : {'Authorization': 'Bearer $token'},
    onUnauthorized: Sesion.vencida,
  );
}

class Sesion {
  static const _almacen = FlutterSecureStorage();
  static const _llave = 'sesion_sitram';

  static String? token;
  static String? tokenCambio;
  static String rol = '';
  static String username = '';
  static String identificacion = '';
  static String empresa = '';
  static String nit = '';
  static DateTime? inicio;
  static DateTime? expira;
  static bool _avisado = false;

  static bool get esAsociado => rol == 'ASOCIADO';
  static bool get esGerente => rol == 'GERENTE' || rol == 'ADMIN';
  static bool get esAdmin => rol == 'ADMIN';

  static String get rutaInicio => esAsociado ? Rutas.misVehiculos : Rutas.inicio;

  static void iniciar(LoginRespuesta r) {
    token = r.token;
    tokenCambio = null;
    rol = r.rol;
    username = r.username;
    identificacion = r.identificacion;
    empresa = r.empresa;
    nit = r.nit;
    inicio = DateTime.now();
    expira = _calcularExpira(r.expiraEn);
    _avisado = false;
    api = prepararApi(token);
    _guardar();
  }

  static Future<void> _guardar() async {
    try {
      await _almacen.write(
        key: _llave,
        value: jsonEncode({
          'token': token,
          'rol': rol,
          'username': username,
          'identificacion': identificacion,
          'empresa': empresa,
          'nit': nit,
          'inicio': inicio?.toIso8601String(),
          'expira': expira?.toIso8601String(),
        }),
      );
    } catch (_) {
    }
  }

  static Future<bool> cargar() async {
    try {
      final texto = await _almacen.read(key: _llave);
      if (texto == null) return false;
      final j = jsonDecode(texto) as Map<String, dynamic>;
      final vence = DateTime.tryParse('${j['expira']}');
      if (j['token'] == null || (vence != null && vence.isBefore(DateTime.now()))) {
        await _almacen.delete(key: _llave);
        return false;
      }
      token = '${j['token']}';
      rol = '${j['rol'] ?? ''}';
      username = '${j['username'] ?? ''}';
      identificacion = '${j['identificacion'] ?? ''}';
      empresa = '${j['empresa'] ?? ''}';
      nit = '${j['nit'] ?? ''}';
      inicio = DateTime.tryParse('${j['inicio']}');
      expira = vence;
      _avisado = false;
      api = prepararApi(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  static DateTime? _calcularExpira(int v) {
    if (v <= 0) return null;
    if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v > 1000000000) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    return DateTime.now().add(Duration(seconds: v));
  }

  static void cerrar() {
    token = null;
    tokenCambio = null;
    rol = '';
    username = '';
    identificacion = '';
    empresa = '';
    nit = '';
    inicio = null;
    expira = null;
    api = prepararApi();
    _almacen.delete(key: _llave).catchError((_) {});
  }

  static void vencida() {
    if (token == null || _avisado) return;
    _avisado = true;
    cerrar();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(Rutas.sesionExpirada, (r) => false);
  }
}
