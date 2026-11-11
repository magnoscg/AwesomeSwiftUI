# Zonas de toque de 44 puntos
Estado: cerrada · Rama: feature/touch-targets · Abierta: 2026-11-11

## Objetivo
Que ningún control del catálogo sea difícil de acertar con el dedo. La auditoría de pulido
encontró 33 componentes con botones de menos de 44 puntos, el tamaño que recomienda Apple.

## Specs
- S1. Cada control listado responde a un toque en un área de al menos 44 puntos de alto y de
  ancho alrededor de su dibujo, salvo los de S3.
- S2. El diseño no cambia donde ampliar el tamaño lo rompería (una línea de texto, una leyenda,
  un icono dentro de un campo): ahí solo crece la zona que responde al toque, con
  `.padding(n).contentShape(.rect).padding(-n)` en la etiqueta del botón.
- S3. Un botón con estilo del sistema (`.bordered`, `.borderedProminent`, `.glass`) a su tamaño
  normal, 34 puntos, no se toca: es el tamaño de Apple. Un icono suelto en un círculo de esos
  estilos, que queda en 28, pasa a `.controlSize(.large)`.
- S4. La regla 7 de `AGENTS.md` lo pide para componentes nuevos.

## Tareas
- [x] T1 (S1, S2) Texto y filas: `AnimatedDonutChart`, `AnimatedRadioButton`, `BreadcrumbTrail`,
  `CoachMarkTour`, `NestedCommentThread`, `ReadMoreText`, `ShutterCaptureButton`,
  `TrialTimelinePaywall`, `ScrollingTabStrip`, `ScrollSpyHeader`, `GlassTagCloud`
- [x] T2 (S1, S2) Iconos: `GlassTabAccessory`, `MapSearchSheet`, `MatchedHeroCard`,
  `PasswordStrengthField`, `RatingStars`, `RichTextEditor`, `TagInputField`, `VideoPosterToPlayer`
- [x] T3 (S1, S2) Solo el demo: `DoubleTapHeartOverlay`, `DragSelectGrid`, `FullScreenMenuOverlay`,
  `JiggleEditModifier`, `SideDrawer`, `TooltipPopover`
- [x] T4 (S3) `MapRouteTracker` y `ScrollEdgeHeader` a `.controlSize(.large)`
- [x] T5 (S4) Regla 7 de `AGENTS.md`, CHANGELOG y cinco previews regrabadas y revisadas

## Verificación
`make verify`. A mano: `au.sh <udid> open <id>` lista el tamaño de cada control; y
`touch-test.sh` toca justo fuera del dibujo y mira si la pantalla cambia, con un toque a 45
puntos como control.

## Log
- L1. «venga vamos a continuar con lo que estabamos», tras el informe de la auditoría, cuyo
  siguiente punto era: «Las zonas de toque, en un solo cambio con su test».
- L2. 2026-11-11. De los 37 hallazgos de «tacto», cuatro no son de tamaño (`GlassSegmentedControl`,
  `HideOnScrollBar`, `NetflixRowsScroller`, `ShimmerButton`) y `EmbeddedWebBrowser` ya estaba hecho.
- L3. 2026-11-11. No se tocan por S3: `CoachMarkTour` (Next), `CropRectangleOverlay`,
  `PhotoAdjustmentSliders`, `PhotoMultiSelectGrid`, `ZoomHeroTransition` y `GlassButtonGallery`,
  que es una galería de los controles del sistema en sus tamaños.
- L4. 2026-11-11. Medido en iOS 27.2 tras el cambio: 44 puntos o más en `AnimatedDonutChart`,
  `AnimatedRadioButton`, `NestedCommentThread`, `MapRouteTracker`, `RatingStars`, `TagInputField`,
  `FullScreenMenuOverlay`, `GlassTagCloud`, `RichTextEditor`, `ScrollEdgeHeader`, `SideDrawer`,
  `ScrollSpyHeader`, `ScrollingTabStrip`, `PasswordStrengthField` y `GlassTabAccessory`.
- L5. 2026-11-11. Con el estilo de botón por defecto, el tamaño que da la accesibilidad no crece
  aunque la zona sí. Comprobado con toques: a 6 y 11 puntos del borde responden `BreadcrumbTrail`,
  `TrialTimelinePaywall`, `ShutterCaptureButton`, `TooltipPopover` y `CoachMarkTour`, y a 45 no;
  `ReadMoreText` a 15 sí y a 30 no; y por estado, `JiggleEditModifier` y `DoubleTapHeartOverlay`.
  No se pudo comparar con la versión anterior en el simulador.
- L6. 2026-11-11. Sin probar con un toque: `DragSelectGrid` (el botón está desactivado sin
  selección), `MapSearchSheet`, `MatchedHeroCard` y `VideoPosterToPlayer`.
- L7. 2026-11-11. `make verify` en Xcode 27.2 y la suite en iOS 18.5 con `axbuild`: sin errores.
