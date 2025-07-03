#!/bin/bash

set -e

echo "🚀 Initializing your new Python project..."

# Change to the generated project directory
cd "{{ cookiecutter.__repo_name }}"

# Create .env file
echo "📝 Creating .env file..."
cat > .env << 'EOF'
# Environment variables for {{ cookiecutter.project_name }}
# NOTE: This file is _never_ committed into the git repository!
#       It might contain secrets (e.g. API keys) that should never be exposed publicly.
# export ENV_VAR="some_value"
EOF

# Install pixi environment
echo "📦 Installing pixi environment (this might take a few moments!)..."
if command -v pixi &> /dev/null; then
    pixi install --manifest-path pyproject.toml
else
    echo "❌ pixi not found. Please install pixi first."
    echo "   You can install pixi from: https://pixi.sh"
    exit 1
fi

# Configure Git
echo "🔧 Configuring git..."

# Get GitHub username from gh CLI
if command -v gh &> /dev/null; then
    GITHUB_USERNAME=$(gh api user --jq .login)
    if [ -z "$GITHUB_USERNAME" ]; then
        echo "❌ Could not get GitHub username. Please ensure you're logged in with 'gh auth login'"
        exit 1
    fi
else
    echo "❌ GitHub CLI not found. Please install it first."
    exit 1
fi

# Initialize git repository
git init -b main

# Prompt user about creating GitHub repository
REPO_NAME="{{ cookiecutter.__repo_name }}"
echo ""
echo "🤔 Would you like to create a GitHub repository for this project?"
echo "   Repository name: ${REPO_NAME}"
echo "   GitHub username: ${GITHUB_USERNAME}"
echo ""
read -p "Create GitHub repository? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📦 Creating GitHub repository..."
    gh repo create "${GITHUB_USERNAME}/${REPO_NAME}" \
        --private \
        --description "{{ cookiecutter.short_description }}" \
        --source . \
        --remote origin \
        --push
    echo "✅ GitHub repository created and pushed!"
else
    echo "📝 Adding remote origin manually..."
    GIT_SSH_URL="git@github.com:${GITHUB_USERNAME}/${REPO_NAME}"
    git remote add origin "$GIT_SSH_URL"
    echo "✅ Remote origin added. You can create the repository manually on GitHub later."
fi

# Install pre-commit hooks
echo "🔧 Installing pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
    echo "🔄 Updating pre-commit hooks to latest versions..."
    pre-commit autoupdate
else
    echo "❌ pre-commit not found. Please install it first."
    echo "   You can install it with: uv tool install pre-commit"
    exit 1
fi

# Make initial commit (with safety mechanism for pre-commit hooks)
echo "📝 Making initial commit..."
git add .
git commit -m "Initial commit" || {
    echo "⚠️  First commit failed, likely due to pre-commit hooks. Retrying..."
    git add .
    git commit -m "Initial commit"
}

echo "🎉 Your project has been successfully initialized!"
echo ""
echo "Next steps:"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✅ Repository already pushed to GitHub!"
else
    echo "1. Create repository on GitHub and push: git push -u origin main"
fi
echo "2. Activate your environment: pixi shell"
echo "3. Start coding!"