# Candidatos 0.3.11: resultados locales

YouTube Android/Windows0.5.0 y Explorador Android/Windows0.2.0 para anfitrión0.3.11, API2 conservada. verify_0311.dart comprueba cada paquete real en dart_eval: rechazo de álbum distinto/desconocido, álbum bloqueado sin MusicBrainz ni reemplazo por letras, desempate estable y campos opcionales ausentes. Fotos públicas y encabezado real con portada de máxima resolución comprobados. live_album_0311.dart conserva las consultas de proveedor exclusivamente aquí.

Harness genérico del anfitrión, escenario tests/album-export-0311.json: seis archivos del álbum público My Dear Melancholy, todos con mismo álbum/artista de álbum/portada incrustada y secuencia1–6. Foto de artista cacheada y abierta offline. Audio temporal eliminado. Pruebas sintéticas de fallo parcial/cancelación/no sobrescritura y suite del anfitrión aprobadas. Un timeout y ensayo parcial previos no se presentan como disponibilidad universal; integración final usa runAsync y un único reintento explícito de transporte.

No hay Android físico nuevo; widgets y exportación SAF deben probarse en teléfono. Paquetes/catálogo publicados intactos y estos candidatos no se publican todavía. No se incorpora código de Mornye; referencia de flujo/prioridad de metadatos facilitada por el usuario: https://github.com/mornyeapp/Mornye .
