# Extensiones de RP Music

Catálogo público experimental para RP Music 0.3.0 (API 2). La versión pública 0.2.6 no incluye todavía este sistema.

En la compilación compatible: Extensiones → Explorar repositorio → introducir https://github.com/Joao-s02/rp-music-extensions → Consultar → elegir una extensión → revisar permisos.

También se pueden descargar los archivos `.rpmx` de `packages/` e importarlos manualmente. Biblioteca viva añade filtros y listas automáticas; Pulso nocturno cambia la disposición del reproductor y la selección aleatoria.

El catálogo no activa ni actualiza extensiones automáticamente. El SHA-256 comprueba coherencia con el índice, no acredita la identidad del autor. Usa repositorios de confianza. El intérprete experimental tiene límites de tiempo, pero no una cuota dura de memoria.

`catalog.json` usa schemaVersion 1 y una lista extensions con id, name, version, description, path relativo y sha256. Para publicar una actualización: regenerar el paquete, incrementar su versión y actualizar el índice con el hash del archivo exacto. No alterar paquetes sin actualizar su hash.

Fuentes Dart en `sources/`. Contrato y empaquetador en el [proyecto principal](https://github.com/Joao-s02/rp_music). Este repositorio distribuye ejemplos; no distribuye la aplicación ni sus datos musicales.

Para regenerar el índice desde los paquetes: `python actualizar_catalogo.py`. Publica índice y paquetes en el mismo commit.


## YouTube Music experimental · Android

Nuevo paquete `packages/youtube-music.rpmx`, requiere **RP Music 0.3.1 o superior en Android**. La release pública 0.2.6 y las compilaciones 0.3.0 no incluyen el adaptador requerido. Instala primero la compilación compatible de prueba, consulta este repositorio, instala y acepta los permisos de internet de YouTube/reproducción; después pulsa **Abrir YouTube Music** en la tarjeta de Extensiones.

Primera entrega: búsqueda de canciones del catálogo musical, reproducción solo audio sin cuenta, cola, pausa/avance/cambio de pista y carátula. El adaptador de red/audio reside en el anfitrión y el paquete programa el contrato de búsqueda. No es acceso HTTP arbitrario ni una extensión que pueda ejecutarse en cualquier versión de RP Music.

Listas/favoritos/historial de esta fuente, cuentas, álbumes/artistas completos y Windows quedan pendientes. Integración no oficial experimental, sin garantía sobre todos los temas/regiones/redes. En emulador Android se verificaron búsqueda, dos canciones y controles, desactivación y pantalla apagada; falta validación en teléfono físico.
