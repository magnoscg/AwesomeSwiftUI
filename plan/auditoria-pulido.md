# Auditoría de pulido de los componentes
Estado: cerrada · Rama: feature/auditoria-pulido · Abierta: 2026-11-11

## Objetivo
Saber qué componentes del catálogo no están pulidos al usarlos, no solo al mirarlos, para que
Óscar decida cuáles se arreglan. La auditoría no cambia ningún componente.

## Specs
- S1. Los 280 componentes tienen una línea en `findings/grupo-<N>.jsonl`: un hallazgo, `ok` con
  los controles que se tocaron, o `sin-probar` con el motivo.
- S2. Cada hallazgo lleva `gravedad` (`alta`, `media`, `baja`), `tipo` (`funcion`, `movimiento`,
  `tacto`, `layout`, `demo`), qué pasa, cómo se reproduce y `evidencia` (`visto` o `codigo`).
- S3. Todo hallazgo de gravedad `alta` está reproducido por la sesión principal antes de entrar
  en el informe; los que no se reproducen se descartan y se dice cuántos.
- S4. El informe ordena por gravedad, agrupa por categoría y dice cuántos componentes quedaron
  `ok`, con hallazgos y `sin-probar`.

## Tareas
- [x] T1 (S1, S2) Guion `au.sh`, tiras de fotogramas, ocho grupos e instrucciones · sin commit, en el scratchpad
- [x] T2 (S1, S2) Grupos 1 a 4, un agente Sonnet y un simulador por grupo · 143 componentes
- [x] T3 (S1, S2) Grupos 5 a 8 · 137 componentes; 280 de 280 con línea
- [x] T4 (S3) Reproducir los hallazgos de gravedad alta · 6 de 7 reproducidos, 1 sin confirmar
- [x] T5 (S4) Informe para Óscar · enviado como fichero, fuera del repositorio

## Verificación
No hay código que verificar. Se comprueba que cada grupo cubre todos sus componentes (S1) y se
reproduce a mano cada hallazgo grave (S3) con `au.sh` en el simulador.

## Log
- L1. «hay componentes que he probado que no los veo muy pulidos en alguna animacion o toque.
  Quiza unos agentes sonnet proandolos y haciendo un informe vendria bien»
- L2. 2026-11-11. Ejemplo de Óscar para calibrar: «el de spy algo que eran chips y al hacer
  scroll cambian pero si pulsaba no se iba a laseccion correspondiente». Reproducido en
  `ScrollSpyHeader`: `ScrollViewReader` no salta a una sección que la pila perezosa no ha creado.
  Arreglado aparte en `feature/scroll-spy-header-jump` (c1029a9) con `ScrollPosition`.
- L3. 2026-11-11. Consecuencia para el criterio: mirar el código o la preview no encuentra este
  tipo de fallo. Los agentes tienen que tocar cada control del demo y comprobar el resultado.
- L4. 2026-11-11. Los arreglos que salgan del informe son features aparte; esta no los incluye.
- L5. 2026-11-11. Resultado: 133 hallazgos (7 altos, 47 medios, 79 bajos) en 112 componentes; 168
  sin pegas. Altos reproducidos: `EmojiPicker`, `WheelPicker`, `DropdownSelectMenu`,
  `InteractiveLineChart`, `NotchedTabBar` y `SearchScopesAndSuggestions`. Sin confirmar:
  el doble toque de `PhotoLightbox`; `axe batch` con dos toques no produce un doble toque.
- L6. 2026-11-11. `NotchedTabBar` era una regresión de la localización (0.5.0): un
  `LocalizedStringResource` interpolado en un `String` imprime su volcado. Arreglado aparte
  (PR 69) junto con el anuncio de `UndoSnackbar`.
- L7. 2026-11-11. `SearchScopesAndSuggestions` se rebaja a medio: sin la reproducción automática
  del demo los filtros aparecen. Catorce demos comparten ese patrón.
- L8. 2026-11-11. Tres de los altos ya se veían en la preview publicada. Al grabar hay que mirar
  qué enseña la preview, no solo que se mueva.
