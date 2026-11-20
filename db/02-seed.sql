-- Datos de partida. Empresa ficticia "Aseguradora Los Aromos".
-- Todo es ficticio: la empresa, las personas, los RUT y los links.
--
-- Datos desactualizados a propósito, que se corrigen en la ronda 3:
--   Nota A: el link del portal termina en "siniestros-2025".
--   Nota B: el plazo de reembolso dice 60 días.
--
-- No se carga aquí:
--   - La nota "Cómo pedir un auto de reemplazo": se enseña en vivo (ronda 2).
--   - Sueldos y claves: los carga el presentador con cargar_ficha() (ver README).

INSERT INTO personas (persona_id, nombre, rut, cargo, rol) VALUES
  (1, 'Martín Soto',   '11.111.111-1', 'Analista de Siniestros (nuevo)',  'Siniestros'),
  (2, 'Camila Rojas',  '22.222.222-2', 'Analista senior de Siniestros',   'Siniestros'),
  (3, 'Diego Fuentes', '33.333.333-3', 'Ejecutivo comercial',             'Comercial'),
  (4, 'Paula Herrera', '44.444.444-4', 'Jefa de Personas',                'Personas');

INSERT INTO notas (nota_id, codigo, titulo, area, responsable, contenido) VALUES
(1, 'A', 'Cómo declarar un siniestro de auto', 'Siniestros', 'Camila Rojas',
$nota$# Cómo declarar un siniestro de auto
Responsable: Camila Rojas, Siniestros

1. El asegurado declara el siniestro en el portal: https://seguros-losaromos.example/siniestros-2025
2. Debe adjuntar: foto de su carnet, licencia de conducir, fotos del daño y la constancia de Carabineros si hubo terceros.
3. Tiene hasta 5 días hábiles desde el accidente para declararlo.
4. Siniestros revisa la declaración en 48 horas y asigna un liquidador.

Ver también: Nota B, Reembolso de gastos médicos.$nota$),

(2, 'B', 'Reembolso de gastos médicos (seguro de salud)', 'Siniestros', 'Camila Rojas',
$nota$# Reembolso de gastos médicos (seguro de salud)
Responsable: Camila Rojas, Siniestros

1. El asegurado envía la boleta o factura, la orden médica y el formulario de reembolso.
2. Plazo para pedir el reembolso: 60 días desde la atención.
3. Si el monto supera 20 UF, la solicitud pasa a revisión de la jefatura de Siniestros.
4. El pago se hace en 10 días hábiles a la cuenta registrada del asegurado.$nota$),

(3, 'C', 'Cómo contratar un seguro de hogar para un cliente nuevo', 'Comercial', 'Diego Fuentes',
$nota$# Cómo contratar un seguro de hogar para un cliente nuevo
Responsable: Diego Fuentes, Comercial

1. Pedir al cliente: carnet, dirección de la propiedad y si es dueño o arrendatario.
2. Cotizar en el cotizador interno con el valor de la propiedad.
3. Enviar la propuesta para firma digital.
4. La póliza parte el día hábil siguiente a la firma.$nota$),

(4, 'D', 'Vacaciones y revisión de sueldo', 'Personas', 'Paula Herrera',
$nota$# Vacaciones y revisión de sueldo
Responsable: Paula Herrera, Personas

- Vacaciones: se piden con 15 días de anticipación en el formulario de Personas y las aprueba la jefatura directa.
- Revisión de sueldo: se solicita por correo a personas@losaromos.example. Las revisiones se hacen en marzo y septiembre.
- Los sueldos de cada persona son confidenciales: cada uno ve solo el suyo.$nota$);

SELECT setval(pg_get_serial_sequence('personas', 'persona_id'), (SELECT max(persona_id) FROM personas));
SELECT setval(pg_get_serial_sequence('notas',    'nota_id'),    (SELECT max(nota_id)    FROM notas));
