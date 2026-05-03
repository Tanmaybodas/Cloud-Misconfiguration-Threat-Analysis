-- Intentional lab fixture for insecure object storage testing.
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email VARCHAR(255),
  password_hash VARCHAR(255)
);

INSERT INTO users VALUES
  (1, 'student@example.com', 'not-a-real-hash'),
  (2, 'developer@example.com', 'not-a-real-hash');
