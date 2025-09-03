# MongoDB Docker Setup

This directory contains a MongoDB Docker setup that allows you to run MongoDB locally and access it from your Mac.

## Quick Start

1. Start MongoDB:
   ```bash
   cd mongodb
   docker-compose up -d
   ```

2. Connect to MongoDB:
   - **Host**: localhost
   - **Port**: 27017
   - **Username**: admin
   - **Password**: password123
   - **Database**: myapp

## Connection Examples

### MongoDB Compass (GUI)
Connection string: `mongodb://admin:password123@localhost:27017/myapp`

### MongoDB Shell
```bash
mongosh "mongodb://admin:password123@localhost:27017/myapp"
```

### Application Connection
```javascript
// Node.js example
const mongoUrl = 'mongodb://admin:password123@localhost:27017/myapp';
```

## Commands

- **Start**: `docker-compose up -d`
- **Stop**: `docker-compose down`
- **View logs**: `docker-compose logs -f`
- **Remove data**: `docker-compose down -v`

## Features

- MongoDB 7.0
- Persistent data storage
- Root user authentication
- Sample initialization data
- Accessible from localhost on port 27017