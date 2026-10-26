# Extensiones de RP Music

Catálogo público experimental API 2. Android y Windows: [RP Music 0.3.2-alpha.1](https://github.com/Joao-s02/rp_music/releases/tag/v0.3.2-alpha.1). La fuente inicial sigue siendo Android. Cada paquete indica su versión/plataforma compatible.

En la compilación compatible: Extensiones → Explorar repositorio → introducir https://github.com/Joao-s02/rp-music-extensions → Consultar → elegir una extensión → revisar permisos.

También se pueden descargar los archivos `.rpmx` de `packages/` e importarlos manualmente. Biblioteca viva añade filtros y listas automáticas; Pulso nocturno cambia la disposición del reproductor y la selección aleatoria.

El catálogo no activa ni actualiza extensiones automáticamente. El SHA-256 comprueba coherencia con el índice, no acredita la identidad del autor. Usa repositorios de confianza. El intérprete experimental tiene límites de tiempo, pero no una cuota dura de memoria.

`catalog.json` usa schemaVersion 1 y una lista extensions con id, name, version, description, path relativo y sha256. Para publicar una actualización: regenerar el paquete, incrementar su versión y actualizar el índice con el hash del archivo exacto. No alterar paquetes sin actualizar su hash.

Fuentes Dart en `sources/`. Contrato y empaquetador en el [proyecto principal](https://github.com/Joao-s02/rp_music). Este repositorio distribuye ejemplos; no distribuye la aplicación ni sus datos musicales.

Para regenerar el índice desde los paquetes: `python actualizar_catalogo.py`. Publica índice y paquetes en el mismo commit.


## Extensiones para fuentes de música en la nube · Android

Primer paquete de prueba: `packages/youtube-music.rpmx`, requiere **RP Music 0.3.1 o superior en Android**. Instala primero la release compatible, consulta el catálogo e instala el paquete revisando sus permisos; después abre su fuente desde la tarjeta de Extensiones. La capacidad está habilitada mediante extensiones/adaptadores compatibles, no implica soporte de cualquier servicio.

Antecedente del paquete 0.1.0 con RP Music 0.3.1: búsqueda de canciones del catálogo musical, reproducción solo audio sin cuenta, cola, pausa/avance/cambio de pista y carátula. El adaptador de red/audio reside en el anfitrión y el paquete programa el contrato de búsqueda. No es acceso HTTP arbitrario ni una extensión que pueda ejecutarse en cualquier versión de RP Music.

Listas/favoritos/historial de esta fuente, cuentas, álbumes/artistas completos y Windows quedan pendientes. Integración no oficial experimental, sin garantía sobre todos los temas/regiones/redes. En emulador Android se verificaron búsqueda, dos canciones y controles, desactivación y pantalla apagada; el usuario confirmó búsqueda/audio rápidos y sin fallos funcionales observados en su prueba. Quedan detalles de diseño para la siguiente versión y validaciones prolongadas.

## Paquete compatible con RP Music 0.3.2

`previews/0.3.2/youtube-music.rpmx` 0.2.0 contiene búsqueda, parser y resolución de audio en Dart interpretado. Requiere RP Music 0.3.2 Android, permisos de HTTP a dominios declarados, reproducción y navegación. Añade acceso YT con icono de reproducción rojo. Importar esta versión vuelve a pedir consentimiento; el paquete antiguo 0.1.0 no usa el nuevo transporte.

La entrada base del catálogo conserva 0.1.0 para RP Music 0.3.1; `versions` ofrece 0.2.0 a anfitriones compatibles. `catalog-variants.json` configura variantes y actualizar_catalogo.py calcula sus hashes. No sustituir la entrada base mientras haya clientes anteriores. Legacy conserva el prototipo y sus antiguas pruebas como antecedente, no como implementación vigente.

La reproducción sigue sin cuenta. Puede no estar disponible para ciertos temas/regiones/redes; no se eluden requerimientos de cuenta. Windows, listas, favoritos e historial siguen pendientes. Pruebas concretas y límites se anotan en tests/RESULTADOS-0.2.0.md antes de distribuir.
