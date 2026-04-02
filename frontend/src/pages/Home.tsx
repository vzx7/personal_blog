import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'

interface Post {
  slug: string
  title: string
  date: string
  category: string
}

function Home() {
  const [posts, setPosts] = useState<Post[]>([])
  const [searchParams] = useSearchParams()
  const category = searchParams.get('category')

  useEffect(() => {
    fetch('/api/posts')
      .then(res => res.json())
      .then(data => setPosts(data))
      .catch(console.error)
  }, [])

  const filteredPosts = category
    ? posts.filter(post => post.category === category)
    : posts

  return (
    <div className="home">
      <h1>{category ? `${category} Posts` : 'All Posts'}</h1>
      {filteredPosts.length === 0 ? (
        <p>No posts found.</p>
      ) : (
        <ul className="post-list">
          {filteredPosts.map(post => (
            <li key={post.slug} className="post-item">
              <Link to={`/post/${post.slug}`}>
                <h2>{post.title}</h2>
              </Link>
              <div className="post-meta">
                <span className="date">{post.date}</span>
                <span className="category">{post.category}</span>
              </div>
            </li>
          ))}
        </ul>
      )}
      {category && (
        <Link to="/" className="back-link">← Back to all posts</Link>
      )}
    </div>
  )
}

export default Home
