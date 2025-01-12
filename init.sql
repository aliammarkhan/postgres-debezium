CREATE TABLE IF NOT EXISTS Student (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    age INT NOT NULL,
    address TEXT,
    create_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);