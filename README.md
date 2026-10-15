# SaveReel

Guarda videos cortos de TikTok e Instagram en tu teléfono a partir de su enlace, para verlos sin conexión.

App Flutter para Android e iOS. SaveReel no está afiliada a TikTok ni a Instagram.

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

## Recibir enlaces desde «Compartir»

SaveReel aparece en la hoja de Compartir de las demás apps (por ejemplo TikTok o Instagram). Al
elegirla, la app se abre con el enlace ya puesto, busca el video y muestra los formatos.

- **Android:** `MainActivity.kt` recibe el texto compartido (`ACTION_SEND`) y se lo pasa a
  Flutter por el canal `savetic/share`. Se prueba con
  `adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "https://vm.tiktok.com/ZMh7K2pQx/" -n com.michaeldevtool.savetic/.MainActivity`.
- **iPhone:** la extensión `ios/ShareExtension` recibe el enlace y abre `savetic://share?text=…`.
  No usa grupos de app, así que funciona con una cuenta de desarrollo gratuita. Para correr
  en un iPhone real hay que elegir tu equipo de desarrollo (Signing & Capabilities) tanto en
  `Runner` como en `ShareExtension`.
- En TikTok e Instagram, el menú propio de Compartir no siempre lista SaveReel: hay que
  tocar «Más» o «…» para abrir la hoja del sistema, donde sí aparece.

## Instagram

Los enlaces `instagram.com/reel/…`, `/p/…` y `/tv/…` se resuelven con la página pública de
inserción de Instagram, que no pide clave ni sesión. Es una fuente no oficial: puede dejar de
funcionar si Instagram la cambia. Como respaldo se puede apuntar a una instancia de
[Cobalt](https://github.com/imputnet/cobalt) con `--dart-define=COBALT_URL=https://…` (y
`--dart-define=COBALT_KEY=…` si pide clave). Solo funciona con contenido público.

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
