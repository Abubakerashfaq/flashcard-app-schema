-- SQLite-compatible schema for Flashcard App
-- Converted from MySQL; column names match app.py

CREATE TABLE IF NOT EXISTS user (
    user_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT NOT NULL UNIQUE,
    email      TEXT NOT NULL UNIQUE,
    password   TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS deck (
    deck_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    deck_name   TEXT NOT NULL,
    description TEXT,
    color       TEXT DEFAULT '#2563eb',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS flashcard (
    flashcard_id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id      INTEGER NOT NULL,
    front_text   TEXT NOT NULL,
    back_text    TEXT NOT NULL,
    hint         TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deck_id) REFERENCES deck(deck_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tag (
    tag_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS flashcard_tag (
    flashcard_id INTEGER NOT NULL,
    tag_id       INTEGER NOT NULL,
    PRIMARY KEY (flashcard_id, tag_id),
    FOREIGN KEY (flashcard_id) REFERENCES flashcard(flashcard_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tag(tag_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS study_session (
    session_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL,
    deck_id       INTEGER NOT NULL,
    session_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    score         INTEGER DEFAULT 0,
    cards_studied INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (deck_id) REFERENCES deck(deck_id) ON DELETE CASCADE,
    CHECK (score BETWEEN 0 AND 100),
    CHECK (cards_studied >= 0)
);

CREATE TABLE IF NOT EXISTS study_log (
    log_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id       INTEGER,
    user_id          INTEGER NOT NULL,
    flashcard_id     INTEGER NOT NULL,
    studied_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result           TEXT NOT NULL CHECK (result IN ('correct', 'incorrect', 'skipped')),
    response_time_ms INTEGER,
    FOREIGN KEY (session_id) REFERENCES study_session(session_id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (flashcard_id) REFERENCES flashcard(flashcard_id) ON DELETE CASCADE,
    CHECK (response_time_ms IS NULL OR response_time_ms >= 0)
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_deck_user ON deck(user_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_deck ON flashcard(deck_id);
CREATE INDEX IF NOT EXISTS idx_session_user_deck ON study_session(user_id, deck_id);
CREATE INDEX IF NOT EXISTS idx_session_date ON study_session(session_date);
CREATE INDEX IF NOT EXISTS idx_tag_name ON tag(name);
CREATE INDEX IF NOT EXISTS idx_flashcardtag_tag ON flashcard_tag(tag_id);
CREATE INDEX IF NOT EXISTS idx_studylog_user_card_time ON study_log(user_id, flashcard_id, studied_at);
CREATE INDEX IF NOT EXISTS idx_studylog_session ON study_log(session_id);
