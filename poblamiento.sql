-- =============================================================================
-- SCRIPT DE REINICIO 
-- =============================================================================
BEGIN
    -- 0. APAGAR EL TRIGGER TEMPORALMENTE (Modo Mantenimiento)
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_VALIDAR_EVALUACION DISABLE';
    DBMS_OUTPUT.PUT_LINE('Trigger de validación desactivado temporalmente.');

    -- 1. Vaciar las tablas de resultados
    EXECUTE IMMEDIATE 'TRUNCATE TABLE Candidatos_Potenciales';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE Auditoria_RRHH';
    DBMS_OUTPUT.PUT_LINE('Tablas de resultados y auditoría limpiadas.');

    -- 2. Borrar los candidatos de prueba (IDs del 4 en adelante)
    DELETE FROM Detalle_Competencias WHERE Entrevista_ID >= 4;
    DELETE FROM Entrevista WHERE ID >= 4;
    DELETE FROM Candidatos WHERE ID >= 4;
    DBMS_OUTPUT.PUT_LINE('Candidatos de prueba masiva eliminados.');

    -- 3. Restaurar a los 3 candidatos originales
    UPDATE Entrevista SET Estado_ID = 3, Decision_ID = 1 WHERE ID = 1;
    UPDATE Entrevista SET Estado_ID = 2, Decision_ID = NULL WHERE ID = 2;
    UPDATE Entrevista SET Estado_ID = 3, Decision_ID = 2 WHERE ID = 3;
    DBMS_OUTPUT.PUT_LINE('Los 3 candidatos originales han sido restaurados.');

    -- 4. ENCENDER EL TRIGGER NUEVAMENTE (Seguridad activada)
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_VALIDAR_EVALUACION ENABLE';
    DBMS_OUTPUT.PUT_LINE('Trigger de validación reactivado.');

    -- 5. Guardar los cambios
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('✅ Base de datos reiniciada. Lista para la presentación.');
    DBMS_OUTPUT.PUT_LINE('=========================================================');
END;

/

-- =============================================================================
-- 5. SCRIPT DE POBLAMIENTO MASIVO (DATA SEEDER PL/SQL)
-- =============================================================================
DECLARE
    v_id_detalle NUMBER := 9; 
    v_nombre VARCHAR2(100);
    v_rut VARCHAR2(13);
    v_cargo NUMBER;
    v_estado NUMBER;
    v_decision NUMBER;
    v_nota1 NUMBER;
    v_nota2 NUMBER;
    v_nota3 NUMBER;
    
    TYPE t_nombres IS VARRAY(10) OF VARCHAR2(50);
    TYPE t_apellidos IS VARRAY(10) OF VARCHAR2(50);
    
    nombres t_nombres := t_nombres('Javiera', 'Andrés', 'Camila', 'Sebastián', 'Valentina', 'Felipe', 'Constanza', 'Nicolás', 'Antonia', 'Diego');
    apellidos t_apellidos := t_apellidos('Pérez', 'Rojas', 'Soto', 'Gómez', 'Silva', 'Díaz', 'Muñoz', 'Morales', 'Tapia', 'Herrera');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando poblamiento de 50 candidatos (IDs 4 al 53)...');
    
    FOR i IN 4..53 LOOP
        -- 1. Generación de identidad
        v_nombre := nombres(MOD(i, 10) + 1) || ' ' || apellidos(MOD(i * 3, 10) + 1);
        v_rut := TO_CHAR(15000000 + (i*1234)) || '-' || TO_CHAR(MOD(i, 9));
        
        -- Inserción del Candidato
        INSERT INTO Candidatos (Id, Nombre, Link_CV, Link_formulario, Rut, Correo, Telefono, Direccion) 
        VALUES (i, v_nombre, 'cloud.com/cv_'||i||'.pdf', 'forms.com/r/resp'||i, v_rut, 'cand_'||i||'@salmonera.cl', '987654'||TO_CHAR(i,'FM000'), 'Av. Sede Central '||i);

        -- 2. Variables dinámicas para la entrevista
        v_cargo := MOD(i, 4) + 1;  
        v_estado := MOD(i, 3) + 1; 
        
        IF v_estado = 3 THEN
            v_decision := MOD(i, 2) + 1;
        ELSE
            v_decision := NULL;
        END IF;

        -- Inserción de la Entrevista (CORREGIDA LA FECHA CON PARÉNTESIS)
        INSERT INTO Entrevista (ID, Fecha, Candidatos_Id, Estado_ID, Cargos_ID, Decision_ID, Psicologo_Id, Link_Informe, Link_Pauta, Link_Entrevista, Sede_ID) 
        VALUES (i, TO_TIMESTAMP('2026-10-0' || (MOD(i,9) + 1) || ' 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), i, v_estado, v_cargo, v_decision, MOD(i, 2) + 1, NULL, NULL, NULL, MOD(i, 3) + 1);

        -- 3. Generación de puntajes matemáticos
        v_nota1 := 60 + MOD(i*7, 40); 
        v_nota2 := 65 + MOD(i*11, 35);
        v_nota3 := 70 + MOD(i*13, 30);
        
        IF v_estado = 2 THEN 
            v_nota1 := 95; v_nota2 := 90; v_nota3 := 98;
        END IF;

        -- Inserción de los Detalles de Competencia
        INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
        VALUES (v_id_detalle, i, 'Habilidad Técnica', v_nota1, 'Procesamiento IA correcto.');
        v_id_detalle := v_id_detalle + 1;

        INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
        VALUES (v_id_detalle, i, 'Trabajo en Equipo', v_nota2, 'Análisis de lenguaje corporal positivo.');
        v_id_detalle := v_id_detalle + 1;

        IF i != 15 THEN
            INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
            VALUES (v_id_detalle, i, 'Adaptabilidad', v_nota3, 'Respuestas estructuradas bajo estrés.');
            v_id_detalle := v_id_detalle + 1;
        END IF;

    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('✅ 50 Candidatos, Entrevistas y Competencias insertados.');
    DBMS_OUTPUT.PUT_LINE('=========================================================');
END;
/
