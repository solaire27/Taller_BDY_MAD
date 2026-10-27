-- specs publicos
CREATE OR REPLACE PACKAGE PKG_RRHH_SALMONERA IS

   -- variable publica 
    g_total_procesados NUMBER := 0;

    -- funcion: calcula el promedio del puntaje de la ia de un candidato especifico
    FUNCTION FN_CALCULAR_PROMEDIO_IA(p_entrevista_id IN NUMBER) RETURN NUMBER;

    -- procedimiento 1: genera reporte de los candidatos
    PROCEDURE PRC_GENERAR_REPORTE_ESTADOS;

    -- Procedimiento 2: inserta candidatos que superen x puntaje en la tabla nueva
    PROCEDURE PRC_ACTUALIZAR_POTENTIAL_MAN;

END PKG_RRHH_SALMONERA;
/
--cuerpo del paquete
CREATE OR REPLACE PACKAGE BODY PKG_RRHH_SALMONERA IS

    --valida que tenga sus 3 competencias antes de entregar el promedio
    FUNCTION FN_CALCULAR_PROMEDIO_IA(p_entrevista_id IN NUMBER) RETURN NUMBER IS
        CURSOR c_competencias IS
            SELECT Puntaje_IA 
            FROM Detalle_Competencias 
            WHERE Entrevista_ID = p_entrevista_id;
            
        v_suma NUMBER := 0;
        v_conteo NUMBER := 0;
        v_promedio NUMBER(5,2);
    BEGIN
        -- suma las competencias del candidato y maneja errores con nvl
        FOR reg IN c_competencias LOOP
            v_suma := v_suma + NVL(reg.Puntaje_IA, 0);
            v_conteo := v_conteo + 1;
        END LOOP;

        -- valida que haya 3 competencias
        IF v_conteo = 3 THEN
            v_promedio := v_suma / 3;
            RETURN ROUND(v_promedio, 2);
        ELSE
            --en cualquier otro caso, retorna -1
            RETURN -1;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN -1; -- Ante cualquier error tecnico, retorna -1
    END FN_CALCULAR_PROMEDIO_IA;

    -- Procedimiento 1: Utiliza cursores anidados para generar un informe de todos los candidatos, agrupados por su estado actual y mostrando su promedio.
    
    PROCEDURE PRC_GENERAR_REPORTE_ESTADOS IS
        --cursor de estados
        CURSOR c_estados IS 
            SELECT ID, Tipo_Estado 
            FROM Estado 
            ORDER BY ID ASC; 
        --cursor de entrevistas segun estado
        CURSOR c_entrevistas(p_estado_id NUMBER) IS
            SELECT e.ID AS Entrevista_ID, 
                   c.Nombre AS Nombre_Candidato, 
                   car.Nombre_Cargo
            FROM Entrevista e 
            JOIN Candidatos c ON e.Candidatos_Id = c.Id
            JOIN Cargos car ON e.Cargos_ID = car.ID
            WHERE e.Estado_ID = p_estado_id;
            
        v_candidatos_por_estado NUMBER;
        v_promedio_candidato NUMBER(5,2);
        exc_estado_vacio EXCEPTION;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=========================================================');
        DBMS_OUTPUT.PUT_LINE('      REPORTE DE CANDIDATOS AGRUPADOS POR ESTADO         ');
        DBMS_OUTPUT.PUT_LINE('=========================================================');

        FOR reg_estado IN c_estados LOOP
            DBMS_OUTPUT.PUT_LINE('ESTADO: ' || UPPER(reg_estado.Tipo_Estado) || '');
            v_candidatos_por_estado := 0;

            BEGIN -- Bloque anidado para proteger la ejecucion si un estado falla
                FOR reg_entrevista IN c_entrevistas(reg_estado.ID) LOOP
                    v_candidatos_por_estado := v_candidatos_por_estado + 1;
                    
                    -- Suma al contador publico
                    g_total_procesados := g_total_procesados + 1;
                    
                    DBMS_OUTPUT.PUT_LINE('   - Postulante: ' || reg_entrevista.Nombre_Candidato || ' (' || reg_entrevista.Nombre_Cargo || ')');
                    
                    -- llama a la funcion
                    v_promedio_candidato := FN_CALCULAR_PROMEDIO_IA(reg_entrevista.Entrevista_ID);
                    
                    IF v_promedio_candidato = -1 THEN
                        DBMS_OUTPUT.PUT_LINE('     => Error: Evaluaciones incompletas.');
                    ELSE
                        DBMS_OUTPUT.PUT_LINE('     => PROMEDIO IA: ' || v_promedio_candidato || ' pts.');
                    END IF;
                    DBMS_OUTPUT.PUT_LINE('   ......................................................');
                END LOOP;

                -- Lanzamos excepción si no hubo candidatos en este estado
                IF v_candidatos_por_estado = 0 THEN
                    RAISE exc_estado_vacio; 
                END IF;

            EXCEPTION
                WHEN exc_estado_vacio THEN
                    DBMS_OUTPUT.PUT_LINE('No hay nadie actualmente con este estado.');
            END; 
            DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------');
        END LOOP; 
        
        DBMS_OUTPUT.PUT_LINE('Total de candidatos procesados: ' || g_total_procesados);
    END PRC_GENERAR_REPORTE_ESTADOS;

    -- PROCEDIMIENTO 2: PRC_ACTUALIZAR_POTENTIAL_MAN
    -- Busca candidatos en estado "En Evaluación" (ID 2), calcula su 
    --            promedio IA y, si supera x pts, los inserta en una tabla de talento.
    
    PROCEDURE PRC_ACTUALIZAR_POTENTIAL_MAN IS
        CURSOR c_pendientes IS
            SELECT e.ID, c.Nombre, c.Correo
            FROM Entrevista e
            JOIN Candidatos c ON e.Candidatos_Id = c.Id
            WHERE e.Estado_ID = 2; -- "En Evaluación"
            
        v_promedio NUMBER(5,2);
        v_insertados NUMBER := 0;
        v_errores NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Iniciando evaluación masiva de talentos...');
        
        FOR reg IN c_pendientes LOOP
            --punto de guardado antes de insertar
            SAVEPOINT sp_antes_insert;
            
            BEGIN
                v_promedio := FN_CALCULAR_PROMEDIO_IA(reg.ID);
                
                IF v_promedio != -1 AND v_promedio >= 85 THEN -- se puede modificar el puntaje
                    INSERT INTO Candidatos_Potenciales (Entrevista_ID, Nombre, Correo, Promedio_IA)
                    VALUES (reg.ID, reg.Nombre, reg.Correo, v_promedio);
                    
                    v_insertados := v_insertados + 1;
                    DBMS_OUTPUT.PUT_LINE(' - Éxito: ' || reg.Nombre || ' registrado (' || v_promedio || ' pts)');
                END IF;
                
            EXCEPTION
                -- en caso de error, vuelve al savepoint pero continua el loop
                WHEN OTHERS THEN
                    ROLLBACK TO sp_antes_insert;
                    v_errores := v_errores + 1;
                    DBMS_OUTPUT.PUT_LINE(' - Fallo aislado en registro: ' || reg.Nombre || ': ' || SQLERRM);
            END;
        END LOOP;
        
        -- reporte
        COMMIT; 
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Proceso finalizado. Insertados: ' || v_insertados || ' | Errores omitidos: ' || v_errores);
        
    EXCEPTION
        -- por si falla el cursor
        WHEN OTHERS THEN
            ROLLBACK; 
            DBMS_OUTPUT.PUT_LINE('Error crítico a nivel de procedimiento: ' || SQLERRM);
    END PRC_ACTUALIZAR_POTENTIAL_MAN;

END PKG_RRHH_SALMONERA;
/ 

-- TRIGGER 1: CONTROL DE REGLA DE NEGOCIO (Validación antes de actualizar)
-- Bloquear el paso a estado "Completado" (ID 3) si el candidato no tiene exactamente 3 competencias evaluadas por Copilot.

CREATE OR REPLACE TRIGGER TRG_VALIDAR_EVALUACION
BEFORE UPDATE OF Estado_ID ON Entrevista
FOR EACH ROW
DECLARE
    v_total_procesados_competencias NUMBER;
BEGIN
    -- Si el usuario está intentando cambiar el estado a "Completado" (ID = 3)
    IF :NEW.Estado_ID = 3 THEN
        
        -- cuenta cuantas competencias tiene el candidato
        SELECT COUNT(*)
        INTO v_total_procesados_competencias
        FROM Detalle_Competencias
        WHERE Entrevista_ID = :NEW.ID;
        
        -- Si no tiene exactamente 3, cancela la actualización con un error 
        IF v_total_procesados_competencias != 3 THEN
            RAISE_APPLICATION_ERROR(-20001, 'REGLA DE NEGOCIO: No se puede finalizar la entrevista. El candidato debe tener exactamente 3 competencias evaluadas por IA.');
        END IF;
        
    END IF;
END;
/


-- TRIGGER 2: AUDITORÍA DE CONTRATACIONES
-- Registrar silenciosamente en una tabla anexa cada vez que un candidato recibe una Decisión (Contratado/Rechazado).
-- ============================================================================


CREATE OR REPLACE TRIGGER TRG_AUDITAR_DECISION
AFTER UPDATE OF Decision_ID ON Entrevista
FOR EACH ROW
BEGIN
    -- Solo audita si se le asignó una decisión válida (evitamos nulos)
    IF :NEW.Decision_ID IS NOT NULL AND :NEW.Decision_ID != NVL(:OLD.Decision_ID, -1) THEN
        
        INSERT INTO Auditoria_RRHH (Entrevista_ID, Usuario_BD, Decision_ID, Fecha_Hora)
        VALUES (:NEW.ID, USER, :NEW.Decision_ID, SYSTIMESTAMP);
        
    END IF;
END;
/
--tablas nuevas de la base de datos
CREATE TABLE Candidatos_Potenciales (Entrevista_ID NUMBER, Nombre VARCHAR2(100), Correo VARCHAR2(200), Promedio_IA NUMBER(5,2)); 

CREATE TABLE Auditoria_RRHH (ID_Auditoria NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, Entrevista_ID NUMBER, Usuario_BD VARCHAR2(50), Decision_ID NUMBER, Fecha_Hora TIMESTAMP);
/
--demostración de la función fuera del procedimiento
   SELECT 
    e.ID AS Entrevista_ID,
    c.Nombre AS Candidato,
    PKG_RRHH_SALMONERA.FN_CALCULAR_PROMEDIO_IA(e.ID) AS Promedio_Final
FROM Entrevista e
JOIN Candidatos c ON e.Candidatos_Id = c.Id;
/
BEGIN
    -- Llamamos al procedimiento dentro del paquete
    PKG_RRHH_SALMONERA.PRC_GENERAR_REPORTE_ESTADOS;
END;
/
-- Forzamos el error de validación
UPDATE Entrevista 
SET Estado_ID = 3 
WHERE ID = 3;

BEGIN
    PKG_RRHH_SALMONERA.PRC_ACTUALIZAR_POTENTIAL_MAN;
END;
/

-- Comprobamos físicamente en la tabla
SELECT * FROM Candidatos_Potenciales;

-- Gerencia actualiza el dato
UPDATE Entrevista 
SET Decision_ID = 2 
WHERE ID = 1;
COMMIT;

-- Revisamos la tabla espía
SELECT * FROM Auditoria_RRHH;
