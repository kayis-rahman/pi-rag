package main

import (
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"

	apphttp "github.com/kayis-rahman/time-beam/internal/http"
)

func main() {
	_ = godotenv.Load()

	r := apphttp.NewRouter()
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	addr := ":" + port
	log.Println("server starting on", addr)
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatal(err)
	}
}
