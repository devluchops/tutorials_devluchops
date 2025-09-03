// Initialize database with sample data
db = db.getSiblingDB('myapp');

// Create a sample collection with some data
db.users.insertMany([
  {
    name: "John Doe",
    email: "john@example.com",
    createdAt: new Date()
  },
  {
    name: "Jane Smith", 
    email: "jane@example.com",
    createdAt: new Date()
  }
]);

print("Database initialized with sample data");