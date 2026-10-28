# YouTube Explorador 0.1.0 — opción experimental

Identidad independiente rp.youtube-explorer, copiada de YouTube Android 0.4.0 (rp.youtube-music). BASELINE.json registra el SHA256 del paquete original; build_explorer.py lo comprueba al regenerar. No reemplaza archivos estables; se ofrece como entrada separada del catálogo. Requiere RP Music 0.3.7 o posterior.

Instalar por archivo desde Extensiones. Ambas pueden permanecer instaladas; elegir explícitamente cuál controla Fuente, o Usar esta fuente. Desactivar Explorador y elegir YouTube Android permite volver a la estable. No se conectan cuentas ni se sincronizan datos remotos todavía.

Exploración pública: filtros de canciones/artistas/álbumes/listas; páginas, reproducción y Cargar más. Álbumes/listas completos cargados se pueden importar como copias locales. Importar no descarga audio. Se mantienen el flujo heredado de audio, descarga y metadatos; no garantiza disponibilidad regional ni todos los formatos de respuesta.

Regeneración: python build_explorer.py. Verificación desde el anfitrión: dart --packages=.dart_tool/package_config.json RUTA_EXTERNA/tests/verify_explorer.dart --live. La lógica de proveedor y fixtures no se copian al repositorio de la app.
