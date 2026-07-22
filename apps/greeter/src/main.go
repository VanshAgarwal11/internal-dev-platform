package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "dev"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from greeter v3 — FULLY automated! Version: %s\n", version)
	})

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	port := "8080"
	log.Printf("greeter starting on port %s (version %s)", port, version)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
