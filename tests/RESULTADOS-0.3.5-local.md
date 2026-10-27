# Candidatos 0.3.5 — verificación local 2026-10-27

YouTube Android 0.4.0 y Letras locales 0.1.0 requieren anfitrión 0.3.5. Sin publicación/push.

- ProgramRuntime real: compilación/normalización/búsqueda alternativa, descarte de artista/versión/duración erróneos y arranque de paquete local aprobados (cinco comprobaciones iniciales).
- Búsqueda real YouTube → LRCLIB: Las Noches/Junior H 227 s, BAILE INoLVIDABLE/Bad Bunny 368 s, La Incondicional/Luis Miguel 258 s; letras sincronizadas en los tres casos (1180/2852/1753 caracteres, sin guardar contenido).
- Metadatos MusicBrainz: edición/campos/URL de portada obtenidos para Las Noches y BAILE INoLVIDABLE. Respuestas 503 y timeout intermitentes documentados; no se garantiza disponibilidad. Se mejora selección para recorrer grabaciones y ediciones en lugar de abandonar en la primera sin datos.
- Anfitrión: prueba optativa de enriquecimiento completo con audio sintético de 4 s, paquete real y caso Las Noches aprobada. Letras 1179 caracteres tras trim y portada 72531 bytes incrustadas; álbum identificado, sin aviso parcial. Archivos temporales eliminados, sin contenido lírico como fixture.
- Incompatibilidades observadas de dart_eval: aritmética con valores retornados/nullable/promociones de Map y RegExpMatch. Se simplificaron las operaciones; ejecutar el intérprete sigue siendo necesario, no basta analizar Dart.
- Catálogo local: cuatro extensiones/nueve variantes con hashes verificados; Spotify excluido, históricos conservados. Repositorio público intacto.

Ejecutar desde el anfitrión con dart --packages=.dart_tool/package_config.json RUTA_A_ESTE_REPO/tests/verify_0_3_5.dart; añadir --youtube o --live para red. La prueba optativa genérica del anfitrión recibe rutas/metadatos por dart-define, no incorpora paquetes en producción.

Pendiente: instalación/importación/selector y lectura de archivos personales en Android físico, cobertura de versiones/redes/servicios y revisión antes de publicar. Este candidato no corrige audio nativo YouTube Windows.
