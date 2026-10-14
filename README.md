# SaveTic

Guarda videos cortos en tu teléfono a partir de su enlace, para verlos sin conexión.

App Flutter para Android e iOS. SaveTic no está afiliada a TikTok.

## Cómo correrla

```bash
flutter pub get
flutter run
```

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
