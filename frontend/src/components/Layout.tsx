import { Link, Outlet } from 'react-router-dom'

function Layout() {
  return (
    <div className="container">
      <header>
        <nav>
          <Link to="/" className="logo">My Blog</Link>
          <ul className="nav-links">
            <li><Link to="/">Home</Link></li>
            <li className="dropdown">
              <span>Categories</span>
              <ul className="dropdown-menu">
                <li><Link to="/?category=Personal">Personal</Link></li>
                <li><Link to="/?category=Religion">Religion</Link></li>
                <li><Link to="/?category=Dev">Dev</Link></li>
              </ul>
            </li>
            <li><Link to="/about">About</Link></li>
          </ul>
        </nav>
      </header>
      <main>
        <Outlet />
      </main>
      <footer>
        <p>&copy; 2026 My Blog</p>
      </footer>
    </div>
  )
}

export default Layout
