# n8n Docker Setup

Complete Docker setup for running n8n workflow automation platform with PostgreSQL database and HTTPS support.

## Features

- n8n workflow automation platform
- PostgreSQL 15 database for production use
- Traefik reverse proxy with automatic HTTPS
- Local data persistence with `./data` volume mount
- Custom domain support (n8n.devluchops.com)
- Docker Compose for easy orchestration

## Quick Start

### 1. Configure hosts file
Add this line to your `/etc/hosts` file:
```
127.0.0.1 n8n.devluchops.com
```

### 2. Start services
```bash
make up
```

### 3. Access n8n
Open: **https://n8n.devluchops.com**

### View logs
```bash
make logs
```

### Stop services
```bash
make down
```

## Docker Compose Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### Build and start
```bash
docker-compose up --build -d
```

## Data Persistence

- n8n data: `./data` directory (workflows, credentials, settings)
- PostgreSQL data: Docker volume `postgres_data`

## Database Configuration

- **Database**: PostgreSQL 15
- **Host**: postgres (internal)
- **Database**: n8n
- **User**: n8n
- **Password**: n8n123

## Environment Variables

- `N8N_HOST=0.0.0.0` - Host binding
- `N8N_PORT=5678` - Port number
- `N8N_PROTOCOL=http` - Protocol
- `N8N_USER_FOLDER=/home/n8n/.n8n` - Data directory
- `DB_TYPE=postgresdb` - Database type
- `DB_POSTGRESDB_HOST=postgres` - Database host
- `DB_POSTGRESDB_DATABASE=n8n` - Database name

## Available Make Commands

- `make help` - Show available commands
- `make build` - Build the Docker image
- `make up` - Start n8n and PostgreSQL services
- `make down` - Stop and remove containers
- `make stop` - Stop containers without removing
- `make clean` - Remove containers, images, and data
- `make logs` - Show container logs
- `make shell` - Open shell in running n8n container