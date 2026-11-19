# COOTRASCHIPILIN · App móvil (SITRAM)

Implementación en Flutter del prototipo de Figma (pantallas S01 a S38), conectada a la API SITRAM.
Todas las peticiones pasan por la clase `ApiService` (lib/services/api_service.dart).

## Cómo correrla
    flutter pub get
    flutter run

URL de la API por defecto: https://api.sitram.cecar.cloud
Para otra URL: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`

Android: en android/app/src/main/AndroidManifest.xml debe estar
`<uses-permission android:name="android.permission.INTERNET"/>` (arriba de <application>).

## Estructura
- lib/main.dart → rutas /s01 ... /s38 (algunas reciben argumentos)
- lib/config.dart → URL de la API
- lib/services/api_service.dart → ApiService del profesor (sin cambios)
- lib/services/sesion.dart → token JWT, rol y datos del usuario; 401 abre S38
- lib/services/sitram_service.dart → todos los endpoints de la API
- lib/models/modelos.dart → respuestas (fromJson)
- lib/models/requests.dart → lo que se envía (toJson)
- lib/widgets/comunes.dart → componentes (botón, chip, campo, fila, alerta, barras, estados)
- lib/pantallas/ → entrada, personas, operacion, planillas, admin, cuenta, taller_pagos

## Inicio de sesión
- POST /api/auth/login. Si responde requiereCambioPassword = true, pasa a S03
  (POST /api/auth/cambiar-password, mínimo 12 caracteres con mayúscula, minúscula y número).
- GERENTE / ASISTENTE ven Inicio, Personas, Operación, Admin y Mi cuenta.
- ASOCIADO ve Mis vehículos, Viajes, Despachos y Mi cuenta.
- Empresas solo aparece para ADMIN.

## Regla del conductor sancionado
- S08 y S10: chip rojo y alerta "No disponible para trabajar".
- S15: los conductores sancionados salen deshabilitados al asignar conductor.
- S24: si el conductor del vehículo tiene sanción ACTIVA en la fecha, Guardar queda deshabilitado.
- S25: los vehículos con conductor sancionado no se pueden marcar.
- Además la API responde 400 si se intenta igual, y la app muestra el motivo.

## Pagos y mantenimientos (S39 a S43)
Están en la API aunque no estaban en el prototipo. Se agregaron como pestañas de Operación.
- Pagos: listado con filtros (planilla, placa, fechas) y detalle. El pago se registra desde el detalle de la planilla;
  el valor lo pone la API con el total de la tarifa.
- Mantenimiento: ingreso al taller, listado, detalle y registro de salida.
  Un vehículo EN_MANTENIMIENTO no puede recibir planillas (S24, S25) ni despachos (S28).

## Sesión
El token se guarda cifrado en el celular (flutter_secure_storage). Al abrir la app, S01 revisa si hay una
sesión vigente y entra directo. Cerrar sesión la borra.
