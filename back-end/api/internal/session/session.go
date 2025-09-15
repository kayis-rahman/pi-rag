package session

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

type Service struct {
	db *sql.DB
}

func NewService(db *sql.DB) *Service { return &Service{db: db} }

func (s *Service) Start(ctx context.Context, userID int64, label string) (int64, error) {
	var existing int
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(1) FROM sessions WHERE user_id=$1 AND ended_at IS NULL`, userID).Scan(&existing)
	if err != nil { return 0, err }
	if existing > 0 { return 0, errors.New("active session exists") }
	var id int64
	err = s.db.QueryRowContext(ctx, `INSERT INTO sessions(user_id, label) VALUES($1,$2) RETURNING id`, userID, label).Scan(&id)
	return id, err
}

func (s *Service) Stop(ctx context.Context, userID int64) error {
	// find active
	var id int64
	var started time.Time
	err := s.db.QueryRowContext(ctx, `SELECT id, started_at FROM sessions WHERE user_id=$1 AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1`, userID).Scan(&id, &started)
	if err != nil { return err }
	dur := int(time.Since(started).Seconds())
	_, err = s.db.ExecContext(ctx, `UPDATE sessions SET ended_at=now(), duration_seconds=$1 WHERE id=$2`, dur, id)
	return err
}

func (s *Service) Active(ctx context.Context, userID int64) (bool, error) {
	var count int
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(1) FROM sessions WHERE user_id=$1 AND ended_at IS NULL`, userID).Scan(&count)
	return count > 0, err
}

func (s *Service) DailyStats(ctx context.Context, userID int64, day time.Time) (int, error) {
	start := time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, day.Location())
	end := start.Add(24 * time.Hour)
	var sum sql.NullInt64
	err := s.db.QueryRowContext(ctx, `SELECT COALESCE(SUM(duration_seconds),0) FROM sessions WHERE user_id=$1 AND started_at >= $2 AND started_at < $3`, userID, start, end).Scan(&sum)
	if err != nil { return 0, err }
	return int(sum.Int64), nil
}
