# Explorador y radio JavaScript — verificación local 2026-10-28

App local 0.3.9+18, API 3 ampliada, sin publicar/push/cambio de catálogo. Dos paquetes 0.1.0 independientes/minAppVersion 0.3.9, externos al APK/ZIP. YouTube estable/Explorador Dart y Laboratorio JS previos conservados.

Suite conjunta: **138 aprobadas** (130 app + ocho externas: dos anteriores y seis nuevas), una prueba optativa de red omitida. Pruebas dirigidas iniciales/repeticiones no se suman. Análisis final de app/test/integration/tools y seis pruebas nuevas sin incidencias. Protecciones nativas de bucle y recursión comprobadas; ausencia inicial de DLL se resolvió indicando la carpeta Release en PATH.

Casos externos: artista/álbum/100 pistas/continuación que excluye recomendaciones/Atrás; resolución AAC sintética/errores/enlace ajeno; radio/HTTPS/favoritas/restauración/renovación UUID/recuperación de espejo; pantallas reales 360px y escala 1.5 sin desbordes. Respuestas grandes se recorren iterativamente y estado se limita con aviso.

Sonda nativa Windows final (archivo RESULTADOS-js-music-native.json): búsqueda pública de artistas/álbumes/listas/canciones; apertura con contenido nuevo (artista 50 elementos, álbum una pista en esa edición, lista 13); resolución real AAC de La Incondicional; lista pública larga con bloque de 100 y continuación de 100. Resultados públicos varían; no se afirma catálogo completo.

Radio Swiss Pop AAC 192: dos coincidencias HTTPS, favorita guardada, audio nativo avanzó 2167 ms, pausa/reanudación y parada por desactivación aprobadas, sin errores. Resolver YouTube no acredita reproducción nativa Windows. Android sin dispositivo adb conectado; prueba física pendiente. Compilaciones normales se registran en la bóveda de RP Music al terminar.

Límite hallado/corregido: depuración Windows con pila QuickJS predeterminada 256 KiB no procesaba JSON anidado de colecciones; host fija 512 KiB manteniendo límite bajo pila de hilo Windows (1 MiB), heap 32 MiB y timeout nativo 1000 ms. Sonda endurecida detectó el problema al rechazar error=true, evitando contar como éxito resultados antiguos conservados.

Fuentes primarias: https://docs.radio-browser.info/ y https://ytmusicapi.readthedocs.io/en/stable/reference/browsing.html . Sin credenciales/cuentas; solo datos públicos. Estado propuesto de firmas/aislamiento de proceso no cambia por estas pruebas.

Cierre de binarios del anfitrión: APK universal normal0.3.9/código18/firma v2 compatible/tres ABI y Windows normal0.3.9+18/ZIP21 archivos con QuickJS/guía. Compilación Windows63.3s/Android185.9s. Salidas y hashes en dist/0.3.9-local del anfitrión; paquetes de extensiones conservados fuera de ambos binarios. Android físico pendiente. Sin publicación/push.
