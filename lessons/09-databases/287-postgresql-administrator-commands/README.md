# 287 - PostgreSQL Administrator & User Commands

Este documento reúne comandos esenciales y administrativos para trabajar con PostgreSQL, desde operaciones básicas hasta tareas de administración y mantenimiento.

## Tabla de Contenidos
- [Comandos Básicos](#comandos-básicos)
  - [Crear Base de Datos](#crear-base-de-datos)
  - [Conectarse a una Base de Datos](#conectarse-a-una-base-de-datos)
  - [Crear Tabla](#crear-tabla)
  - [Insertar Datos](#insertar-datos)
  - [Consultar Datos](#consultar-datos)
  - [Actualizar Datos](#actualizar-datos)
  - [Eliminar Datos](#eliminar-datos)
  - [Eliminar Tabla](#eliminar-tabla)
  - [Desconectarse de la Base de Datos](#desconectarse-de-la-base-de-datos)
- [Comandos Administrativos](#comandos-administrativos)
  - [Crear Usuario](#crear-usuario)
  - [Conceder Privilegios](#conceder-privilegios)
  - [Revocar Privilegios](#revocar-privilegios)
  - [Cambiar Contraseña de Usuario](#cambiar-contraseña-de-usuario)
  - [Backup y Restore](#backup-y-restore)
  - [Ver Tamaño de Base de Datos](#ver-tamaño-de-base-de-datos)
  - [Ver Tamaño de Tabla](#ver-tamaño-de-tabla)
- [Recursos Adicionales](#recursos-adicionales)

---

## Comandos Básicos

### Crear Base de Datos

Para crear una nueva base de datos, utiliza el siguiente comando:

```sql
CREATE DATABASE database_name;
```

### Conectarse a una Base de Datos

Para conectarte a una base de datos, utiliza el siguiente comando:

```sql
\c database_name;
```

### Crear Tabla

Para crear una nueva tabla, utiliza el comando `CREATE TABLE`:

```sql
CREATE TABLE table_name (
  column1 datatype constraint,
  column2 datatype constraint,
  ...
);
```

Ejemplo:

```sql
CREATE TABLE users (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  age integer
);
```

### Insertar Datos

Para insertar datos en una tabla, utiliza el comando `INSERT INTO`:

```sql
INSERT INTO table_name (column1, column2, ...)
VALUES (value1, value2, ...);
```

Ejemplo:

```sql
INSERT INTO users (name, age)
VALUES ('John Doe', 30);
```

### Consultar Datos

Para recuperar datos de una tabla, utiliza el comando `SELECT`:

```sql
SELECT column1, column2, ...
FROM table_name
WHERE condition;
```

Ejemplo:

```sql
SELECT * FROM users;
```

### Actualizar Datos

Para actualizar datos existentes en una tabla, utiliza el comando `UPDATE`:

```sql
UPDATE table_name
SET column1 = value1, column2 = value2, ...
WHERE condition;
```

Ejemplo:

```sql
UPDATE users
SET age = 31
WHERE id = 1;
```

### Eliminar Datos

Para eliminar datos de una tabla, utiliza el comando `DELETE FROM`:

```sql
DELETE FROM table_name
WHERE condition;
```

Ejemplo:

```sql
DELETE FROM users
WHERE id = 1;
```

### Eliminar Tabla

Para eliminar una tabla, utiliza el comando `DROP TABLE`:

```sql
DROP TABLE table_name;
```

Ejemplo:

```sql
DROP TABLE users;
```

### Desconectarse de la Base de Datos

Para desconectarte de una base de datos, utiliza el siguiente comando:

```sql
\q
```

---

## Comandos Administrativos

### Crear Usuario

Para crear un nuevo usuario, utiliza el siguiente comando:

```sql
CREATE USER username WITH PASSWORD 'password';
```

### Conceder Privilegios

Para conceder privilegios a un usuario, utiliza el comando `GRANT`:

```sql
GRANT privileges ON table_name TO username;
```

Ejemplo:

```sql
GRANT ALL PRIVILEGES ON users TO john;
```

### Revocar Privilegios

Para revocar privilegios a un usuario, utiliza el comando `REVOKE`:

```sql
REVOKE privileges ON table_name FROM username;
```

Ejemplo:

```sql
REVOKE INSERT ON products FROM alice;
```

### Cambiar Contraseña de Usuario

Para cambiar la contraseña de un usuario, utiliza el siguiente comando:

```sql
ALTER USER username WITH PASSWORD 'new_password';
```

### Backup y Restore

- **Backup:**

```bash
pg_dump -U username -d database_name -f backup_file.sql
```

- **Restore:**

```bash
pg_restore -U username -d database_name backup_file.sql
```

### Ver Tamaño de Base de Datos

Para ver el tamaño de una base de datos, utiliza el siguiente comando:

```sql
SELECT pg_size_pretty(pg_database_size('database_name')) AS size;
```

### Ver Tamaño de Tabla

Para ver el tamaño de una tabla, utiliza el siguiente comando:

```sql
SELECT pg_size_pretty(pg_total_relation_size('table_name')) AS size;
```

---

## Recursos Adicionales

- [Documentación oficial de PostgreSQL](https://www.postgresql.org/docs/)
- [Comandos psql](https://www.postgresql.org/docs/current/app-psql.html)

> Nota: Algunos comandos administrativos requieren privilegios adecuados.