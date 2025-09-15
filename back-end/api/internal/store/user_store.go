package store

import (
	"context"
	"database/sql"
)

type User struct {
	ID           int64
	Email        string
	PasswordHash string
}

type UserStore struct{ db *sql.DB }

func NewUserStore(db *sql.DB) *UserStore { return &UserStore{db: db} }

func (s *UserStore) Create(ctx context.Context, email, passwordHash string) (int64, error) {
	var id int64
	err := s.db.QueryRowContext(ctx, `INSERT INTO users(email, password_hash) VALUES($1,$2) RETURNING id`, email, passwordHash).Scan(&id)
	return id, err
}

func (s *UserStore) GetByEmail(ctx context.Context, email string) (*User, error) {
	u := &User{}
	err := s.db.QueryRowContext(ctx, `SELECT id, email, password_hash FROM users WHERE email=$1`, email).Scan(&u.ID, &u.Email, &u.PasswordHash)
	if err != nil {
		return nil, err
	}
	return u, nil
}

func (s *UserStore) GetByID(ctx context.Context, id int64) (*User, error) {
	u := &User{}
	err := s.db.QueryRowContext(ctx, `SELECT id, email, password_hash FROM users WHERE id=$1`, id).Scan(&u.ID, &u.Email, &u.PasswordHash)
	if err != nil {
		return nil, err
	}
	return u, nil
}
