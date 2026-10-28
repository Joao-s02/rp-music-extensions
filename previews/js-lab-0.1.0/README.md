# Laboratorio JS 0.1.0 — prueba experimental

Requiere RP Music 0.3.8 o posterior. API 3/JavaScript, capacidad screen. Instalar por archivo desde Extensiones, aceptar permisos y pulsar Abrir pantalla o abrir su acceso de navegación. No sustituye Fuente: YouTube estable y Explorador siguen instaladas con motor Dart. Se ofrece como opción independiente en el catálogo desde la publicación de 0.3.8.

La extensión define tres páginas mediante árboles de componentes nativos y decide la navegación: saludo con formulario, panel con contador persistente, y biblioteca con búsqueda local/reproducción explícita. Guarda datos solo dentro de la app. No requiere cuenta ni red. La vista de biblioteca recibe hasta 500 pistas autorizadas, muestra hasta ocho resultados y no recibe rutas de archivos.

JavaScript estándar/QuickJS; no Node/npm ni HTML/CSS libre. Este prototipo demuestra autonomía de flujo y composición, sin prometer componentes ilimitados o todas las futuras capacidades de un SDK.

Regenerar: python build_js_lab.py. Pruebas específicas en tests/javascript_lab_test.dart, ejecutadas desde el anfitrión con Flutter y la biblioteca nativa QuickJS compilada. No copiar fuentes/paquete al repositorio principal.
