# Deploying Trip Expense to Cloudflare Pages

This guide will help you deploy your Flutter web app to Cloudflare Pages.

## Prerequisites

1. A Cloudflare account (free tier works)
2. Git repository (GitHub, GitLab, or Bitbucket)
3. Flutter SDK installed

## Method 1: Deploy via Cloudflare Dashboard (Recommended)

### Step 1: Build the Flutter Web App

```bash
cd /Users/santosh/coding/personal/trip
flutter build web --release
```

This will create the build files in `build/web/` directory.

### Step 2: Push to Git Repository

If you haven't already, initialize git and push to a repository:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

### Step 3: Deploy via Cloudflare Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Pages** in the sidebar
3. Click **Create a project**
4. Choose **Connect to Git**
5. Select your Git provider (GitHub, GitLab, or Bitbucket)
6. Authorize Cloudflare to access your repositories
7. Select your repository (`trip`)
8. Configure build settings:
   - **Framework preset**: None
   - **Build command**: `bash build.sh` or use the GitHub Actions method below
   - **Build output directory**: `build/web`
   - **Root directory**: `/` (leave empty)
   - **Environment variables**: (Optional) Add any needed variables
9. Click **Save and Deploy**

**Note:** Cloudflare Pages doesn't have Flutter pre-installed. You have two options:

### Option A: Use the build script (may be slow)
Use `bash build.sh` as the build command. This will install Flutter during build (takes ~5-10 minutes).

### Option B: Use GitHub Actions (Recommended - Faster)
See "Method 4: GitHub Actions + Cloudflare Pages" below for a faster approach.

### Step 4: Configure Environment Variables (if needed)

If you need to change Supabase credentials:
1. Go to your project settings
2. Navigate to **Environment variables**
3. Add any required variables

## Method 2: Deploy via Wrangler CLI

### Step 1: Install Wrangler

```bash
npm install -g wrangler
# or
npm install wrangler --save-dev
```

### Step 2: Login to Cloudflare

```bash
wrangler login
```

### Step 3: Build the App

```bash
flutter build web --release
```

### Step 4: Deploy

```bash
wrangler pages deploy build/web --project-name=trip-expense
```

## Method 3: Manual Upload

### Step 1: Build the App

```bash
flutter build web --release
```

### Step 2: Upload via Dashboard

1. Go to Cloudflare Dashboard → Pages
2. Click **Create a project** → **Upload assets**
3. Drag and drop the contents of `build/web/` folder
4. Click **Deploy site**

## Important Notes

### Base Path Configuration

If deploying to a subdirectory, update `web/index.html`:

```html
<base href="/your-subdirectory/">
```

And build with:
```bash
flutter build web --release --base-href="/your-subdirectory/"
```

### Single Page Application (SPA) Routing

Flutter web apps are SPAs. You need to configure Cloudflare to handle routing:

1. Create a `_redirects` file in `web/` directory (see below)
2. Or configure redirects in Cloudflare Pages settings:
   - Go to **Functions** → **Redirects**
   - Add rule: `/* /index.html 200`

### CORS Configuration

If you encounter CORS issues with Supabase:
- Configure CORS in your Supabase dashboard
- Add your Cloudflare Pages domain to allowed origins

## Troubleshooting

### Build Fails

- Ensure Flutter web is enabled: `flutter config --enable-web`
- Check Flutter version: `flutter --version`
- Try cleaning build: `flutter clean && flutter pub get`

### Routing Issues

- Ensure `_redirects` file is in `web/` directory
- Check Cloudflare Pages redirect rules

### Assets Not Loading

- Verify all assets are in `web/` directory
- Check `pubspec.yaml` assets section
- Ensure base href is correct

## Continuous Deployment

Once connected to Git, Cloudflare Pages will automatically:
- Deploy on every push to main branch
- Create preview deployments for pull requests
- Show build logs and deployment status

## Custom Domain

1. Go to your project → **Custom domains**
2. Click **Set up a custom domain**
3. Follow the DNS configuration instructions
4. Cloudflare will automatically provision SSL certificates

