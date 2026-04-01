CREATE DATABASE flashcard_app;

USE flashcard_app;

CREATE TABLE User (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_user_username UNIQUE (username)
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

CREATE TABLE Tag (
  tag_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE FlashcardTag (
  flashcard_id INT NOT NULL,
  tag_id INT NOT NULL,
  PRIMARY KEY (flashcard_id, tag_id),
  FOREIGN KEY (flashcard_id) REFERENCES Flashcard(flashcard_id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES Tag(tag_id) ON DELETE CASCADE
);

CREATE TABLE StudySession (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  deck_id INT NOT NULL,
  session_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  score INT,
  cards_studied INT,
  FOREIGN KEY (user_id) REFERENCES User(user_id),
  FOREIGN KEY (deck_id) REFERENCES Deck(deck_id),
  CONSTRAINT chk_score CHECK (score BETWEEN 0 AND 100),
  CONSTRAINT chk_cards_studied CHECK (cards_studied >= 0)
);

CREATE TABLE StudyLog (
  log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  flashcard_id INT NOT NULL,
  studied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  result ENUM('correct', 'incorrect', 'skipped') NOT NULL,
  response_time_ms INT,
  FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
  FOREIGN KEY (flashcard_id) REFERENCES Flashcard(flashcard_id) ON DELETE CASCADE,
  CONSTRAINT chk_response_time_ms CHECK (response_time_ms IS NULL OR response_time_ms >= 0)
);

-- Optional seed data
INSERT INTO User (username, email, password)
VALUES ('testuser', 'test@example.com', '1234');

INSERT INTO Deck (user_id, deck_name, description)
VALUES (1, 'Biology', 'Bio flashcards');

INSERT INTO Flashcard (deck_id, front_text, back_text)
VALUES (1, 'What is a cell', 'Basic unit of life');

INSERT INTO Tag (name) VALUES ('biology'), ('cells');
INSERT INTO FlashcardTag (flashcard_id, tag_id)
SELECT f.flashcard_id, t.tag_id
FROM Flashcard f
CROSS JOIN Tag t
WHERE f.deck_id = 1
  AND t.name IN ('biology', 'cells');

INSERT INTO StudyLog (user_id, flashcard_id, result, response_time_ms)
VALUES (1, 1, 'correct', 1500);

-- Helpful indexes for lookups
CREATE INDEX idx_deck_user ON Deck (user_id);
CREATE INDEX idx_flashcard_deck ON Flashcard (deck_id);
CREATE INDEX idx_session_user_deck ON StudySession (user_id, deck_id);
CREATE INDEX idx_session_date ON StudySession (session_date);
CREATE INDEX idx_tag_name ON Tag (name);
CREATE INDEX idx_flashcardtag_tag ON FlashcardTag (tag_id);
CREATE INDEX idx_studylog_user_card_time ON StudyLog (user_id, flashcard_id, studied_at);

-- Lightweight test cases (safe to run)
-- 1) Add another user and deck with a couple cards
INSERT INTO User (username, email, password)
VALUES ('alice', 'alice@example.com', 'secret');

INSERT INTO Deck (user_id, deck_name, description)
VALUES (2, 'Chemistry', 'Basic chemistry facts');

INSERT INTO Flashcard (deck_id, front_text, back_text)
VALUES
  (2, 'What is an atom?', 'Smallest unit of matter'),
  (2, 'Symbol for water?', 'H2O');

-- 2) Record a study session for the original deck
INSERT INTO StudySession (user_id, deck_id, score, cards_studied)
VALUES (1, 1, 90, 10);

-- 3) Verify cascade: deleting the Chemistry deck removes its flashcards
DELETE FROM Deck WHERE deck_id = 2;
SELECT COUNT(*) AS flashcards_remaining_for_deleted_deck
FROM Flashcard WHERE deck_id = 2;
