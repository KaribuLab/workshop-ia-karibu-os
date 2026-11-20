-- Datos de prueba. Empresa ficticia "Cordillera Servicios".
-- Las fechas son relativas al día en que se crea la base, para que siempre
-- haya compromisos vencidos, por vencer y futuros.
--
-- Casos sembrados a propósito para los ejercicios:
--   A. Compromisos vencidos y aún Pendiente / En curso (varios proyectos).
--   B. Compromisos sin responsable.
--   C. Riesgos Alta / Crítica sin dueño o sin plan de mitigación.
--   D. Proyecto "En curso" con 0 % de avance y fecha de fin cercana (P5).
--   E. Proyecto marcado "En curso" cuya fecha de fin ya pasó (P3).
--   F. Compromisos asignados a una persona inactiva (persona 14).
--   G. Proyecto "Cerrado" con un compromiso todavía Pendiente (P8).

INSERT INTO equipos (equipo_id, nombre, proposito) VALUES
  (1, 'Comercial',    'Conseguir y cuidar clientes'),
  (2, 'Delivery',     'Ejecutar los proyectos comprometidos con clientes'),
  (3, 'Plataforma',   'Mantener la infraestructura y herramientas internas'),
  (4, 'Personas',     'Contratación, onboarding y desarrollo del equipo');

INSERT INTO personas (persona_id, nombre, email, rol, equipo_id, activo) VALUES
  ( 1, 'Valentina Rojas',    'valentina.rojas@cordillera.test',    'Líder Comercial',        1, true),
  ( 2, 'Matías Fuentes',     'matias.fuentes@cordillera.test',     'Ejecutivo de cuentas',   1, true),
  ( 3, 'Camila Soto',        'camila.soto@cordillera.test',        'Ejecutiva de cuentas',   1, true),
  ( 4, 'Ignacio Paredes',    'ignacio.paredes@cordillera.test',    'Preventa',               1, true),
  ( 5, 'Francisca Morales',  'francisca.morales@cordillera.test',  'Líder de Delivery',      2, true),
  ( 6, 'Sebastián Castro',   'sebastian.castro@cordillera.test',   'Jefe de proyecto',       2, true),
  ( 7, 'Antonia Vega',       'antonia.vega@cordillera.test',       'Jefa de proyecto',       2, true),
  ( 8, 'Diego Herrera',      'diego.herrera@cordillera.test',      'Desarrollador',          2, true),
  ( 9, 'Javiera Núñez',      'javiera.nunez@cordillera.test',      'Desarrolladora',         2, true),
  (10, 'Tomás Araya',        'tomas.araya@cordillera.test',        'Analista de datos',      2, true),
  (11, 'Constanza Pizarro',  'constanza.pizarro@cordillera.test',  'Diseñadora',             2, true),
  (12, 'Felipe Contreras',   'felipe.contreras@cordillera.test',   'Analista QA',            2, true),
  (13, 'Rodrigo Sepúlveda',  'rodrigo.sepulveda@cordillera.test',  'Líder de Plataforma',    3, true),
  (14, 'Daniela Espinoza',   'daniela.espinoza@cordillera.test',   'Ingeniera DevOps',       3, false),
  (15, 'Cristóbal Reyes',    'cristobal.reyes@cordillera.test',    'Ingeniero DevOps',       3, true),
  (16, 'Paula Tapia',        'paula.tapia@cordillera.test',        'Ingeniera de seguridad', 3, true),
  (17, 'Nicolás Vargas',     'nicolas.vargas@cordillera.test',     'Soporte',                3, true),
  (18, 'Carolina Muñoz',     'carolina.munoz@cordillera.test',     'Líder de Personas',      4, true),
  (19, 'Benjamín Silva',     'benjamin.silva@cordillera.test',     'Reclutador',             4, true),
  (20, 'Isidora Campos',     'isidora.campos@cordillera.test',     'Analista de personas',   4, true);

INSERT INTO proyectos (proyecto_id, nombre, cliente, equipo_id, responsable_id, estado, fecha_inicio, fecha_fin_planificada, avance_pct) VALUES
  (1, 'Portal de clientes',            'Banco Austral',        2,  6, 'En curso',    current_date - 90,  current_date + 30,  70),
  (2, 'Migración a la nube',           'Seguros del Pacífico', 2,  7, 'En riesgo',   current_date - 120, current_date + 15,  45),
  (3, 'Tablero de ventas',             'Retail Los Andes',     2,  6, 'En curso',    current_date - 75,  current_date - 10,  85),
  (4, 'App de terreno',                'Minera Atacama',       2,  7, 'En curso',    current_date - 40,  current_date + 80,  30),
  (5, 'Automatización de cobranza',    'Clínica Providencia',  2,  5, 'En curso',    current_date - 30,  current_date + 20,   0),
  (6, 'Renovación de monitoreo',       'Interno',              3, 13, 'En curso',    current_date - 50,  current_date + 40,  55),
  (7, 'Programa de onboarding',        'Interno',              4, 18, 'Planificado', current_date + 7,   current_date + 90,   0),
  (8, 'Propuesta red de sucursales',   'Banco Austral',        1,  1, 'Cerrado',     current_date - 150, current_date - 60, 100);

INSERT INTO compromisos (compromiso_id, proyecto_id, descripcion, responsable_id, estado, fecha_compromiso, fecha_cierre) VALUES
  -- P1 Portal de clientes
  ( 1, 1, 'Entregar diseño de la pantalla de inicio',            11, 'Cumplido',  current_date - 60, current_date - 62),
  ( 2, 1, 'Integrar inicio de sesión con el banco',               8, 'Cumplido',  current_date - 35, current_date - 30),
  ( 3, 1, 'Pruebas de carga del portal',                         12, 'En curso',  current_date - 5,  NULL),
  ( 4, 1, 'Capacitar a la mesa de ayuda del cliente',             6, 'Pendiente', current_date + 10, NULL),
  ( 5, 1, 'Publicar versión beta para 50 clientes',               9, 'Pendiente', current_date + 18, NULL),
  ( 6, 1, 'Acta de aceptación firmada',                        NULL, 'Pendiente', current_date + 28, NULL),
  -- P2 Migración a la nube
  ( 7, 2, 'Inventario de servidores actuales',                   15, 'Cumplido',  current_date - 95, current_date - 90),
  ( 8, 2, 'Migrar base de datos de pólizas',                     14, 'En curso',  current_date - 20, NULL),
  ( 9, 2, 'Plan de vuelta atrás aprobado por el cliente',         7, 'Pendiente', current_date - 12, NULL),
  (10, 2, 'Prueba de recuperación ante desastres',               14, 'Pendiente', current_date - 3,  NULL),
  (11, 2, 'Ventana de corte a producción',                        7, 'Pendiente', current_date + 12, NULL),
  (12, 2, 'Apagar servidores antiguos',                        NULL, 'Pendiente', current_date + 25, NULL),
  -- P3 Tablero de ventas
  (13, 3, 'Conectar fuente de ventas diarias',                   10, 'Cumplido',  current_date - 50, current_date - 48),
  (14, 3, 'Definir indicadores con gerencia comercial',           6, 'Cumplido',  current_date - 45, current_date - 40),
  (15, 3, 'Tablero por sucursal',                                10, 'Cumplido',  current_date - 25, current_date - 20),
  (16, 3, 'Corregir diferencias con el cierre contable',         10, 'En curso',  current_date - 15, NULL),
  (17, 3, 'Entrega final y traspaso',                             6, 'Pendiente', current_date - 10, NULL),
  -- P4 App de terreno
  (18, 4, 'Levantamiento con supervisores de faena',              7, 'Cumplido',  current_date - 28, current_date - 28),
  (19, 4, 'Prototipo navegable',                                 11, 'Cumplido',  current_date - 10, current_date - 8),
  (20, 4, 'Modo sin conexión',                                    8, 'En curso',  current_date + 14, NULL),
  (21, 4, 'Piloto con 10 equipos en terreno',                     7, 'Pendiente', current_date + 45, NULL),
  (22, 4, 'Revisión de seguridad de la app',                     16, 'Pendiente', current_date + 60, NULL),
  -- P5 Automatización de cobranza
  (23, 5, 'Reunión de inicio con la clínica',                     5, 'Pendiente', current_date - 25, NULL),
  (24, 5, 'Acceso al sistema de facturación',                  NULL, 'Pendiente', current_date - 18, NULL),
  (25, 5, 'Mapa del proceso actual de cobranza',                 10, 'Pendiente', current_date - 8,  NULL),
  (26, 5, 'Primer flujo automatizado en pruebas',                 9, 'Pendiente', current_date + 10, NULL),
  (27, 5, 'Puesta en marcha',                                     5, 'Pendiente', current_date + 20, NULL),
  -- P6 Renovación de monitoreo
  (28, 6, 'Elegir herramienta de monitoreo',                     13, 'Cumplido',  current_date - 40, current_date - 41),
  (29, 6, 'Instalar agentes en servidores críticos',             15, 'Cumplido',  current_date - 20, current_date - 15),
  (30, 6, 'Alertas de disponibilidad configuradas',              15, 'En curso',  current_date + 3,  NULL),
  (31, 6, 'Turnos de guardia definidos',                         13, 'Pendiente', current_date + 15, NULL),
  (32, 6, 'Dar de baja el monitoreo anterior',                   17, 'Pendiente', current_date + 35, NULL),
  -- P7 Programa de onboarding
  (33, 7, 'Encuesta a los últimos 10 ingresos',                  20, 'En curso',  current_date + 5,  NULL),
  (34, 7, 'Guía del primer día',                                 18, 'Pendiente', current_date + 20, NULL),
  (35, 7, 'Plan de los primeros 30 días por rol',                19, 'Pendiente', current_date + 40, NULL),
  (36, 7, 'Asignar tutores',                                   NULL, 'Pendiente', current_date + 45, NULL),
  -- P8 Propuesta red de sucursales
  (37, 8, 'Presentar propuesta técnica',                          4, 'Cumplido',  current_date - 110, current_date - 112),
  (38, 8, 'Negociar condiciones comerciales',                     1, 'Cumplido',  current_date - 80,  current_date - 75),
  (39, 8, 'Enviar contrato firmado',                              2, 'Cumplido',  current_date - 65,  current_date - 61),
  (40, 8, 'Encuesta de satisfacción al cliente',                  3, 'Pendiente', current_date - 55,  NULL);

INSERT INTO riesgos (riesgo_id, proyecto_id, descripcion, severidad, estado, dueno_id, plan_mitigacion) VALUES
  ( 1, 1, 'El banco puede cambiar su proveedor de inicio de sesión',     'Media',   'Abierto',   6,    'Mantener la integración detrás de una capa propia'),
  ( 2, 1, 'Mesa de ayuda del cliente sin personal para la capacitación', 'Baja',    'Abierto',   6,    NULL),
  ( 3, 2, 'La base de pólizas supera la ventana de migración',           'Crítica', 'Abierto',   NULL, NULL),
  ( 4, 2, 'La ingeniera que conoce los servidores antiguos dejó el equipo', 'Alta', 'Abierto',   7,    NULL),
  ( 5, 2, 'Costos de nube sobre lo presupuestado',                       'Media',   'Mitigando', 13,   'Revisión semanal de consumo y límites por ambiente'),
  ( 6, 3, 'Las cifras no cuadran con contabilidad',                      'Alta',    'Mitigando', 10,   'Conciliación diaria con el equipo contable'),
  ( 7, 3, 'El cliente no ha nombrado quién recibirá el tablero',         'Media',   'Abierto',   NULL, NULL),
  ( 8, 4, 'Sin señal en parte de la faena',                              'Alta',    'Mitigando', 8,    'Modo sin conexión con sincronización posterior'),
  ( 9, 4, 'Equipos de terreno con celulares antiguos',                   'Media',   'Abierto',   7,    NULL),
  (10, 5, 'La clínica no entrega acceso a facturación',                  'Crítica', 'Abierto',   NULL, NULL),
  (11, 5, 'Proyecto sin avance a 20 días del plazo',                     'Alta',    'Abierto',   5,    NULL),
  (12, 6, 'Alertas en exceso generan fatiga en la guardia',              'Media',   'Abierto',   13,   'Partir solo con alertas de disponibilidad'),
  (13, 6, 'Dos sistemas de monitoreo en paralelo duplican costo',        'Baja',    'Abierto',   17,   'Fecha límite para dar de baja el anterior'),
  (14, 7, 'Líderes sin tiempo para ser tutores',                         'Media',   'Abierto',   18,   NULL),
  (15, 8, 'El cliente pidió alcance adicional sin ajustar el precio',    'Alta',    'Cerrado',   1,    'Se acordó una segunda etapa con presupuesto propio');

-- Los ids del seed son explícitos: dejar las secuencias después del último.
SELECT setval(pg_get_serial_sequence('equipos',     'equipo_id'),     (SELECT max(equipo_id)     FROM equipos));
SELECT setval(pg_get_serial_sequence('personas',    'persona_id'),    (SELECT max(persona_id)    FROM personas));
SELECT setval(pg_get_serial_sequence('proyectos',   'proyecto_id'),   (SELECT max(proyecto_id)   FROM proyectos));
SELECT setval(pg_get_serial_sequence('compromisos', 'compromiso_id'), (SELECT max(compromiso_id) FROM compromisos));
SELECT setval(pg_get_serial_sequence('riesgos',     'riesgo_id'),     (SELECT max(riesgo_id)     FROM riesgos));
