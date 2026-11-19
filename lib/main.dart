import 'package:flutter/material.dart';
import 'models/modelos.dart';
import 'pantallas/admin.dart';
import 'pantallas/cuenta.dart';
import 'pantallas/entrada.dart';
import 'pantallas/operacion.dart';
import 'pantallas/personas.dart';
import 'pantallas/planillas.dart';
import 'pantallas/taller_pagos.dart';
import 'rutas.dart';
import 'services/sesion.dart';
import 'tema.dart';
import 'widgets/comunes.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  Route<dynamic> rutas(RouteSettings s) {
    final a = s.arguments;
    Widget pantalla;
    switch (s.name) {
      case Rutas.login:
        pantalla = const S02Login();
      case Rutas.cambiarClave:
        pantalla = const S03CambiarClave();
      case Rutas.inicio:
        pantalla = const S04Inicio();

      case Rutas.asociados:
        pantalla = const S05Asociados();
      case Rutas.nuevoAsociado:
        pantalla = S06FormAsociado(asociado: a as Asociado?);
      case Rutas.detalleAsociado:
        pantalla = S07DetalleAsociado(id: a as String);
      case Rutas.conductores:
        pantalla = const S08Conductores();
      case Rutas.nuevoConductor:
        pantalla = S09FormConductor(conductor: a as Conductor?);
      case Rutas.detalleConductor:
        pantalla = S10DetalleConductor(id: a as String);
      case Rutas.sanciones:
        pantalla = S11Sanciones(conductor: a as String?);
      case Rutas.registrarSancion:
        pantalla = S12RegistrarSancion(conductor: a as String?);
      case Rutas.detalleSancion:
        pantalla = S13DetalleSancion(id: a as int);

      case Rutas.vehiculos:
        pantalla = const S14Vehiculos();
      case Rutas.nuevoVehiculo:
        pantalla = S15FormVehiculo(vehiculo: a as Vehiculo?);
      case Rutas.detalleVehiculo:
        pantalla = S16DetalleVehiculo(placa: a as String);
      case Rutas.afiliaciones:
        pantalla = const S17Afiliaciones();
      case Rutas.nuevaAfiliacion:
        pantalla = S18FormAfiliacion(afiliacion: a as Afiliacion?);
      case Rutas.detalleAfiliacion:
        pantalla = S19DetalleAfiliacion(id: a as int);

      case Rutas.tarifas:
        pantalla = const S20Tarifas();
      case Rutas.registrarTarifa:
        pantalla = const S21RegistrarTarifa();
      case Rutas.detalleTarifa:
        pantalla = S22DetalleTarifa(id: a as int);

      case Rutas.planillas:
        pantalla = const S23Planillas();
      case Rutas.nuevaPlanilla:
        pantalla = const S24NuevaPlanilla();
      case Rutas.generacionMasiva:
        pantalla = const S25GeneracionMasiva();
      case Rutas.detallePlanilla:
        pantalla = S26DetallePlanilla(numero: a as int);
      case Rutas.despachos:
        pantalla = const S27Despachos();
      case Rutas.registrarDespacho:
        pantalla = const S28RegistrarDespacho();
      case Rutas.detalleDespacho:
        pantalla = S29DetalleDespacho(id: a as int);

      case Rutas.empresas:
        pantalla = const S30Empresas();
      case Rutas.registrarEmpresa:
        pantalla = const S31RegistrarEmpresa();
      case Rutas.detalleEmpresa:
        pantalla = S32DetalleEmpresa(id: a as int);
      case Rutas.usuarios:
        pantalla = const S33RegistrarUsuario();

      case Rutas.misVehiculos:
        pantalla = const S34MisVehiculos();
      case Rutas.misViajes:
        pantalla = const S35MisViajes();
      case Rutas.misDespachos:
        pantalla = const S36MisDespachos();
      case Rutas.miCuenta:
        pantalla = const S37MiCuenta();
      case Rutas.sesionExpirada:
        pantalla = const S38SesionExpirada();

      case Rutas.pagos:
        pantalla = const S39Pagos();
      case Rutas.detallePago:
        pantalla = S40DetallePago(id: a as int);
      case Rutas.mantenimientos:
        pantalla = const S41Mantenimientos();
      case Rutas.ingresoTaller:
        pantalla = S42IngresoTaller(placa: a as String?);
      case Rutas.detalleMantenimiento:
        pantalla = S43DetalleMantenimiento(id: a as int);

      default:
        pantalla = const S01Carga();
    }
    return MaterialPageRoute(builder: (_) => pantalla, settings: s);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COOTRASCHIPILIN',
      debugShowCheckedModeBanner: false,
      theme: temaApp(),
      navigatorKey: navigatorKey,
      initialRoute: Rutas.carga,
      onGenerateRoute: rutas,
    );
  }
}
