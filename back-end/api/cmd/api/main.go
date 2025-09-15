package main

import (
	"context"
	"log"
	nhttp "net/http"

	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"

	"github.com/kayis-rahman/time-beam/internal/config"
	"github.com/kayis-rahman/time-beam/internal/db"
	apphttp "github.com/kayis-rahman/time-beam/internal/http"
	"github.com/kayis-rahman/time-beam/internal/migrate"
)

func main() {
	_ = godotenv.Load()

	cfg := config.Load()
	dbconn, err := db.Connect(cfg)
	if err != nil { log.Fatal(err) }
	defer dbconn.Close()

	if err := migrate.Run(context.Background(), dbconn); err != nil { log.Fatal(err) }

	rdb := redis.NewClient(&redis.Options{Addr: cfg.RedisAddr, Password: cfg.RedisPass})
	defer rdb.Close()

	r := apphttp.NewRouterWithDeps(cfg, dbconn, rdb)
	addr := ":" + cfg.Port
	log.Println("server starting on", addr)
	if err := nhttp.ListenAndServe(addr, r); err != nil {
		log.Fatal(err)
	}
}
