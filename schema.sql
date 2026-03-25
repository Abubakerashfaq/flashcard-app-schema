CREATE DATABASE flashcard_app;

USE flashcard_app;

CREATE TABLE User (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Deck (
  deck_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  deck_name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

CREATE TABLE Flashcard (
  flashcard_id INT AUTO_INCREMENT PRIMARY KEY,
  deck_id INT NOT NULL,
  front_text TEXT NOT NULL,
  back_text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (deck_id) REFERENCES Deck(deck_id) ON DELETE CASCADE
);

CREATE TABLE StudySession (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  deck_id INT NOT NULL,
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

-- Helpful indexes for lookups
CREATE INDEX idx_deck_user ON Deck (user_id);
CREATE INDEX idx_flashcard_deck ON Flashcard (deck_id);
CREATE INDEX idx_session_user_deck ON StudySession (user_id, deck_id);
