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

Todos los checks relevantes deben estar en verde. Si aparece algún error, sigue las instrucciones que imprime el comando.

### 2. Clonar o descargar el proyecto

```bash
git clone <url-del-repo>
cd tongoy_app
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Abrir en VS Code

```bash
code .
```

VS Code debería detectar el proyecto Flutter automáticamente y ofrecer instalar las extensiones recomendadas (aceptar todas).

### 5. Seleccionar dispositivo

En la barra inferior de VS Code, haz clic donde dice "No Device" y elige:
- Un emulador Android (requiere Android Studio)
- Un simulador iOS (requiere Xcode, solo macOS)
- Tu dispositivo físico conectado por USB

### 6. Ejecutar la app

Presiona **F5** o ve a Run → Start Debugging.

También puedes usar la terminal:

```bash
flutter run
```

---

## Estructura del proyecto

```
lib/
├── main.dart                          # Punto de entrada
├── core/
│   ├── constants/
│   │   └── api_constants.dart         # URLs y claves de la API
│   ├── errors/
│   │   ├── app_error.dart             # Errores tipados (sealed classes)
│   │   └── result.dart                # Result<T> = Success | Failure
│   ├── network/
│   │   └── dio_client.dart            # Cliente HTTP con cookies
│   └── router/
│       └── app_router.dart            # Navegación (go_router)
│
├── features/
│   ├── horario/                       # Vista de horario semanal
│   │   ├── domain/
│   │   │   ├── entities/              # HorarioItemEntity, MasterEntity, etc.
│   │   │   ├── repositories/          # IHorarioRepository (interfaz)
│   │   │   └── usecases/              # GetHorarioUseCase, GetMasterUseCase
│   │   ├── data/
│   │   │   ├── datasources/           # HorarioRemoteDataSource (Dio)
│   │   │   ├── models/                # DTOs que mapean el JSON
│   │   │   └── repositories/          # HorarioRepository (implementación)
│   │   └── presentation/
│   │       ├── providers/             # horarioProvider, horarioFiltroProvider
│   │       ├── screens/               # HorarioScreen
│   │       └── widgets/               # HorarioGrilla, FiltrosSheet, SearchBar
│   │
│   ├── auth/                          # Login / sesión
│   │   ├── domain/
│   │   │   ├── entities/              # UsuarioEntity
│   │   │   ├── repositories/          # IAuthRepository
│   │   │   └── usecases/              # LoginUseCase, LogoutUseCase
│   │   ├── data/
│   │   │   ├── datasources/           # AuthRemoteDataSource
│   │   │   └── repositories/          # AuthRepository (con SecureStorage)
│   │   └── presentation/
│   │       ├── providers/             # AuthNotifier, AuthState
│   │       └── screens/               # LoginScreen
│   │
│   ├── mis_cursos/                    # Cursos del usuario autenticado
│   │   ├── domain/entities/           # CursoUsuarioEntity
│   │   ├── data/                      # datasource + repositorio + provider
│   │   └── presentation/screens/      # MisCursosScreen
│   │
│   └── asistencia/                    # Lista de asistencia por curso
│       ├── data/                      # datasource + entidades + providers
│       └── presentation/screens/      # AsistenciaScreen
│
├── shared/
│   ├── theme/app_theme.dart           # Tema Material 3 (azul UCN)
│   └── widgets/main_scaffold.dart     # Bottom navigation bar
│
test/
└── unit/
    ├── horario_usecase_test.dart
    └── result_test.dart
```

---

## Arquitectura

El proyecto sigue **Clean Architecture** con tres capas:

```
Presentation  →  Domain  ←  Data
(Riverpod)       (puro)     (Dio + SharedPrefs)
```

- **Domain**: no depende de nada externo. Solo Dart puro. Aquí viven las entidades, interfaces de repositorios y casos de uso.
- **Data**: implementa los repositorios usando Dio para red y SharedPreferences / SecureStorage para local.
- **Presentation**: widgets Flutter + providers Riverpod que consumen los casos de uso.

### Flujo de una petición

```
HorarioScreen
  → ref.watch(horarioFiltradoProvider)
    → ref.watch(horarioProvider)
      → GetHorarioUseCase.call(filtro)
        → IHorarioRepository.getHorario(filtro)
          → HorarioRepository (implementación)
            → HorarioRemoteDataSource.fetchHorario(filtro)
              → Dio.get("/g.php", queryParams)
                → API Tongoy (losvilos.ucn.cl)
```

### Manejo de errores

Se usa `Result<T>` (tipo sellado) en lugar de excepciones para el flujo normal:

```dart
final result = await getHorario(filtro);
result.when(
  success: (items) => mostrarItems(items),
  failure: (error) => mostrarError(error.message),
);
```

---

## Dependencias principales

| Paquete | Uso |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navegación declarativa |
| `dio` | Cliente HTTP |
| `dio_cookie_manager` | Manejo automático de cookies de sesión |
| `flutter_secure_storage` | Guardar credenciales cifradas |
| `shared_preferences` | Caché del master de la API |

---

## Comandos útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar tests
flutter test

# Analizar el código
flutter analyze

# Formatear código
dart format lib/ test/

# Compilar APK de debug
flutter build apk --debug

# Compilar APK de release
flutter build apk --release

# Compilar para iOS (solo macOS)
flutter build ios --release
```

---

## Cómo agregar una nueva funcionalidad

Sigue el patrón ya establecido:

1. **Crear la entidad** en `features/<nombre>/domain/entities/`
2. **Definir la interfaz** del repositorio en `features/<nombre>/domain/repositories/`
3. **Escribir el caso de uso** en `features/<nombre>/domain/usecases/`
4. **Implementar el data source** en `features/<nombre>/data/datasources/`
5. **Implementar el repositorio** en `features/<nombre>/data/repositories/`
6. **Crear el provider** en `features/<nombre>/presentation/providers/`
7. **Construir la pantalla** en `features/<nombre>/presentation/screens/`
8. **Escribir tests** en `test/unit/`

---

## API de Tongoy — referencia rápida

Base URL: `https://losvilos.ucn.cl/tongoy`

| Endpoint | Método | Auth | Descripción |
|---|---|---|---|
| `/master.php` | GET | No | Áreas, bloques, salas, semestres... |
| `/g.php` | GET | No | Horario con filtros |
| `/a.php?op=auth` | POST | No | Login (devuelve cookie) |
| `/mi.php` | GET | Cookie | Usuario actual |
| `/cp.php` | GET | Cookie | Cursos del usuario |
| `/asist_marcar6.php` | GET | Cookie | Lista de asistencia |
| `/asist_marcar6.php?op=s` | POST | Cookie | Guardar asistencia |
| `/ge.php` | POST | No | Validar RUT estudiante |

Para cambiar la URL base, edita `lib/core/constants/api_constants.dart`.

---

## Notas de seguridad

- La cookie de sesión (PHPSESSID) es gestionada automáticamente por `dio_cookie_manager`.
- El usuario/RUT se guarda con `flutter_secure_storage` (cifrado en el llavero del sistema operativo).
- Nunca se guardan contraseñas en disco.
- En Android, `usesCleartextTraffic="false"` fuerza HTTPS.

---

## Versión

`1.0.0` — compatible con la API Tongoy v0.9.8
