# Windows audio y YouTube — candidatos locales0.3.10

Sin push/publicación/cambio de catálogo. Requieren app local0.3.10+19 con media_kit/libmpv en Windows; Android conserva su motor. Paquetes anteriores publicados y fuentes Android preservados.

## YouTube API2

YouTube Windows0.4.1 (rp.youtube-music-windows) usa código Dart exacto de YouTube Android0.4.0, con manifiesto Windows/minApp0.3.10. YouTube Explorador Windows0.1.0 (rp.youtube-explorer-windows) usa código Dart exacto de Explorador0.1.0, con identidad/manifiesto Windows independiente. No se migra a JS.

Sonda nativa final: búsqueda pública20 resultados en ambas; dos canciones reales, avance del audio, pausa, seek10s, siguiente/anterior y parada al desactivar aprobados. Búsquedas1050ms/766ms; total hasta cargar y acumular2s de audio3820ms/3498ms, respectivamente. No confundir estas cifras con tiempo puro hasta primer sonido. No garantiza toda canción/región/red; sin cuenta ni sincronización nuevas. Descarga/selector/listas requieren retesteo específico; no se declaran validados solo por reproducir.

## Radio0.1.1 y Explorador JS

Nueva fuente radio_internet_011.js conserva0.1.0. /json/url/UUID devuelve enlace y registra clic en una petición, en vez de consultar por UUID y después pedir clic. Comprueba UUID/HTTPS/URL directa; el anfitrión mantiene validación del stream público. Dos pruebas particulares: una sola consulta y rechazo de respuesta ajena/insegura.

Radio Swiss Pop AAC192: selección952ms, total6952ms con2080ms de avance; inicio aproximado5s en este ensayo. Pausa/reanudación/parada por revocación aprobadas. No acredita resolver cualquier demora30s de otra emisora/red.

Explorador musical JS0.1.0 publicado sin modificar: búsqueda/navegación/100+100 y audio real Windows aprobados con motor nuevo; resolución1610ms y total4318ms con2s de avance. No es únicamente URL o recepción de bytes.

## Compatibilidad y límites

Suite conjunta142 aprobadas/una red optativa omitida; incluye132 de app, ocho externas anteriores y dos Radio0.1.1. Pruebas dirigidas/repeticiones nativas no se suman a ese total. Análisis final limpio. Doce controles de formatos del anfitrión, rechazo de archivo inválido/recuperación y bandeja/cierre comprobados según bóveda del anfitrión.

build_windows_0310.py genera únicamente previews/0.3.10 y hashes; comprueba las huellas de paquetes base, nunca cambia catálogo. Datos/música privados fuera del repositorio y distribuciones. Avisos nativos no fatales de osc/caché/TLS en cierre documentados; no se confunden con errores del canal de reproducción. Android físico, escucha prolongada y latencia general API3 pendientes.
