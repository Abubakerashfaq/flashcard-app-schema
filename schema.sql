CREATE DATABASE flashcard_app;

USE flashcard_app;

CREATE TABLE User (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50),
  email VARCHAR(100),
  password VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Deck (
  deck_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  deck_name VARCHAR(100),
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Flashcard (
  flashcard_id INT AUTO_INCREMENT PRIMARY KEY,
  deck_id INT,
  front_text TEXT,
  back_text TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (deck_id) REFERENCES Deck(deck_id)
);

CREATE TABLE StudySession (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  deck_id INT,
  session_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  score INT,
  cards_studied INT,
  FOREIGN KEY (user_id) REFERENCES User(user_id),
  FOREIGN KEY (deck_id) REFERENCES Deck(deck_id)
);

-- Optional seed data
INSERT INTO User (username, email, password)
VALUES ('testuser', 'test@example.com', '1234');

INSERT INTO Deck (user_id, deck_name, description)
VALUES (1, 'Biology', 'Bio flashcards');

INSERT INTO Flashcard (deck_id, front_text, back_text)
VALUES (1, 'What is a cell', 'Basic unit of life');
