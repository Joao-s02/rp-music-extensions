# Preparación local 0.3.4 — 2026-10-27

Paquetes sin publicar y fuera del catálogo vigente. Requieren app local 0.3.4+13; importar archivo y revisar permisos. Fuentes exclusivamente aquí, no copiadas al anfitrión.

- YouTube Windows: 20 resultados, respuesta AAC parcial de 65536 bytes y recepción completa de 5983881 bytes comprobadas con el verificador genérico. **Prueba nativa Windows fallida**: la posición no avanzó o no inició; varias repeticiones, proxy y búfer descartados del anfitrión por no resolverlo. No se declara reproducción Windows lista. El paquete es candidato experimental.
- YouTube Android: conserva búsqueda/resolución previa y añade operación lyrics y permiso storage.download. No se atribuye prueba nativa Android nueva a este paquete. Nueva consulta de letras ejecutada en ProgramRuntime con fixture de inicio y respuesta sintética.
- Spotify ambas plataformas: paquete sin cuenta obtiene datos públicos del embed y devuelve un resultado; URL de audioPreview entregó 65536 bytes HTTP 206. Es un fragmento, no canción completa. No hay búsqueda por nombre ni reproducción nativa/selector nueva aprobada. Letras completas planas; no simular sincronización de un fragmento de posición original desconocida.
- Consultas LRCLIB reales sin cuenta: verificadas existencia de plainLyrics/syncedLyrics, sin incluir letras de esas canciones en el repositorio. Consulta opcional por botón, enviando metadatos.
- Paquetes/source coherentes; minAppVersion 0.3.4 y dominios/permisos separados. Android/Windows de YouTube tienen IDs y plataformas distintos, comparten lógica para evitar divergencias innecesarias.
- Anfitrión: 97 pruebas aprobadas y análisis limpio. Incluye navegación de múltiples fuentes con elección explícita, permiso de descarga antes de resolver, textos limitados y letras LRC en pantalla con seek/cambio de canción. No es prueba de exportación real mediante selector ni escucha física.

## Archivos locales exactos

| Archivo | Bytes | SHA-256 |
| --- | ---: | --- |
| spotify-preview.rpmx | 4720 | 78329635c18fdc3e4106a3196e57d2cfc51dce144dc60aeaff01e17022ab29a9 |
| youtube-music-android.rpmx | 8939 | d62e49a593ba26c7ec43ce2502242bb4cfb01a1e0414533d281f4736b4cf2c90 |
| youtube-music-windows.rpmx | 9035 | 8a5b1cb0302b0a8aa1dc44b72cbd3d43d2f36b17fb80ff81480bc41f2febc9ed |

Publicación autorizada por el usuario el 2026-10-27: catálogo ofrece YouTube Android 0.3.0 y Spotify vista previa 0.1.0 solo a anfitriones compatibles. Windows sigue fuera del catálogo recomendado; candidato manual con fallo explícito en manifiesto. La versión pública del anfitrión sigue siendo 0.3.3-alpha.1.
