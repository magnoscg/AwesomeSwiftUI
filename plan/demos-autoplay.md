# Demos que se paran al primer toque
Estado: cerrada · Rama: feature/demos-stop-autoplay · Abierta: 2026-11-11

## Objetivo
Un demo puede animarse solo para que se vea vivo y para grabar su preview, pero deja de hacerlo
en cuanto alguien lo toca. Hoy catorce demos siguen moviéndose y pisan lo que hace la persona.

## Specs
- S1. En los catorce demos, tras el primer toque (pulsar, arrastrar o hacer scroll) el demo no
  vuelve a cambiar por su cuenta: el estado que deja la persona sigue igual 4 s después.
- S2. Antes del primer toque el demo se anima como hasta ahora, así que las previews grabadas
  siguen valiendo.
- S3. El gesto del componente sigue funcionando: el toque que para el demo también hace efecto.
- S4. Todos usan la misma pieza: `@State private var isAutoPlaying = true`, el bucle
  `while isAutoPlaying`, y
  `.simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })`.
  Un demo con una hoja la aplica también dentro de la hoja.
- S5. `AGENTS.md` lo pide como regla para demos nuevos.

## Tareas
- [x] T1 (S1–S4) `CoverFlowCarousel`, como prueba de la pieza · probado en iOS 27.2 y 18.5
- [x] T2 (S1–S4) Scroll: `PagedGridLauncher`, `VerticalFullScreenFeed`, `HideOnScrollBar`,
  `ScrollProgressBar`, `StickyStackedCards`, `ScrollVisibilityReveal` · probados en iOS 27.2 y 18.5
- [x] T3 (S1–S4) `CustomDetentSheet`, `DoubleTapHeartOverlay`, `DoubleTapZoomImage`,
  `SpinningVinylArt`, `SearchScopesAndSuggestions`, `AdaptiveColumnsGrid`, `MasonryLayout` · probados
- [x] T4 (S5) Regla 14 en `AGENTS.md` y entrada en el CHANGELOG

## Verificación
`make verify`. A mano, por demo: abrirlo, comprobar que se mueve solo, tocarlo, y comparar dos
capturas separadas 4 s.

## Log
- L1. «Sí, los demos», a la pregunta «¿Sigo con los 14 demos que se mueven solos y pelean con el
  dedo?», tras la propuesta del informe: «que la reproducción automática se detenga al primer
  toque, con la misma pieza en todos, y una regla en `AGENTS.md` que lo pida».
- L2. 2026-11-11. Cinco demos ya tenían `isAutoPlaying` (`AnimatedRadioButton`, `RatingStars`,
  `PolygonMorphShape`, `BlurredImageBackdrop`, `SpotlightOverlay`); se usa el mismo nombre.
- L3. 2026-11-11. `CoverFlowCarousel` en iOS 27.2 y 18.5: se anima solo, un deslizamiento lo
  para y pasa de portada, y 4 s después sigue en la misma.
- L4. 2026-11-11. Prueba por demo con `autoplay-test.sh`: dos capturas antes de tocar (se mueve)
  y dos separadas 4 s tras un deslizamiento (quieto). Trece de trece en iOS 27.2 y en 18.5. En
  `DoubleTapHeartOverlay` y `SpinningVinylArt` la medida por capturas no sirve; se comprobó el
  estado de sus botones.
- L5. 2026-11-11. `SearchScopesAndSuggestions` cambia la spec S4: su reproducción automática abría
  y cerraba la búsqueda, y eso dejaba los filtros sin aparecer al buscar a mano. Se quita y la
  preview se graba con `previewSteps`. El filtro vuelve a «All» al cerrar la búsqueda.
- L6. 2026-11-11. `CustomDetentSheet`: la hoja es otra presentación, así que lleva el gesto
  dentro; y si alguien la arrastra por el tirador, el bucle lo nota porque el detent ya no es
  el que puso. Tocar el fondo atenuado no lo para: no es tocar el componente.
- L7. 2026-11-11. `MasonryLayout` y `AdaptiveColumnsGrid` ya tenían `autoPlays`; se renombra a
  `isAutoPlaying`.
