-- TechStore | SQL Server | 99: Reinicio para DESARROLLO
-- ¡DESTRUCTIVO! Elimina la base de datos TechStore completa. Úsalo solo en tu máquina
-- local para volver a ejecutar los scripts 00 a 08 desde cero.
USE master;
GO
IF DB_ID('TechStore') IS NOT NULL
BEGIN
    ALTER DATABASE TechStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TechStore;
END
GO
