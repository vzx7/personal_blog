import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'

interface Post {
  slug: string
  title: string
  date: string
  category: string
  content: string
}

function Post() {
  const { slug } = useParams<{ slug: string }>()
  const [post, setPost] = useState<Post | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/posts/${slug}`)
      .then(res => res.json())
      .then(data => {
        setPost(data)
        setLoading(false)
      })
      .catch(err => {
        console.error(err)
        setLoading(false)
      })
  }, [slug])

  if (loading) {
    return <div className="loading">Loading...</div>
  }

  if (!post) {
    return (
      <div className="not-found">
        <h1>Post not found</h1>
        <Link to="/">← Back to home</Link>
      </div>
    )
  }

  return (
    <article className="post">
      <header>
        <h1>{post.title}</h1>
        <div className="post-meta">
          <span className="date">{post.date}</span>
          <span className="category">{post.category}</span>
        </div>
      </header>
      <div 
        className="post-content"
        dangerouslySetInnerHTML={{ __html: post.content }}
      />
      <Link to="/" className="back-link">← Back to all posts</Link>
    </article>
  )
}

export default Post
