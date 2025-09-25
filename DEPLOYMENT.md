# Deployment Guide for OnlineResampler.jl

This document explains how to set up automatic documentation deployment to GitHub Pages.

## GitHub Repository Setup

The repository is configured with:
- ✅ GitHub Actions workflow (`.github/workflows/Documentation.yml`)
- ✅ Documenter.jl configuration (`docs/make.jl`) with `deploydocs()`
- ✅ Documentation Project.toml in `docs/`

## GitHub Pages Configuration

### Step 1: Enable GitHub Pages

1. Go to https://github.com/femtotrader/OnlineResampler.jl
2. Click **Settings** tab
3. Click **Pages** in the left sidebar
4. Under **Source**, select **"Deploy from a branch"**
5. Under **Branch**, select **"gh-pages"** and **"/ (root)"**
6. Click **Save**

### Step 2: Verify Actions

1. Go to the **Actions** tab on GitHub
2. You should see the "Documentation" workflow
3. It will run automatically on every push to `main`

## Documentation URLs

Once configured, documentation will be available at:

- **Latest development version**: https://femtotrader.github.io/OnlineResampler.jl/dev/
- **Stable version**: https://femtotrader.github.io/OnlineResampler.jl/stable/ (when you create releases)

## Optional: SSH Deploy Key Setup (Recommended)

For enhanced security, you can set up SSH deploy keys:

### Generate SSH Key Pair
```bash
ssh-keygen -t rsa -b 4096 -C "documenter-key" -f documenter-key -N ""
```

### Add Deploy Key
1. Go to **Settings** > **Deploy keys**
2. Click **Add deploy key**
3. Title: "Documenter Key"
4. Key: Contents of `documenter-key.pub`
5. ✅ Check "Allow write access"
6. Click **Add key**

### Add Secret
1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Click **New repository secret**
3. Name: `DOCUMENTER_KEY`
4. Secret: Contents of `documenter-key` (private key)
5. Click **Add secret**

## Triggering Documentation Builds

Documentation builds automatically on:
- ✅ Push to `main` branch
- ✅ New tags/releases
- ✅ Pull requests (build only, no deploy)

## Manual Trigger

You can manually trigger builds:
1. Go to **Actions** tab
2. Select "Documentation" workflow
3. Click **Run workflow** > **Run workflow**

## Local Testing

Test documentation builds locally:
```bash
# Build documentation
make docs

# Build and open
make docs-open
```

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**: Set up SSH deploy key (see above)
2. **"No pages site" error**: Check GitHub Pages settings
3. **Build failures**: Check Actions tab for error logs

### Useful Commands

```bash
# Check workflow status
gh run list --workflow=Documentation

# View workflow logs
gh run view --log

# Trigger manual build
gh workflow run Documentation
```

## Badge for README

Add this badge to show documentation status:
```markdown
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://femtotrader.github.io/OnlineResampler.jl/dev/)
```

---

The documentation should be live within a few minutes after the first successful workflow run!