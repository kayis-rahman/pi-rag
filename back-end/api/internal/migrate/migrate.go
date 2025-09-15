package migrate

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"strings"
)

//go:embed sql/*.sql
var files embed.FS

// Run executes all embedded SQL files in lexical order
func Run(ctx context.Context, db *sql.DB) error {
	entries, err := files.ReadDir("sql")
	if err != nil {
		return err
	}
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".sql") {
			continue
		}
		b, err := files.ReadFile("sql/" + e.Name())
		if err != nil {
			return err
		}
		if _, err := db.ExecContext(ctx, string(b)); err != nil {
			return fmt.Errorf("migrate %s: %w", e.Name(), err)
		}
	}
	return nil
}
