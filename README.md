# Tongoy UCN — App Móvil

App móvil para el sistema académico Tongoy de la Universidad Católica del Norte (Sede Coquimbo), construida con Flutter.

---

## Requisitos previos

| Herramienta | Versión mínima | Instalación |
|---|---|---|
| Flutter SDK | 3.19+ | https://flutter.dev/docs/get-started/install |
| Dart SDK | 3.2+ | Incluido con Flutter |
| VS Code | cualquiera | https://code.visualstudio.com |
| Extensión Flutter | última | Buscar "Flutter" en VS Code |
| Android Studio / Xcode | según plataforma | Para emuladores |

---

## Instalación paso a paso

### 1. Verificar Flutter instalado

```bash
flutter doctor
```

### 2. Clonar el proyecto

```bash
git clone <url-del-repo>
cd tongoy_app
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la app

```bash
flutter run
```

---

## API de Tongoy

> **Ambiente de desarrollo:** `https://losvilos.ucn.cl/hawaii`  
> **Ambiente de producción:** `https://losvilos.ucn.cl/tongoy`

Para cambiar el ambiente, edita `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'https://losvilos.ucn.cl/hawaii'; // dev
// static const String baseUrl = 'https://losvilos.ucn.cl/tongoy'; // prod
```

| Endpoint | Método | Auth | Descripción |
|---|---|---|---|
| `/master.php` | GET | No | Áreas, bloques, salas, semestres |
| `/g.php` | GET | No | Horario con filtros |
| `/a.php?op=auth` | POST | No | Login (devuelve cookie) |
| `/mi.php` | GET | Cookie | Usuario actual |
| `/cp.php` | GET | Cookie | Cursos del usuario |
| `/asist_marcar6.php` | GET | Cookie | Lista de asistencia |
| `/asist_marcar6.php?op=s` | POST | Cookie | Guardar asistencia |
| `/ge.php` | POST | No | Validar RUT estudiante |

---

## Build de release para Android

### 1. Generar el keystore

```bash
keytool -genkeypair -v \
  -keystore android/keystore/tongoy-release.jks \
  -alias tongoy \
  -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Crear `android/keystore.properties`

```properties
storeFile=../keystore/tongoy-release.jks
storePassword=TU_STORE_PASSWORD
keyAlias=tongoy
keyPassword=TU_KEY_PASSWORD
```

> ⚠ `keystore.properties` y el archivo `.jks` están en `.gitignore`.  
> **Nunca los subas al repositorio.**

### 3. Compilar APK de release

```bash
flutter build apk --release
```

---

## Comandos útiles

```bash
flutter pub get        # Instalar dependencias
flutter test           # Ejecutar tests
flutter analyze        # Analizar el código
dart format lib/ test/ # Formatear código
flutter build apk --debug    # APK de debug
flutter build apk --release  # APK de release (requiere keystore)
```

---

## Estructura del proyecto

```
lib/
├── main.dart
├── core/
│   ├── constants/api_constants.dart
│   ├── errors/
│   ├── network/dio_client.dart
│   └── router/app_router.dart
└── features/
    ├── auth/
    ├── horario/
    ├── mis_cursos/
    └── asistencia/
```

---

## Notas de seguridad

- La cookie de sesión (PHPSESSID) es gestionada por `dio_cookie_manager`.
- Las credenciales se guardan con `flutter_secure_storage` (cifrado nativo).
- El escáner QR valida dominio **y** ruta del endpoint — solo acepta URLs de asistencia conocidas.
- No se registran datos personales en logs en builds de producción.
- En Android, `usesCleartextTraffic="false"` fuerza HTTPS.