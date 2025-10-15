# Frontend Folder Structure

```
frontend/
│
├── index.html                      ← Root entry point (redirects to pages/)
├── README.md                      ← Complete documentation
├── DEPLOYMENT.md                  ← Deployment guide for all platforms
├── QUICK_START.md                 ← Quick start guide
├── vercel.json                    ← Vercel configuration
├── .gitignore                     ← Git ignore rules
│
├── pages/                         ← HTML Pages (10 files)
│   ├── index.html                 ← Main landing page
│   ├── admin-dashboard.html       ← Admin management panel
│   ├── analytics.html             ← Analytics dashboard
│   ├── authority-analytics.html   ← Authority analytics view
│   ├── my-reports.html           ← User's submitted reports
│   ├── public-analytics.html     ← Public analytics view
│   ├── reports.html              ← Incident reports (protected)
│   ├── debug.html                ← Debug page
│   ├── test-navigation.html      ← Navigation test
│   └── test-reports.html         ← Reports test
│
├── scripts/                       ← JavaScript Files (8 files)
│   ├── script.js                  ← Main application logic
│   ├── api-client.js              ← API communication layer
│   ├── navigation-manager.js      ← Navigation visibility control
│   ├── admin-dashboard.js         ← Admin dashboard functionality
│   ├── analytics.js               ← Analytics page logic
│   ├── authority-analytics.js     ← Authority analytics logic
│   ├── my-reports.js             ← My reports page logic
│   └── reports-dashboard.js       ← Reports dashboard logic
│
├── styles/                        ← CSS Files (4 files)
│   ├── styles.css                 ← Main stylesheet
│   ├── analytics.css              ← Analytics page styles
│   ├── reports-dashboard.css      ← Reports dashboard styles
│   └── report-enhancements.css    ← Report UI enhancements
│
└── assets/                        ← Static Resources
    ├── fonts/                     ← Custom fonts
    ├── icons/                     ← Icon files
    └── images/                    ← Image files
```

## File Count Summary

- **HTML Pages:** 10 files
- **JavaScript Files:** 8 files
- **CSS Files:** 4 files
- **Config Files:** 5 files (README, DEPLOYMENT, QUICK_START, vercel.json, .gitignore)
- **Total:** 27+ files (plus assets)

## Path Structure

All paths are relative and deployment-ready:

### In HTML files (pages/*.html):
- CSS: `../styles/styles.css`
- JS: `../scripts/script.js`
- Assets: `../assets/images/logo.png`
- Other pages: `index.html`, `analytics.html`, etc.

### In JavaScript files:
- API: `https://ocean-hazard-1-6j5g.onrender.com/api`
- LocalStorage: Browser-based persistence

### Root index.html:
- Redirects to: `pages/index.html`

## Key Features

✅ Self-contained - All frontend files in one folder
✅ No build step required - Pure HTML/CSS/JS
✅ Works with any static hosting
✅ Vercel/Netlify/GitHub Pages ready
✅ Mobile responsive
✅ Role-based navigation
✅ JWT authentication
✅ Interactive maps (Mapbox)

## Deployment Ready

Upload the entire `frontend/` folder to any of these platforms:
- Vercel (recommended)
- Netlify
- GitHub Pages
- Railway
- Render
- Any static hosting

## Size

- Total size: ~500KB (excluding assets)
- Lightweight and fast loading
- No heavy frameworks or dependencies
