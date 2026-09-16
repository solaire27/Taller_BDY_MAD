--problemática 1
DECLARE
    -- definicion del record
    TYPE t_ficha_postulante IS RECORD (
        nombre_completo  Candidatos.Nombre%TYPE,
        rut_candidato    Candidatos.Rut%TYPE,
        cargo_postulado  Cargos.Nombre_Cargo%TYPE,
        estado_actual    Estado.Tipo_Estado%TYPE,
        decision_final   Decision.Resultado%TYPE
    );
    -- variable basada en el record creado
    v_ficha t_ficha_postulante;
    -- variable de busqueda 
    v_id_entrevista_buscada NUMBER := 4;
BEGIN
    -- llenado del record
    -- se usa left join para cubrir si el candidato aún no tiene una decisión sobre contratación
    SELECT c.Nombre, 
           c.Rut, 
           car.Nombre_Cargo, 
           est.Tipo_Estado, 
           NVL(d.Resultado, 'Sin veredicto') -- Manejo de nulos
    INTO v_ficha.nombre_completo, 
         v_ficha.rut_candidato, 
         v_ficha.cargo_postulado, 
         v_ficha.estado_actual, 
         v_ficha.decision_final
    FROM Entrevista e
    JOIN Candidatos c ON e.Candidatos_Id = c.Id
    JOIN Cargos car ON e.Cargos_ID = car.ID
    JOIN Estado est ON e.Estado_ID = est.ID
    left JOIN Decision d ON e.Decision_ID = d.ID
    WHERE e.ID = v_id_entrevista_buscada;

    -- impresión de los datos del record
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('         FICHA DEL POSTULANTE       ');
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('Nombre  : ' || v_ficha.nombre_completo);
    DBMS_OUTPUT.PUT_LINE('RUT     : ' || v_ficha.rut_candidato);
    DBMS_OUTPUT.PUT_LINE('Cargo   : ' || v_ficha.cargo_postulado);
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Estado  : ' || v_ficha.estado_actual);
    DBMS_OUTPUT.PUT_LINE('Veredicto: ' || UPPER(v_ficha.decision_final));
    DBMS_OUTPUT.PUT_LINE('=========================================================');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró la entrevista ID ' || v_id_entrevista_buscada);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error técnico: ' || SQLERRM);
END;

--problemática 2
DECLARE
    -- varray que guardará las competencias asignadas por la ia del candidato
    TYPE t_arreglo_competencias IS VARRAY(3) OF VARCHAR2(100);
    
    -- se declara e inicializa la variable basada en ese tipo (vacía al inicio)
    v_top_competencias t_arreglo_competencias := t_arreglo_competencias();
    
    -- variables auxiliares
    v_nombre_candidato Candidatos.Nombre%TYPE;
    v_indice NUMBER := 1;
    
    -- variable para poder probar distintos IDs de entrevistas fácilmente
    v_id_entrevista_buscada NUMBER := 6;

    -- Cursor para obtener los  detalles de la que se quiera
    CURSOR c_detalles IS
        SELECT Nombre_Competencia, Puntaje_IA
        FROM Detalle_Competencias
        WHERE Entrevista_ID = v_id_entrevista_buscada; 

BEGIN
    -- se obtiene el nombre del candidato y se guarda en la variable
    SELECT c.Nombre INTO v_nombre_candidato
    FROM Candidatos c JOIN Entrevista e ON c.Id = e.Candidatos_Id
    WHERE e.ID = v_id_entrevista_buscada;

    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE(' RESUMEN CANDIDATO: ' || UPPER(v_nombre_candidato));
    DBMS_OUTPUT.PUT_LINE('=========================================================');

    -- Llenado del VARRAY
    FOR reg IN c_detalles LOOP
        -- Se extiende el tamaño del array en 1 espacio de memoria por cada iteración
        v_top_competencias.EXTEND;
        
        -- Se guarda el texto concatenado dentro de la posición actual del arreglo
        v_top_competencias(v_indice) := reg.Nombre_Competencia || ' (' || reg.Puntaje_IA || ' pts)';
        
        v_indice := v_indice + 1;
    END LOOP;

    -- Lectura del VARRAY 
    IF v_top_competencias.COUNT = 0 THEN --manejo de errores si se hizo entrevista pero no tiene competencias asignadas
        DBMS_OUTPUT.PUT_LINE('Atención: Este candidato aún no tiene competencias evaluadas por Copilot.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Competencias clave evaluadas por Copilot:');
        FOR i IN 1 .. v_top_competencias.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(' ' || i || '.- ' || v_top_competencias(i));--imprime cada elemento del varray
        END LOOP;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------');

EXCEPTION
    -- Captura si se ingresa un ID de entrevista que no existe
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR DE BÚSQUEDA: No existe ninguna entrevista registrada con el ID ' || v_id_entrevista_buscada);
        
    -- Captura si por error hay más de 3 competencias asignadas, por si copilot fallara, evitando que el VARRAY colapse
    WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
        DBMS_OUTPUT.PUT_LINE('ERROR DE CAPACIDAD: El candidato supera el límite máximo de competencias (3) permitidas.');
        
    -- Captura cualquier otra falla imprevista
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error desconocido: ' || SQLERRM);
END;

--problematica 3
DECLARE
    -- Cursor 1: Obtiene los estados de las entrevistas
    CURSOR c_estados IS 
        SELECT ID, Tipo_Estado 
        FROM Estado 
        ORDER BY ID ASC; 

    -- Cursor 2: Obtiene las entrevistas usando el cursor 1 como parametro
    CURSOR c_entrevistas(p_estado_id NUMBER) IS
        SELECT e.ID AS Entrevista_ID, 
               c.Nombre AS Nombre_Candidato, 
               car.Nombre_Cargo
        FROM Entrevista e 
        JOIN Candidatos c ON e.Candidatos_Id = c.Id
        JOIN Cargos car ON e.Cargos_ID = car.ID
        WHERE e.Estado_ID = p_estado_id;

    -- Cursor 3: Obtiene las competencias asignadas por la ia usando el cursor 2 como parámetro
    CURSOR c_detalles_ia(p_entrevista_id NUMBER) IS
        SELECT Nombre_Competencia, Puntaje_IA 
        FROM Detalle_Competencias
        WHERE Entrevista_ID = p_entrevista_id;
        
    v_candidatos_por_estado NUMBER; --para manejo de errores
    v_suma_puntajes         NUMBER;
    v_promedio              NUMBER(5,2);
    v_contador_comp         NUMBER;
    
    exc_estado_vacio EXCEPTION; --personalizada

BEGIN
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('      REPORTE DE CANDIDATOS AGRUPADOS POR ESTADO         ');
    DBMS_OUTPUT.PUT_LINE('=========================================================');

    -- loop principal (recorre Estados)
    FOR reg_estado IN c_estados LOOP
        DBMS_OUTPUT.PUT_LINE('>> REVISANDO ESTADO: ' || UPPER(reg_estado.Tipo_Estado) || ' <<');
        v_candidatos_por_estado := 0;
        -- Bloque anidado, si lo hacía con loops simples, cuando algún estado no tuviera entrevistas, el raise terminaba el código y no ejecutaba el resto
            Begin
            -- loop secundario (recorre Candidatos que tengan una entrevista con el estado que se esté iterando)
            FOR reg_entrevista IN c_entrevistas(reg_estado.ID) LOOP
                
                v_candidatos_por_estado := v_candidatos_por_estado + 1;
                DBMS_OUTPUT.PUT_LINE('   - Postulante: ' || reg_entrevista.Nombre_Candidato || ' (' || reg_entrevista.Nombre_Cargo || ')');
                
                -- Reinicio de variables para poder reutilizarlas en otros loops
                v_suma_puntajes := 0;
                v_contador_comp := 0;

                -- loop terciario (recorre competencias IA de la entrevista que se esté iterando)
                FOR reg_detalle IN c_detalles_ia(reg_entrevista.Entrevista_ID) LOOP
                    v_suma_puntajes := v_suma_puntajes + reg_detalle.Puntaje_IA;
                    v_contador_comp := v_contador_comp + 1;
                END LOOP;

                -- Cálculo de promedio matematico
                IF v_contador_comp = 3 THEN
                    v_promedio := v_suma_puntajes / 3;
                    DBMS_OUTPUT.PUT_LINE('     => PROMEDIO IA: ' || ROUND(v_promedio, 1) || ' pts.');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('     => Error: Evaluaciones incompletas.');
                END IF;
                
                DBMS_OUTPUT.PUT_LINE('   ......................................................');
                
            END LOOP;

            -- Por si no hay candidatos en el estado que se está iterando
            IF v_candidatos_por_estado = 0 THEN
                RAISE exc_estado_vacio; -- Gatillamos el error
            END IF;

        EXCEPTION
            WHEN exc_estado_vacio THEN
                DBMS_OUTPUT.PUT_LINE('   -> [ERROR DE NEGOCIO] No hay nadie actualmente con este estado.');
        END; 
        --fin del bloque anidado, pasa al siguiente loop
        
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------');
    END LOOP; 
    
    DBMS_OUTPUT.PUT_LINE('Reporte finalizado exitosamente.');
    
END;

--
