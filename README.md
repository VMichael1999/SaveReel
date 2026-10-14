# SaveTic

Guarda videos cortos en tu teléfono a partir de su enlace, para verlos sin conexión.

App Flutter para Android e iOS. SaveTic no está afiliada a TikTok.

## Cómo correrla

Usa **Flutter 3.47.5** (ver `.fvmrc`). Con [fvm](https://fvm.app):

```bash
fvm use 3.47.5
fvm flutter pub get
fvm flutter run
```

Las versiones anteriores de Flutter no compilan para iOS con Xcode 26 o 27: su
herramienta llama a `lipo -verify_arch` con una sintaxis que ese Xcode ya no acepta.

Por omisión consulta el servicio público de [tikwm.com](https://www.tikwm.com), que no pide clave.

## Servicio de descargas

La URL del servicio se cambia al compilar, sin tocar el código:

| Opción | Para qué |
|---|---|
| `--dart-define=API_BASE_URL=https://mi-backend.com` | Usar un backend propio o un servidor de prueba. |
| `--dart-define=API_ENDPOINT=/analysis` | Ruta del servicio (por omisión `/api/`). |
| `--dart-define-from-file=env.json` | Pasar `RAPIDAPI_KEY` si usas un servicio de RapidAPI (copia `env.example.json`; `env.json` no se sube a git). |

Las cabeceras de RapidAPI solo se envían cuando hay `RAPIDAPI_KEY`. Los archivos de video se bajan con un cliente aparte que nunca recibe ninguna clave.

**Antes de publicar en las tiendas** conviene un backend propio: el servicio público de terceros no tiene garantías y puede cambiar o limitar el acceso.

## Pruebas

```bash
flutter analyze
flutter test
```
