// greeter is a minimal HTTP service used to exercise the platform's CI/CD path:
// source -> image build -> registry -> GitOps deploy -> running pod.
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	// APP_VERSION makes the running build visible at runtime. Without it there's no
	// way to tell from outside the cluster which image a pod is actually serving,
	// which makes verifying a deploy guesswork.
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "dev"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from greeter v3 — FULLY automated! Version: %s\n", version)
	})

	// Liveness/readiness endpoint. The Deployment's readinessProbe polls this, so
	// Kubernetes only sends traffic once the process is actually up and serving.
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	port := "8080"
	log.Printf("greeter starting on port %s (version %s)", port, version)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}