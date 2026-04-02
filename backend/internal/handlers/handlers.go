package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/yuin/goldmark"
)

type Post struct {
	Slug     string `json:"slug"`
	Title    string `json:"title"`
	Date     string `json:"date"`
	Category string `json:"category"`
	Content  string `json:"content,omitempty"`
}

var postsDir = "./posts"

// validSlug проверяет, что slug содержит только безопасные символы
var validSlug = regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)

func ListPosts(w http.ResponseWriter, r *http.Request) {
	posts, err := listAllPosts()
	if err != nil {
		log.Printf("Error listing posts: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(posts)
}

func GetPost(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	slug := vars["slug"]

	// Проверка на path traversal и недопустимые символы
	if !isValidSlug(slug) {
		http.Error(w, "Invalid post slug", http.StatusBadRequest)
		return
	}

	post, err := getPostBySlug(slug)
	if err != nil {
		http.Error(w, "Post not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(post)
}

// isValidSlug проверяет slug на допустимые символы и отсутствие path traversal
func isValidSlug(slug string) bool {
	if len(slug) == 0 || len(slug) > 200 {
		return false
	}
	// Запрещаем любые символы кроме букв, цифр и дефисов
	if !validSlug.MatchString(slug) {
		return false
	}
	// Дополнительная защита от path traversal
	if strings.Contains(slug, "..") || strings.Contains(slug, "/") || strings.Contains(slug, "\\") {
		return false
	}
	return true
}

func parseMarkdown(filename string) (Post, error) {
	// Базовая валидация имени файла
	baseName := filepath.Base(filename)
	if baseName != filename {
		return Post{}, &os.PathError{Op: "parse", Path: filename, Err: os.ErrInvalid}
	}

	data, err := os.ReadFile(filepath.Join(postsDir, filename))
	if err != nil {
		return Post{}, err
	}

	content := string(data)
	title := extractFrontmatterField(content, "title")
	date := extractFrontmatterField(content, "date")
	category := extractFrontmatterField(content, "category")

	slug := strings.TrimSuffix(filename, ".md")

	var html strings.Builder
	if err := goldmark.Convert([]byte(content), &html); err != nil {
		return Post{}, err
	}

	return Post{
		Slug:     slug,
		Title:    title,
		Date:     date,
		Category: category,
		Content:  html.String(),
	}, nil
}

func extractFrontmatterField(content, field string) string {
	lines := strings.Split(content, "\n")
	inFrontmatter := false
	for i, line := range lines {
		if strings.TrimSpace(line) == "---" {
			if i == 0 {
				inFrontmatter = true
				continue
			}
			break
		}
		if inFrontmatter && strings.HasPrefix(line, field+":") {
			return strings.TrimSpace(strings.TrimPrefix(line, field+":"))
		}
	}
	return ""
}

func listAllPosts() ([]Post, error) {
	var posts []Post

	entries, err := os.ReadDir(postsDir)
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".md") {
			post, err := parseMarkdown(entry.Name())
			if err != nil {
				log.Printf("Error parsing %s: %v", entry.Name(), err)
				continue
			}
			post.Content = ""
			posts = append(posts, post)
		}
	}

	sort.Slice(posts, func(i, j int) bool {
		ti, _ := time.Parse("2006-01-02", posts[i].Date)
		tj, _ := time.Parse("2006-01-02", posts[j].Date)
		return ti.After(tj)
	})

	return posts, nil
}

func getPostBySlug(slug string) (Post, error) {
	filename := slug + ".md"
	return parseMarkdown(filename)
}
