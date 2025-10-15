# Ocean Guard Frontend

Modern, responsive frontend for the Ocean Guard marine safety system.

## 🌊 Overview

Ocean Guard is India's coastal safety network that enables citizens to report maritime incidents and authorities to respond quickly. This frontend provides:

- 📱 Responsive incident reporting system
- 📊 Real-time analytics dashboard  
- 🗺️ Interactive map visualization (Mapbox)
- 👥 Role-based access control
- 🔐 Secure JWT authentication

## 📂 Structure

```
frontend/
├── index.html              # Root redirect file
├── README.md              # This file
├── pages/                 # HTML pages
│   ├── index.html         # Landing page
│   ├── analytics.html     # Analytics dashboard
│   ├── reports.html       # Incident reports (protected)
│   ├── admin-dashboard.html # Admin panel (protected)
│   ├── my-reports.html    # User's reports
│   ├── authority-analytics.html
│   └── public-analytics.html
├── scripts/               # JavaScript modules
│   ├── script.js          # Main app logic
│   ├── api-client.js      # API communication
│   ├── navigation-manager.js # Navigation control
│   ├── admin-dashboard.js
│   ├── analytics.js
│   ├── reports-dashboard.js
│   └── my-reports.js
├── styles/                # CSS files
│   ├── styles.css         # Main stylesheet
│   ├── analytics.css
│   ├── reports-dashboard.css
│   └── report-enhancements.css
└── assets/                # Static resources
    ├── images/
    ├── fonts/
    └── icons/
```

## 🚀 Quick Start

### Local Development

```bash
# Serve the frontend locally
cd frontend
python -m http.server 3000

# Or using Node.js
npx http-server -p 3000
```

Open: http://localhost:3000

### Configuration

**API Endpoint:** Currently configured to `https://ocean-hazard-1-6j5g.onrender.com/api`

To change, edit `scripts/api-client.js`:
```javascript
class APIClient {
    constructor(baseURL = 'https://your-backend-url.com/api') {
        this.baseURL = baseURL;
        // ...
    }
}
```

## 📦 Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd frontend
vercel
```

Or connect your GitHub repo to Vercel dashboard:
1. Import repository
2. Set root directory to `/frontend`
3. Deploy

### Netlify

1. Drag and drop the `frontend` folder to Netlify
2. Or connect via Git with base directory set to `frontend`

### GitHub Pages

```bash
# Push to gh-pages branch
cd frontend
git init
git add .
git commit -m "Deploy frontend"
git branch -M gh-pages
git remote add origin <your-repo-url>
git push -u origin gh-pages
```

Enable GitHub Pages in repository settings.

### Other Platforms

This is a **static site** with no build step required. Simply:
1. Upload the `frontend` folder
2. Set `index.html` as the entry point
3. Ensure static file serving is enabled

## 🔑 Features

### Public Features
- ✅ Submit incident reports
- ✅ View public analytics
- ✅ Track your submitted reports
- ✅ Real-time map visualization

### Authority Features (Login Required)
- ✅ View all incident reports
- ✅ Access detailed analytics
- ✅ Filter and search reports
- ✅ Role-based dashboard

### Admin Features
- ✅ Manage users and teams
- ✅ Delete authorities/rescue teams
- ✅ System-wide analytics
- ✅ Full access control

## 🛠️ Technology Stack

- **Vanilla JavaScript** (No framework dependencies)
- **Mapbox GL JS** for interactive maps
- **LocalStorage/SessionStorage** for state persistence
- **JWT Authentication** via HTTP-only headers
- **CSS3** with responsive design
- **Font Awesome** icons

## 📱 Responsive Design

- ✅ Mobile-first approach
- ✅ Tablet and desktop optimized
- ✅ Touch-friendly UI elements
- ✅ Adaptive navigation

## 🔐 Security

- JWT token-based authentication
- Tokens stored in localStorage/sessionStorage
- HTTPS recommended for production
- Role-based access control (RBAC)
- XSS protection via content security

## 🌍 Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari 14+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## 🐛 Common Issues

### "Reports not loading"
- Check if you're logged in with authority/admin role
- Verify backend API is running
- Check browser console for errors

### "Map not showing"
- Ensure Mapbox access token is valid
- Check internet connection
- Verify Mapbox CDN is accessible

### "Login not persisting"
- Check localStorage is enabled
- Clear browser cache
- Try sessionStorage fallback

## 📄 API Integration

Backend API: https://ocean-hazard-1-6j5g.onrender.com/api

### Endpoints Used:
- `POST /auth/login` - User authentication
- `POST /auth/register` - User registration  
- `GET /incidents/` - Fetch incidents
- `POST /incidents/` - Submit new incident
- `DELETE /users/{id}` - Delete user (admin only)
- `GET /analytics/overview` - System stats

## 🤝 Contributing

1. Make changes in the appropriate folder
2. Test locally before deployment
3. Update this README if structure changes
4. Follow existing code style

## 📞 Support

For issues or questions:
- Check browser console for errors
- Verify backend API status
- Review network tab for failed requests

## 📝 License

Ocean Guard - Marine Safety System
Built for India's coastal communities

---

**Last Updated:** January 2025
**Version:** 2.0
**Backend:** https://ocean-hazard-1-6j5g.onrender.com/api
