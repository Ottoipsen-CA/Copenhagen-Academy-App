-- Migration script to create the challenge_results table.
-- Execute this with:
-- sqlite3 football_academy.db < migrations/create_challenge_results_table.py

DROP TABLE IF EXISTS challenge_results;

CREATE TABLE challenge_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    completion_id INTEGER NOT NULL,
    result_value FLOAT NOT NULL,
    notes TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (completion_id) REFERENCES challenge_completions (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_challenge_results_completion_id ON challenge_results (completion_id);
