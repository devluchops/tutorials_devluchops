from flask import Flask, request, jsonify, render_template_string
import sqlite3
import os
import subprocess
import hashlib

app = Flask(__name__)

# Vulnerable function for SAST testing - SQL Injection
def get_user_by_id(user_id):
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    # Vulnerable: Direct string concatenation (SQL Injection)
    query = f"SELECT * FROM users WHERE id = {user_id}"
    cursor.execute(query)
    result = cursor.fetchone()
    conn.close()
    return result

# Vulnerable function for SAST testing - Command Injection
@app.route('/ping')
def ping():
    host = request.args.get('host', 'localhost')
    # Vulnerable: Command injection
    result = subprocess.run(f"ping -c 1 {host}", shell=True, capture_output=True, text=True)
    return jsonify({"output": result.stdout})

# Vulnerable function for SAST testing - XSS
@app.route('/search')
def search():
    query = request.args.get('q', '')
    # Vulnerable: XSS
    template = f"""
    <html>
        <body>
            <h1>Search Results for: {query}</h1>
            <p>No results found</p>
        </body>
    </html>
    """
    return render_template_string(template)

# Vulnerable function - Path traversal
@app.route('/file')
def read_file():
    filename = request.args.get('name', '')
    # Vulnerable: Path traversal
    try:
        with open(f"files/{filename}", 'r') as f:
            return f.read()
    except FileNotFoundError:
        return "File not found"

# Hardcoded credentials (SAST will catch this)
DATABASE_PASSWORD = "admin123"
API_KEY = "sk-1234567890abcdef"

# Weak password hashing
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    # Vulnerable: Using MD5 for password hashing
    hashed_password = hashlib.md5(password.encode()).hexdigest()
    
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)", (username, hashed_password))
    conn.commit()
    conn.close()
    
    return jsonify({"message": "User registered"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/')
def home():
    return jsonify({"message": "Security Vulnerable App - For Testing Purposes Only"})

if __name__ == '__main__':
    # Initialize database
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS users 
                     (id INTEGER PRIMARY KEY, username TEXT, password TEXT)''')
    conn.commit()
    conn.close()
    
    # Vulnerable: Debug mode enabled in production
    app.run(host='0.0.0.0', port=5000, debug=True)