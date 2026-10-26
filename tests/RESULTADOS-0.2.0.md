# Fuente 0.2.0 para RP Music 0.3.2 — verificación local

2026-10-26. Verificación previa a la distribución del paquete 0.2.0 para RP Music 0.3.2-alpha.1.

- Fuente y paquete coherentes byte a byte normalizando saltos de línea. Hashes de todas las entradas/variantes del catálogo comprobados.
- Parser ejecutado mediante ProgramRuntime con fixture sintético: devuelve Demo. Búsqueda real: 20 resultados para la consulta de demostración.
- Resolución real anónima: HTTP 206 con 65536 bytes AAC. Bootstrap con configuración/cookies anónimas en memoria; sin ese paso se observó LOGIN_REQUIRED. No eludir condiciones de acceso de contenido.
- Android emulador API 37, prueba genérica integration_test/extension_source_test.dart del anfitrión en depuración: paquete externo instalado con permisos, búsqueda, dos canciones, pausa/seek, 30 s de observación monotónica de la segunda canción y revocación que impide reanudar. HOME y SLEEP enviados durante la observación; resultado RP_SOURCE_PROBE_OK y prueba aprobada. La ejecución completa duró 73 s, no corresponde a 73 s de escucha continua.
- El manifiesto define el acceso YT (playBadge rojo), nombre del servicio, dominios y plataforma Android. UI/SDK genérico comprobados por pruebas del anfitrión; retesteo en teléfono físico pendiente.

No se prueba toda la biblioteca de música, múltiples regiones/redes ni escucha prolongada. Windows/listas/favoritos/historial/cuentas siguen pendientes. No se promete compatibilidad con cualquier contenido ni políticas de tienda. El paquete 0.1.0 se conserva para RP Music 0.3.1; 0.2.0 requiere 0.3.2 y nuevo consentimiento de permisos.

Para repetir el fixture: desde el checkout del anfitrión compatible, ejecutar tools/run_extension_fixture.dart pasando la ruta de este paquete y tests/search-fixture.json. Para búsqueda/audio HTTP: tools/verify_source_package.dart con paquete y consulta. La prueba Android recibe SOURCE_PACKAGE_GZIP y SOURCE_QUERY mediante dart-define-from-file; comprimir el JSON con gzip y codificarlo base64. No copiar fuentes o paquetes específicos al repositorio principal.
