# Variantes para RP Music 0.3.3 — pruebas locales

Verificación previa a la distribución de los paquetes: fuente 0.2.1 con icono temático playOutline y Biblioteca viva 0.1.1 con filtro por artistas separados por comas. Ambas requieren 0.3.3. Fuentes y envoltorios comparados, hashes de todas las variantes comprobados; entradas previas conservadas.

Biblioteca viva ejecutada por ProgramRuntime con tests/multiple-artists.json: filtrar por Dos devuelve canción etiquetada Uno, Dos. La fuente conserva lógica de búsqueda/audio de 0.2.0 y cambia su manifiesto visual.

Host: 86 pruebas aprobadas y análisis limpio, incluyendo artistas en grupos distintos, snapshot, historial anterior/avance, listas y UI. Android emulador API 37, recorrido genérico con paquete externo 0.2.1: búsqueda, dos canciones, pausa/seek, Anterior y Siguiente históricos, progreso monotónico 30 s y revocación: aprobado (96 s de test total, no escucha continua de 96 s). Un primer intento no alcanzó >2 s de posición dentro de la espera fija de 5 s; se conserva como fallo de ese ensayo. El recorrido aprobado fue en primer plano, sin nueva comprobación HOME/SLEEP. Retesteo físico y escucha prolongada pendientes.

Windows de la fuente, cuentas, listas/favoritos/historial online siguen pendientes. Interfaz de fuente/proveedor permanece separada del anfitrión; no copiar paquetes al repositorio principal.
