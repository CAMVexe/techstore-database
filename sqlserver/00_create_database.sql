-- TechStore | SQL Server | 00: Crear la base de datos
-- Requiere SQL Server 2016 SP1 o superior (se usa CREATE OR ALTER).
IF DB_ID('TechStore') IS NULL
    CREATE DATABASE TechStore;
GO
