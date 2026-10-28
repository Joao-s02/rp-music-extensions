# Extensiones de RP Music

## Para RP Music 0.3.5

`previews/0.3.5/youtube-music-android.rpmx`: YouTube Android 0.4.0. Corrige extracción de artista/duración y búsqueda de letras mediante normalización, búsqueda alternativa y comprobación de versión/duración. Descargas consultan MusicBrainz/Cover Art Archive para etiquetas y portada; letras LRCLIB disponibles se incrustan por el anfitrión. Requiere RP Music 0.3.5.

`previews/0.3.5/letras-locales.rpmx`: Letras locales 0.1.0. Proveedor de letras independiente de la fuente musical. Al seleccionar una canción local sin letra incrustada/caché, busca automáticamente. Solo guarda en soporte privado de la app; no escribe en música local. Requiere permisos library.read/network.http/lyrics.cache y app 0.3.5.

Regenerar candidatos con `python build_0_3_5.py`. Combina `sources/metadata_lyrics.dart` con plantilla YouTube en `sources/youtube_music.dart`; genera fuentes completas youtube_enriched.dart y letras_locales.dart y sus paquetes. Intérprete real y comprobaciones en tests/verify_0_3_5.dart, ejecutado con el package_config del anfitrión. El catálogo omite Spotify por cancelación expresa; no borra paquetes/historia. Se conservan las variantes para clientes anteriores. No son adjuntos ni assets de la app principal.

Instalar desde el catálogo o importar los archivos anteriores. Las extensiones siguen siendo experimentales: retesteo físico Android/selector pendiente, cobertura de letras y metadatos no garantizada. Pruebas en [resultados 0.3.5](tests/RESULTADOS-0.3.5-local.md).

Los apartados siguientes describen el historial de 0.3.4 y entregas anteriores.

Catálogo público experimental API 2. Android y Windows: [RP Music 0.3.5-alpha.1](https://github.com/Joao-s02/rp_music/releases/tag/v0.3.5-alpha.1). La fuente inicial sigue siendo Android. Cada paquete indica su versión/plataforma compatible.

En la compilación compatible: Extensiones → Explorar repositorio → introducir https://github.com/Joao-s02/rp-music-extensions → Consultar → elegir una extensión → revisar permisos.

También se pueden descargar los archivos `.rpmx` de `packages/` e importarlos manualmente. Biblioteca viva añade filtros y listas automáticas; Pulso nocturno cambia la disposición del reproductor y la selección aleatoria.

El catálogo no activa ni actualiza extensiones automáticamente. El SHA-256 comprueba coherencia con el índice, no acredita la identidad del autor. Usa repositorios de confianza. El intérprete experimental tiene límites de tiempo, pero no una cuota dura de memoria.

`catalog.json` usa schemaVersion 1 y una lista extensions con id, name, version, description, path relativo y sha256. Para publicar una actualización: regenerar el paquete, incrementar su versión y actualizar el índice con el hash del archivo exacto. No alterar paquetes sin actualizar su hash.

Fuentes Dart en `sources/`. Contrato y empaquetador en el [proyecto principal](https://github.com/Joao-s02/rp_music). Este repositorio distribuye ejemplos; no distribuye la aplicación ni sus datos musicales.

Para regenerar el índice desde los paquetes: `python actualizar_catalogo.py`. Publica índice y paquetes en el mismo commit.


## Extensiones para fuentes de música en la nube · Android

Primer paquete de prueba: `packages/youtube-music.rpmx`, requiere **RP Music 0.3.1 en Android** (para 0.3.2 usar la variante 0.2.0 indicada abajo). Instala primero la release compatible, consulta el catálogo e instala el paquete revisando sus permisos; después abre su fuente desde la tarjeta de Extensiones. La capacidad está habilitada mediante extensiones/adaptadores compatibles, no implica soporte de cualquier servicio.

Antecedente del paquete 0.1.0 con RP Music 0.3.1: búsqueda de canciones del catálogo musical, reproducción solo audio sin cuenta, cola, pausa/avance/cambio de pista y carátula. El adaptador de red/audio reside en el anfitrión y el paquete programa el contrato de búsqueda. No es acceso HTTP arbitrario ni una extensión que pueda ejecutarse en cualquier versión de RP Music.

Listas/favoritos/historial de esta fuente, cuentas, álbumes/artistas completos y Windows quedan pendientes. Integración no oficial experimental, sin garantía sobre todos los temas/regiones/redes. En emulador Android se verificaron búsqueda, dos canciones y controles, desactivación y pantalla apagada; el usuario confirmó búsqueda/audio rápidos y sin fallos funcionales observados en su prueba. Quedan detalles de diseño para la siguiente versión y validaciones prolongadas.

## Paquete compatible con RP Music 0.3.2

`previews/0.3.2/youtube-music.rpmx` 0.2.0 contiene búsqueda, parser y resolución de audio en Dart interpretado. Requiere RP Music 0.3.2 Android, permisos de HTTP a dominios declarados, reproducción y navegación. Añade acceso YT con icono de reproducción rojo. Importar esta versión vuelve a pedir consentimiento; el paquete antiguo 0.1.0 no usa el nuevo transporte.

La entrada base del catálogo conserva 0.1.0 para RP Music 0.3.1; `versions` ofrece 0.2.0 a anfitriones compatibles. `catalog-variants.json` configura variantes y actualizar_catalogo.py calcula sus hashes. No sustituir la entrada base mientras haya clientes anteriores. Legacy conserva el prototipo y sus antiguas pruebas como antecedente, no como implementación vigente.

La reproducción sigue sin cuenta. Puede no estar disponible para ciertos temas/regiones/redes; no se eluden requerimientos de cuenta. Windows, listas, favoritos e historial siguen pendientes. Pruebas concretas y límites se anotan en tests/RESULTADOS-0.2.0.md antes de distribuir.


Publicación confirmada: RP Music 0.3.2-alpha.1 disponible para Android/Windows; la variante de fuente 0.2.0 está publicada en este catálogo y su hash remoto fue verificado. El paquete 0.1.0 se conserva para RP Music 0.3.1. No se adjuntan extensiones a la release de la app.

## Actualizaciones para RP Music 0.3.3

- previews/0.3.3/youtube-music.rpmx 0.2.1: icono de contorno playOutline, con color/tamaño del tema del anfitrión. Búsqueda/audio conservan el código verificado de 0.2.0. Requiere anfitrión 0.3.3.
- previews/0.3.3/biblioteca-viva.rpmx 0.1.1: filtro que reconoce cada artista separado por comas, manteniendo compatibilidad con la etiqueta original. Requiere anfitrión 0.3.3 para las nuevas opciones del selector.

El catálogo selecciona estas variantes en RP Music 0.3.3. Se conservan entradas para 0.3.1/0.3.2. Consulta el repositorio desde la app, elige Actualizar y revisa sus permisos; también puedes importar estos archivos manualmente. Fuente de Biblioteca viva actualizada aquí; los ejemplos heredados del principal no se copian ni actualizan.


Publicación confirmada: [RP Music 0.3.3-alpha.1](https://github.com/Joao-s02/rp_music/releases/tag/v0.3.3-alpha.1) disponible. Fuente 0.2.1 y Biblioteca viva 0.1.1 publicadas en este catálogo y sus hashes remotos verificados; requieren anfitrión 0.3.3. Se mantienen variantes compatibles con 0.3.1/0.3.2. Las extensiones no se adjuntan a la release de la aplicación.

## Preparación 0.3.4 — sin publicar

Paquetes en previews/0.3.4, importación manual con app local 0.3.4+13. Android y Windows tienen manifiestos/IDs de YouTube separados, compartiendo sources/youtube_music.dart; requieren nuevo permiso storage.download para exportar y añaden LRCLIB como dominio para letras opcionales. No se modifica catálogo publicado.

spotify-preview.rpmx 0.1.0 funciona con ambas plataformas sin cuenta, mediante embed público de Spotify. Pegar enlace de canción; únicamente audioPreview cuando existe, no audio completo ni búsqueda por nombre. Letras completas sin sincronización porque no conocemos el offset del fragmento. No se usa otro proveedor de audio simulando Spotify. Verificación y límites en tests/RESULTADOS-0.3.4.md.

## Publicación autorizada para RP Music 0.3.4

El catálogo ofrece YouTube Android 0.3.0 con letras LRCLIB y descarga manual, y Spotify · vistas previas 0.1.0 (un paquete Android/Windows). Ambos requieren anfitrión 0.3.4 y revisión de permisos. Versiones anteriores se conservan.

Spotify: pegar enlace público de canción; solo fragmentos disponibles sin cuenta, sin búsqueda por nombre ni canciones completas. Letras planas sin sincronización con el fragmento. YouTube Windows permanece como [candidato manual](previews/0.3.4/youtube-music-windows.rpmx) con fallos de reproducción nativa conocidos, fuera del catálogo recomendado. Las pruebas de recepción de audio no acreditan escucha nativa ni el guardado mediante selector. Detalles/hashes en [resultados](tests/RESULTADOS-0.3.4.md).

Publicación confirmada: RP Music 0.3.4-alpha.1 / app 0.3.4+13, con los siete adjuntos Android/Windows/guías/hashes verificados. Catálogo y paquetes de este repositorio comparados con descargas públicas; Android 0.3.0 y Spotify vista previa 0.1.0 disponibles, versiones anteriores preservadas. Windows sigue siendo candidato manual con fallos nativos conocidos.

Publicación 0.3.5 confirmada: https://github.com/Joao-s02/rp_music/releases/tag/v0.3.5-alpha.1. App 0.3.5+14; siete adjuntos verificados en el principal. Catálogo/paquetes de este repositorio públicos y comprobados desde la app 0.3.5. La publicación no sustituye retesteo físico Android ni corrige YouTube Windows.

## YouTube Explorador 0.1.0 — para RP Music 0.3.7+

Opción experimental separada de YouTube Android 0.4.0. Ambas pueden instalarse; elegir cuál controla Fuente o pulsar Usar esta fuente. La estable se conserva intacta. [Paquete Explorador](previews/explorer-0.1.0/youtube-explorer.rpmx) · [Uso y límites](previews/explorer-0.1.0/README.md).

Añade exploración pública de artistas/álbumes/listas y paginación; permite importar álbum/lista cargados como copia local independiente, sin descargar audio automáticamente. No incluye cuenta Google ni sincronización; no promete discografía exhaustiva. Android solamente para reproducción del proveedor. No se adjunta a releases de la app. Verificaciones y límites en [resultados](tests/RESULTADOS-explorer-local.md).
