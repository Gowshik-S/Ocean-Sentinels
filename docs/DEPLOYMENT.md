# 🚀 Quick Deployment Guide

## Option 1: Vercel (Recommended - 5 minutes)

### Via Vercel CLI
```bash
# Install Vercel
npm i -g vercel

# Navigate to frontend folder
cd frontend

# Deploy (follow prompts)
vercel

# For production
vercel --prod
```

### Via Vercel Dashboard
1. Go to https://vercel.com/new
2. Import your Git repository
3. Configure project:
   - **Framework Preset:** Other
   - **Root Directory:** `frontend`
   - **Build Command:** (leave empty)
   - **Output Directory:** (leave empty)
4. Click **Deploy**
5. Your site will be live at: `https://your-project.vercel.app`

---

## Option 2: Netlify (Drag & Drop)

1. Go to https://app.netlify.com/drop
2. Drag the entire `frontend` folder
3. Your site is live instantly!
4. (Optional) Connect to Git for continuous deployment

### Via Netlify CLI
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
cd frontend
netlify deploy

# Production deploy
netlify deploy --prod
```

---

## Option 3: GitHub Pages (Free)

```bash
cd frontend

# Initialize git if not already
git init
git add .
git commit -m "Deploy Ocean Guard frontend"

# Create gh-pages branch
git branch -M gh-pages

# Add your repo
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to gh-pages
git push -u origin gh-pages
```

Then enable GitHub Pages:
1. Go to repository Settings
2. Pages section
3. Source: `gh-pages` branch
4. Save

Your site: `https://YOUR_USERNAME.github.io/YOUR_REPO/`

---

## Option 4: Railway

1. Go to https://railway.app/new
2. Select "Deploy from GitHub repo"
3. Choose your repository
4. Settings:
   - **Root Directory:** `frontend`
   - **Start Command:** `python -m http.server $PORT` or `npx serve -s . -p $PORT`
5. Deploy

---

## Option 5: Render

1. Go to https://dashboard.render.com/
2. New → Static Site
3. Connect your repository
4. Settings:
   - **Root Directory:** `frontend`
   - **Build Command:** (leave empty)
   - **Publish Directory:** `.`
5. Create Static Site

---

## Testing Deployment Locally

Before deploying, test that everything works:

```bash
cd frontend

# Using Python
python -m http.server 8000

# Using Node.js
npx http-server -p 8000

# Using PHP
php -S localhost:8000
```

Open: http://localhost:8000

---

## Environment Configuration

After deployment, verify:

1. **API Endpoint** in `scripts/api-client.js`:
   ```javascript
   constructor(baseURL = 'https://ocean-hazard-1-6j5g.onrender.com/api')
   ```

2. **Mapbox Token** in pages (if you have one):
   ```javascript
   mapboxgl.accessToken = 'YOUR_TOKEN';
   ```

3. **Test Login:**
   - Admin: admin@oceanguard.in / admin123
   - Authority: authority1@oceanguard.in / rescue123

---

## Post-Deployment Checklist

- [ ] Frontend is accessible
- [ ] All pages load correctly
- [ ] Maps are displaying
- [ ] Login/logout works
- [ ] API requests succeed
- [ ] Images/icons load
- [ ] Responsive on mobile
- [ ] HTTPS is enabled

---

## Custom Domain (Optional)

### Vercel
1. Go to project settings
2. Domains tab
3. Add your domain
4. Update DNS records as shown

### Netlify
1. Domain settings
2. Add custom domain
3. Configure DNS

---

## Troubleshooting

### "Cannot GET /"
- Ensure `index.html` is in the root of frontend folder
- Check deployment logs for errors

### "API requests failing"
- Verify backend is running: https://ocean-hazard-1-6j5g.onrender.com/api/docs
- Check CORS settings on backend
- Enable HTTPS if backend requires it

### "Maps not loading"
- Check internet connection
- Verify Mapbox CDN accessibility
- Check browser console for token errors

### "Blank page"
- Check browser console for JavaScript errors
- Verify all paths are correct (../ for resources)
- Clear browser cache

---

## Quick Links

- **Backend API:** https://ocean-hazard-1-6j5g.onrender.com/api
- **API Docs:** https://ocean-hazard-1-6j5g.onrender.com/api/docs
- **Source Code:** [Your GitHub Repo]

---

**Need Help?**
Check the main README.md for detailed documentation.

**Deployment Time:** ~5-10 minutes
**Cost:** FREE (all platforms offer free tier)
