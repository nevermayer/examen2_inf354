CREATE PROCEDURE CompararPalabras
    @palabra1 NVARCHAR(20),
    @palabra2 NVARCHAR(20),
    @nombreTabla NVARCHAR(128) 
AS
BEGIN
    DECLARE
        @longitud1 INT,
        @longitud2 INT,
        @posicion INT,
        @letra NVARCHAR(2),
        @contador INT,
        @sql NVARCHAR(2000),
        @columna NVARCHAR(4),
        @contar INT

    -- Obtener longitudes de las palabras
    SET @longitud1 = LEN(@palabra1)
    SET @longitud2 = LEN(@palabra2)

    -- Crear la tabla basada en el nombre proporcionado
    SET @posicion = 1
    SET @sql = 'CREATE TABLE ' + QUOTENAME(@nombreTabla) + ' (' -- Use QUOTENAME para evitar problemas con nombres de tabla

    WHILE @posicion <= @longitud1
    BEGIN
        SET @letra = LEFT(@palabra1, 1)
        SET @palabra1 = RIGHT(@palabra1, LEN(@palabra1)-1)
        SET @sql = @sql + @letra + CAST(@posicion AS NVARCHAR) + ' INT, '
        SET @posicion = @posicion + 1
    END

    SET @sql = LEFT(@sql, LEN(@sql)-1) + ')'
    PRINT @sql
    EXEC sp_executesql @sql

    -- Insertar valores en la tabla basada en la segunda palabra
    SET @posicion = 1
    WHILE @posicion <= @longitud2
    BEGIN
        SET @letra = LEFT(@palabra2, 1)
        SET @palabra2 = RIGHT(@palabra2, LEN(@palabra2)-1)
        SET @contar = 0

        SELECT @contar = COUNT(*)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = @nombreTabla
          AND LEFT(COLUMN_NAME, 1) = @letra
          AND ORDINAL_POSITION <= @posicion 

        IF @contar > 0
        BEGIN 
            SELECT TOP 1 @columna = COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = @nombreTabla
              AND LEFT(COLUMN_NAME, 1) = @letra
              AND ORDINAL_POSITION >= @posicion 

            SET @sql = 'INSERT INTO ' + QUOTENAME(@nombreTabla) + ' (' + @columna + ') VALUES (1)'
            EXEC sp_executesql @sql
        END 

        SET @posicion = @posicion + 1
    END

    -- Construir la consulta final
    SET @sql = 'SELECT '
    SELECT @contar = COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @nombreTabla

    SET @posicion = 1
    WHILE @posicion <= @contar
    BEGIN
        SELECT @columna = COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = @nombreTabla AND ORDINAL_POSITION = @posicion

        SET @sql = @sql + 'SUM(ISNULL(' + @columna + ', 0)) + '
        SET @posicion = @posicion + 1
    END

    SET @sql = LEFT(@sql, LEN(@sql)-1) + ' FROM ' + QUOTENAME(@nombreTabla)
    EXEC sp_executesql @sql
END;

-- Ejecutar
EXEC CompararPalabras 'jorgeluis', 'jougeluis', 'polo'