package main

import (
	"log"
	"net/http"

	"blog/internal/handlers"

	"github.com/gorilla/mux"
)

// securityHeaders добавляет заголовки безопасности
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'")
		next.ServeHTTP(w, r)
	})
}

func main() {
	r := mux.NewRouter()

	r.HandleFunc("/api/posts", handlers.ListPosts).Methods("GET")
	r.HandleFunc("/api/posts/{slug}", handlers.GetPost).Methods("GET")

	// Статические файлы с ограничением только для dist
	distPath := "../frontend/dist"
	r.PathPrefix("/").Handler(http.FileServer(http.Dir(distPath)))

	// Применяем заголовки безопасности
	handler := securityHeaders(r)

	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", handler))
}
