# Deployment Guide

## Automated Deployment with GitHub Actions

This project is configured to automatically deploy to Fly.io whenever you push changes to the `master` or `main` branch.

### Initial Setup

#### 1. Add Fly.io Deploy Token to GitHub Secrets

You need to add your Fly.io deploy token as a GitHub secret:

1. Go to your GitHub repository: https://github.com/divijshrivastava/phoenix-chat
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Name: `FLY_API_TOKEN`
6. Value: Generate a new token by running the following command locally:

   ```bash
   flyctl tokens create deploy -x 999999h
   ```

   Copy the output token (it will start with `FlyV1`) and paste it as the secret value.

7. Click **Add secret**

**Important:** Never commit tokens to your repository! Keep them secure in GitHub Secrets only.

#### 2. How It Works

Once the secret is configured, the deployment workflow will:

1. Trigger automatically on every push to `master` or `main` branch
2. Checkout your code
3. Set up Fly.io CLI
4. Deploy your application to Fly.io using the `--remote-only` flag (builds on Fly.io's servers)

### Workflow File

The workflow configuration is located at `.github/workflows/fly-deploy.yml`

### Manual Deployment

If you need to deploy manually, you can still use:

```bash
flyctl deploy --app chat-app-morning-water-4025
```

### Monitoring Deployments

- View deployment logs in GitHub Actions: https://github.com/divijshrivastava/phoenix-chat/actions
- View app status on Fly.io: `flyctl status --app chat-app-morning-water-4025`
- View live logs: `flyctl logs --app chat-app-morning-water-4025`
- Open app: https://chat-app-morning-water-4025.fly.dev/

### Troubleshooting

If the deployment fails:

1. Check the GitHub Actions logs for error messages
2. Verify the `FLY_API_TOKEN` secret is set correctly
3. Check Fly.io logs: `flyctl logs --app chat-app-morning-water-4025`
4. Verify your app configuration: `flyctl status --app chat-app-morning-water-4025`

### Deployment Workflow

```
Code Change → Push to GitHub → GitHub Actions Triggered → Deploy to Fly.io → App Updated
```

Every push to master/main will automatically deploy the latest changes to your live application!
