# Cómo contribuir

¡Gracias por querer ayudar! Este proyecto prefiere cambios pequeños y claros.

## Antes de empezar

1. Busca en los issues si ya existe lo que quieres hacer. Si no, abre uno.
2. Haz fork del repositorio y crea una rama con prefijo según el tipo de trabajo:
   `feat/`, `fix/`, `chore/`, `docs/`, `test/` o `refactor/`.

## Flujo

- Un PR por rama y un cambio útil por PR.
- Commits atómicos y en español, con el cambio descrito en una frase, por ejemplo
  `Trata una duración de 0 como desconocida para leerla del archivo`.
- No hagas commits directos en `main`. Los PR se fusionan con **Merge pull request**
  para conservar el historial de commits.

## Antes de abrir el PR

```bash
flutter analyze
flutter test
```

El CI ejecuta lo mismo y debe quedar en verde. Usa Flutter 3.47.5 (ver `.fvmrc`).

## Diseño

Los colores, tamaños y movimientos salen de los tokens de `lib/src/config/theme`. No uses
colores ni medidas sueltas en los widgets. Si tu cambio toca lo visual, adjunta una captura
en el PR (claro y oscuro).

## Qué no se acepta

- Claves, tokens ni archivos de entorno (`env.json`).
- Código que descargue contenido privado o que esquive protecciones de las redes.

## Código de conducta

Sé respetuoso. Las críticas van al código, no a las personas.
