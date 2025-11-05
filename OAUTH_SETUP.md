# OAuth Authentication Setup

This application uses OAuth for authentication with Google and GitHub. Follow these steps to set up OAuth for development and production.

## Required Environment Variables

You need to set the following environment variables:

```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export GITHUB_CLIENT_ID="your-github-client-id"
export GITHUB_CLIENT_SECRET="your-github-client-secret"
```

## 1. Google OAuth Setup

### Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Select **Web application**
6. Configure the OAuth consent screen if prompted
7. Add authorized redirect URIs:
   - Development: `http://localhost:4000/auth/google/callback`
   - Production: `https://your-app.fly.dev/auth/google/callback`
8. Click **Create**
9. Copy the **Client ID** and **Client Secret**

### Set Environment Variables

```bash
export GOOGLE_CLIENT_ID="your-client-id-from-google"
export GOOGLE_CLIENT_SECRET="your-client-secret-from-google"
```

## 2. GitHub OAuth Setup

### Create OAuth App

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Fill in the details:
   - **Application name**: Phoenix Chat (or your app name)
   - **Homepage URL**:
     - Development: `http://localhost:4000`
     - Production: `https://your-app.fly.dev`
   - **Authorization callback URL**:
     - Development: `http://localhost:4000/auth/github/callback`
     - Production: `https://your-app.fly.dev/auth/github/callback`
4. Click **Register application**
5. Copy the **Client ID**
6. Click **Generate a new client secret** and copy it

### Set Environment Variables

```bash
export GITHUB_CLIENT_ID="your-client-id-from-github"
export GITHUB_CLIENT_SECRET="your-client-secret-from-github"
```

## 3. Production Setup (Fly.io)

Set secrets on Fly.io:

```bash
flyctl secrets set GOOGLE_CLIENT_ID="your-google-client-id" \
  GOOGLE_CLIENT_SECRET="your-google-client-secret" \
  GITHUB_CLIENT_ID="your-github-client-id" \
  GITHUB_CLIENT_SECRET="your-github-client-secret" \
  --app chat-app-morning-water-4025
```

**Important:** Make sure to use the production callback URLs when creating OAuth apps for production!

## 4. Development Workflow

### Option 1: Export in your shell

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export GOOGLE_CLIENT_ID="..."
export GOOGLE_CLIENT_SECRET="..."
export GITHUB_CLIENT_ID="..."
export GITHUB_CLIENT_SECRET="..."
```

Then reload your shell or run `source ~/.zshrc`

### Option 2: Use a .env file

1. Create a `.env` file in the project root (already in .gitignore):

```bash
export GOOGLE_CLIENT_ID="..."
export GOOGLE_CLIENT_SECRET="..."
export GITHUB_CLIENT_ID="..."
export GITHUB_CLIENT_SECRET="..."
```

2. Source it before running the app:

```bash
source .env
mix phx.server
```

## 5. Running the Application

### Start the server:

```bash
mix phx.server
```

### Visit:

http://localhost:4000

You should now see "Continue with Google" and "Continue with GitHub" buttons!

## Troubleshooting

### "redirect_uri_mismatch" error

- Make sure your callback URLs in Google/GitHub match exactly
- Development: `http://localhost:4000/auth/{provider}/callback`
- Production: `https://your-app.fly.dev/auth/{provider}/callback`

### "Environment variable not set" error

- Make sure you've exported all required environment variables
- Restart your terminal or Phoenix server after setting them

### Database errors

- Make sure PostgreSQL is running
- Run `mix ecto.create` to create the database
- Run `mix ecto.migrate` to run migrations

## Security Notes

- **NEVER** commit OAuth credentials to version control
- Use environment variables for all secrets
- The `.env` file is already in `.gitignore`
- Use different OAuth apps for development and production
- Regularly rotate your OAuth client secrets
