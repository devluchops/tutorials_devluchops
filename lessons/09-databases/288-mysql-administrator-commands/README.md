# 288 - MySQL Administrator & User Commands

Este documento reúne comandos esenciales y administrativos para trabajar con MySQL, desde operaciones básicas hasta tareas de administración y mantenimiento.

## Tabla de Contenidos
- [Comandos Básicos](#comandos-básicos)
  - [Operaciones con Bases de Datos](#operaciones-con-bases-de-datos)
  - [Operaciones con Tablas](#operaciones-con-tablas)
  - [Manipulación de Datos](#manipulación-de-datos)
  - [Consultas de Datos](#consultas-de-datos)
  - [Agregación de Datos](#agregación-de-datos)
  - [Transacciones](#transacciones)
- [Comandos Administrativos](#comandos-administrativos)
  - [Variables y Estado](#variables-y-estado)
  - [Gestión de Usuarios y Privilegios](#gestión-de-usuarios-y-privilegios)
  - [Gestión de Bases de Datos y Tablas](#gestión-de-bases-de-datos-y-tablas)
  - [Tablespaces](#tablespaces)
  - [Mantenimiento y Optimización](#mantenimiento-y-optimizacion)
  - [Backup y Restore](#backup-y-restore)
  - [Replicación](#replicación)

---

## Comandos Básicos

### Operaciones con Bases de Datos
- `CREATE DATABASE database_name;` - Crear una nueva base de datos.
- `DROP DATABASE database_name;` - Eliminar una base de datos existente.
- `USE database_name;` - Seleccionar una base de datos para operaciones posteriores.
- `SHOW DATABASES;` - Listar todas las bases de datos disponibles.

### Operaciones con Tablas
- `CREATE TABLE table_name (column1 datatype, column2 datatype, ...);` - Crear una nueva tabla.
- `ALTER TABLE table_name ADD column_name datatype;` - Agregar una columna a una tabla existente.
- `ALTER TABLE table_name MODIFY column_name datatype;` - Modificar el tipo de dato de una columna.
- `ALTER TABLE table_name DROP COLUMN column_name;` - Eliminar una columna de una tabla.
- `DROP TABLE table_name;` - Eliminar una tabla existente.
- `SHOW TABLES;` - Listar todas las tablas de la base de datos actual.
- `DESCRIBE table_name;` o `DESC table_name;` - Ver la estructura de una tabla.

### Manipulación de Datos
- `INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...);` - Insertar una nueva fila en una tabla.
- `UPDATE table_name SET column_name = new_value WHERE condition;` - Modificar datos en una tabla existente.
- `DELETE FROM table_name WHERE condition;` - Eliminar datos de una tabla.

### Consultas de Datos
- `SELECT column1, column2, ... FROM table_name;` - Consultar todas las filas y columnas de una tabla.
- `SELECT * FROM table_name;` - Consultar todas las columnas de una tabla.
- `SELECT column1, column2, ... FROM table_name WHERE condition;` - Consultar filas específicas según una condición.
- `SELECT column1, column2, ... FROM table_name ORDER BY column_name;` - Consultar filas ordenadas por una columna.
- `SELECT column1, column2, ... FROM table_name LIMIT count;` - Consultar un número específico de filas.
- `SELECT column1, column2, ... FROM table_name JOIN another_table ON condition;` - Realizar un JOIN entre dos tablas.

### Agregación de Datos
- `SELECT COUNT(column_name) FROM table_name;` - Contar filas.
- `SELECT AVG(column_name) FROM table_name;` - Calcular el promedio de una columna.
- `SELECT SUM(column_name) FROM table_name;` - Calcular la suma de una columna.
- `SELECT MIN(column_name) FROM table_name;` - Valor mínimo de una columna.
- `SELECT MAX(column_name) FROM table_name;` - Valor máximo de una columna.
- `SELECT DISTINCT column_name FROM table_name;` - Valores únicos de una columna.

### Transacciones
- `START TRANSACTION;` - Iniciar una transacción.
- `COMMIT;` - Guardar los cambios de una transacción.
- `ROLLBACK;` - Descartar los cambios de una transacción.

---

## Comandos Administrativos

### Variables y Estado
- `SHOW VARIABLES;` - Mostrar variables de configuración del servidor.
- `SHOW STATUS;` - Mostrar información de estado del servidor.
- `SHOW PROCESSLIST;` - Ver procesos en ejecución.
- `KILL process_id;` - Terminar un proceso.
- `SET GLOBAL variable_name = value;` - Cambiar el valor de una variable global.
- `FLUSH PRIVILEGES;` - Recargar privilegios de usuario.

### Gestión de Usuarios y Privilegios
- `CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';` - Crear usuario.
- `DROP USER 'username'@'localhost';` - Eliminar usuario.
- `GRANT privileges ON database_name.table_name TO 'username'@'localhost';` - Conceder privilegios.
- `REVOKE privileges ON database_name.table_name FROM 'username'@'localhost';` - Revocar privilegios.
- `SHOW GRANTS FOR 'username'@'localhost';` - Ver privilegios de un usuario.
- `ALTER USER 'username'@'localhost' IDENTIFIED BY 'new_password';` - Cambiar contraseña.

### Gestión de Bases de Datos y Tablas
- `CREATE DATABASE database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;` - Crear base de datos con charset/collation.
- `ALTER DATABASE database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;` - Cambiar charset/collation.
- `DROP DATABASE database_name;` - Eliminar base de datos.

### Tablespaces
- `CREATE TABLESPACE tablespace_name ADD DATAFILE 'path/to/datafile.ibd';` - Crear tablespace y añadir datafile.
- `ALTER TABLESPACE tablespace_name ADD DATAFILE 'path/to/datafile.ibd';` - Añadir datafile a tablespace.
- `ALTER TABLESPACE tablespace_name DROP DATAFILE 'path/to/datafile.ibd';` - Eliminar datafile de tablespace.

### Mantenimiento y Optimización
- `SHOW TABLE STATUS;` - Información de tablas.
- `OPTIMIZE TABLE table_name;` - Optimizar tabla.
- `REPAIR TABLE table_name;` - Reparar tabla.
- `ANALYZE TABLE table_name;` - Analizar tabla para optimización.

### Backup y Restore
- `BACKUP DATABASE database_name TO 'path/to/backup_directory';` - Realizar backup (requiere herramientas externas).
- `RESTORE DATABASE database_name FROM 'path/to/backup_directory';` - Restaurar backup (requiere herramientas externas).
- `PURGE BINARY LOGS BEFORE 'yyyy-mm-dd hh:mm:ss';` - Eliminar logs binarios antiguos.

### Replicación
- `SHOW MASTER STATUS;` - Estado de logs binarios del master.
- `SHOW SLAVE STATUS;` - Estado de la replicación en el slave.
- `START SLAVE;` - Iniciar replicación en el slave.
- `STOP SLAVE;` - Detener replicación en el slave.
- `RESET SLAVE;` - Resetear configuración de replicación.

---

> Nota: Algunos comandos administrativos requieren privilegios adecuados y pueden variar según la versión de MySQL.

## Recursos
- [Documentación oficial de MySQL](https://dev.mysql.com/doc/)
- [Comandos MySQL](https://dev.mysql.com/doc/refman/8.0/en/sql-statements.html)
