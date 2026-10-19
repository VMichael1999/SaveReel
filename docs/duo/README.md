# SaveReel en el iPhone Duo

`savereel-duo.html` es la referencia de diseño: cada pantalla tiene un `data-screen`
(`duo-01-inicio` … `duo-12-vertical`). El diseño se elige solo por el tamaño de la pantalla
en puntos (`lib/src/core/layout/duo_layout.dart`), nunca por el modelo ni la orientación.

| Diseño | Condición | Qué hace |
| --- | --- | --- |
| `normal` | Todo lo demás | Lo de siempre, sin cambios |
| `closed` | Ancho 420–520 y alto/ancho 1,3–1,6 (≈ 466 × 678 pt) | Franja lateral a la derecha |
| `openLandscape` | Ancho ≥ 840, ancho > alto y alto/ancho ≤ 1,6 (≈ 951 × 669 pt) | Franja y dos mitades |
| `openPortrait` | Ancho ≥ 600, alto > ancho y alto/ancho ≤ 1,6 (≈ 669 × 951 pt) | Barras arriba como hoy |

El límite de proporción no está en el prompt original: sin él, un iPhone normal en horizontal
(852 × 393) caía en `openLandscape`.

## Lo que se midió en el simulador

- En el Duo cerrado el sistema reserva **84 pt a la derecha** (`padding.right`); `padding.top`
  llega en 0 y la isla, la hora y la señal ocupan unos 150 pt de alto sin contarse en él. La
  franja usa `padding.right` como ancho y reserva 160 pt arriba (`DuoSideBar.systemTopHeight`).
- `MediaQuery.displayFeatures` llega vacío en iOS: no se puede saber si está medio doblado.

## Pantallas

| ID | Estado |
| --- | --- |
| `duo-01-inicio`, `duo-03-biblioteca`, `duo-04-reproductor` | Hecho (`closed`) |
| `duo-02-vista-previa` | Hecho: la misma hoja con la miniatura de 96 pt |
| `duo-05-inicio-y-vista-previa`, `duo-06-descargando` | Hecho: la derecha muestra la vista previa o las descargas |
| `duo-07-biblioteca` | Hecho: 6 columnas con el hueco entre la 3.ª y la 4.ª en el centro |
| `duo-08-biblioteca-y-reproductor` | Hecho: la ruta del reproductor se adapta y no recrea el controlador |
| `duo-09-ajustes` | Hecho: lista a la izquierda y las opciones de la fila elegida a la derecha |
| `duo-11-split-view` | Mismo diseño que `duo-01`, con la franja en el borde derecho; falta saber en qué mitad está la ventana |
| `duo-12-vertical` | Hecho: recientes de a 4 y biblioteca de 4 columnas |
| `duo-10-medio-doblado` | No se construye: hace falta un canal nativo |

Los goldens de las pantallas de siempre están en `test/golden/goldens/`; los del Duo, en
`test/features/goldens/duo/`. Usan la fuente de prueba de Flutter, así que no se parecen
letra por letra al HTML.
