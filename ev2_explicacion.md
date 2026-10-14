Paquete: PKG_RRHH_SALMONERA (Procedimientos)
PRC_GENERAR_REPORTE_ESTADOS (Reporte Masivo):
Recorre toda la base de datos utilizando cursores anidados (jerarquía: Estado > Entrevista > Competencias). Su objetivo es imprimir en consola un informe ordenado de todos los postulantes, mostrando en qué estado se encuentran y calculando su promedio de IA. Si un estado no tiene postulantes, arroja una alerta controlada.

PRC_ACTUALIZAR_POTENTIAL_MAN:
Busca a los candidatos que están "En Evaluación". Utiliza la función matemática para calcular su promedio y, si obtienen 85 puntos o más, los inserta automáticamente en la tabla VIP Candidatos_Potenciales. Utiliza un control de errores con SAVEPOINT para asegurar que si un candidato falla al insertarse, el resto de los candidatos aprobados se guarden con éxito sin interrumpir el proceso.

Triggers
TRG_VALIDAR_EVALUACION (Protector de Reglas de Negocio):
Se dispara ANTES (BEFORE UPDATE) de que alguien cambie el estado de una entrevista. Es una barrera de seguridad: si un analista intenta pasar a un candidato al estado "Completado" (ID 3), el trigger cuenta sus evaluaciones. Si el candidato no tiene exactamente 3 competencias asignadas por la IA, el trigger aborta la actualización y lanza un error rojo crítico (ORA-20001), obligando a completar el proceso primero.

TRG_AUDITAR_DECISION (Auditoría):
Se dispara DESPUÉS (AFTER UPDATE) de que se le asigne una Decisión final a un candidato (Contratado o Rechazado). Trabaja de forma silenciosa en segundo plano: captura el ID de la entrevista, el nombre del usuario de la base de datos que hizo el cambio y la fecha/hora exacta (SYSTIMESTAMP), guardando esta evidencia en la tabla histórica Auditoria_RRHH para fines de transparencia.

Pendiente a posibles correcciones en el código
