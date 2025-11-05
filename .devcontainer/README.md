# Dev Container Configuration

This repository is configured for **GitHub Codespaces** and **VS Code Dev Containers**.

## What's Included

- **Node.js 20** - For modern JavaScript development
- **Python 3.11** - For backend scripts and tools
- **Live Server** - Auto-reloading development server
- **Git & GitHub CLI** - Version control tools
- **Prettier** - Code formatting
- **VS Code Extensions** - Pre-installed development tools

## Quick Start

### Using GitHub Codespaces (Recommended)

1. Go to your GitHub repository
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait for the environment to build (~2 minutes)
4. Run: `live-server website/` in the terminal
5. Your website will open automatically!

### Using VS Code Dev Containers (Local)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
3. Open this project in VS Code
4. Click "Reopen in Container" when prompted
5. Run: `live-server website/` in the terminal

## Development Commands

```bash
# Start live development server
live-server website/

# Start alternative HTTP server
http-server website/ -p 8080

# Format code with Prettier
prettier --write website/*.{html,css,js}

# Check for issues
prettier --check website/*.{html,css,js}
```

## Ports

The following ports are automatically forwarded:

- **8080** - Main website development server
- **3000** - Alternative development port
- **5500** - Live Server default port

## Extensions Included

- **Prettier** - Code formatter
- **ESLint** - JavaScript linter
- **Live Server** - Auto-reload development server
- **Python** - Python language support
- **Pylance** - Python IntelliSense
- **Auto Rename Tag** - HTML tag pair renaming
- **Code Spell Checker** - Spelling checker
- **Error Lens** - Inline error highlighting

## Benefits

✅ **Consistent Environment** - Everyone uses the same setup  
✅ **No Local Setup** - Works in browser via Codespaces  
✅ **Pre-configured Tools** - Everything installed automatically  
✅ **Fast Onboarding** - New contributors ready in minutes  
✅ **Cloud-Based** - Code from anywhere  

## Troubleshooting

### Container won't build
- Ensure Docker is running (local) or wait for Codespaces
- Check internet connection
- Try rebuilding: Command Palette → "Dev Containers: Rebuild Container"

### Port already in use
- Change port: `live-server website/ --port=8081`
- Or use alternative: `http-server website/ -p 8082`

### Extensions not working
- Reload window: Command Palette → "Developer: Reload Window"
- Rebuild container if issue persists

## Production Deployment

This dev container is for **development only**. For production deployment to **recipefinder.uk**, see:

- `website/DEPLOYMENT.md` - Full deployment guide
- `website/README.md` - Website documentation

## Learn More

- [GitHub Codespaces Docs](https://docs.github.com/en/codespaces)
- [Dev Containers Docs](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container Spec](https://containers.dev/)
