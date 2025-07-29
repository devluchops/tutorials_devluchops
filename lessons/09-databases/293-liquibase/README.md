# Liquibase Command Reference

Liquibase is an open-source database schema migration tool that provides version control for your database changes. This README file serves as a reference guide for the Liquibase commands along with examples to help you get started.

## Installation

To use Liquibase, you need to have Java installed on your system. You can download the latest version of Liquibase from the official website: [https://www.liquibase.org/](https://www.liquibase.org/)

## Usage

Once you have Liquibase installed, you can use it through the command line or integrate it into your build process using build tools such as Maven or Gradle.

### Command Line Usage

To execute Liquibase commands via the command line, use the following syntax:

```
liquibase [command] [command options]
```


Now let's dive into the various Liquibase commands along with their options and examples.

## Commands

### 1. `migrate`

The `migrate` command updates the database to the latest available version.

```
liquibase migrate [command options]

```


Options:

- `--changeLogFile=[path]`: Specifies the changelog file to use (default: `changelog.xml`).
- `--contexts=[contexts]`: Specifies the runtime contexts to use.
- `--labels=[labels]`: Specifies the labels to include or exclude.
- `--tag=[tag]`: Executes changes up to the given tag.
- `--rollbackTag=[tag]`: Rolls back changes to the given tag.

Example:

```
liquibase migrate
```


### 2. `update`

The `update` command deploys changes to the database without rolling back previously deployed changes.

```
liquibase update [command options]
```


Options:

- `--changeLogFile=[path]`: Specifies the changelog file to use (default: `changelog.xml`).
- `--contexts=[contexts]`: Specifies the runtime contexts to use.
- `--labels=[labels]`: Specifies the labels to include or exclude.
- `--tag=[tag]`: Executes changes up to the given tag.

Example:

```
liquibase update
```


### 3. `rollback`

The `rollback` command rolls back the database to a previous state based on the number of changesets or a specific tag.

```
liquibase rollback [command options]
```

Options:

- `--changeLogFile=[path]`: Specifies the changelog file to use (default: `changelog.xml`).
- `--rollbackCount=[count]`: Rolls back the specified number of changesets.
- `--rollbackTag=[tag]`: Rolls back changes to the given tag.
- `--contexts=[contexts]`: Specifies the runtime contexts to use.

Example:

```
liquibase rollback --rollbackCount=1
```

### 4. `status`

The `status` command displays the current status of the database, showing which changesets have been applied.

```
liquibase status [command options]
```

Options:

- `--changeLogFile=[path]`: Specifies the changelog file to use (default: `changelog.xml`).
- `--verbose`: Displays detailed output.

Example:

```
liquibase status [command options]
```

Options:

- `--changeLogFile=[path]`: Specifies the changelog file to use (default: `changelog.xml`).
- `--verbose`: Displays detailed output.

Example:


```
liquibase status
```

### 5. `generateChangeLog`

The `generateChangeLog` command creates a new changelog file by comparing the current database state with an existing one.

```
liquibase generateChangeLog [command options]
```

Options:

- `--changeLogFile=[path]`: Specifies the output changelog file to create.
- `--diffTypes=[types]`: Specifies the types of objects to compare (e.g., tables, views, procedures
