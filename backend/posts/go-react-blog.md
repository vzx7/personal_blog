---
title: Building a Blog with Go and React
date: 2026-03-10
category: Dev
---

# Building a Blog with Go and React

Today I'm sharing how I built this very blog using Go for the backend and React for the frontend.

## Why This Stack?

I chose this combination because:

- **Go**: Fast, simple, great for APIs
- **React**: Component-based, excellent ecosystem
- **TypeScript**: Type safety for maintainable code

## Backend Structure

The Go backend is minimal:

```go
func main() {
    r := mux.NewRouter()
    r.HandleFunc("/api/posts", ListPosts)
    r.HandleFunc("/api/posts/{slug}", GetPost)
}
```

## Frontend Setup

Using Vite for the React frontend gives us:

- Lightning fast HMR
- Optimized builds
- Great TypeScript support

## Lessons Learned

1. Keep it simple
2. Don't over-engineer
3. Focus on content first

This project shows that you can build something useful in a weekend!
