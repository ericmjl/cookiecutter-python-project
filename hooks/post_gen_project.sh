#!/bin/bash

set -e

echo "🚀 Initializing your new Python project..."

# Cookiecutter runs this hook with cwd already at the generated project root
# (the folder named "{{ cookiecutter.__repo_name }}"). Only cd if we are still
# in the parent directory (older/alternate Cookiecutter behavior).
REPO="{{ cookiecutter.__repo_name }}"
if [ "$(basename "$PWD")" != "$REPO" ] && [ -d "$REPO" ]; then
  cd "$REPO"
fi

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

# Create Jupyter kernel
echo "🔧 Enabling Jupyter kernel discovery of your newfangled conda environment..."
if command -v pixi &> /dev/null; then
    pixi run python -m ipykernel install --user --name "$(basename "$PWD")"
else
    echo "❌ pixi not found. Skipping Jupyter kernel setup."
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

    # Check GitHub account status and verify with user
    echo "🔍 Checking GitHub account status..."
    gh auth status

    echo ""
    echo "🤔 Please confirm you're using the correct GitHub account:"
    echo "   Active account: ${GITHUB_USERNAME}"
    echo ""
    read -p "Is this the correct account? (Y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "🔄 Switching GitHub account..."
        gh auth switch
        GITHUB_USERNAME=$(gh api user --jq .login)
        echo "✅ Switched to account: ${GITHUB_USERNAME}"
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

# Function to attempt git commit with retry logic
commit_with_retry() {
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..."

        if git add . && git commit -m "Initial commit"; then
            echo "✅ Initial commit successful!"
            return 0
        else
            echo ""
            echo "❌ Commit failed on attempt $attempt"
            echo ""
            echo "This is likely due to pre-commit hooks failing (e.g., pydoclint, ruff, etc.)"
            echo "The error output above shows which checks failed."
            echo ""

            if [ $attempt -lt $max_attempts ]; then
                echo "Would you like to:"
                echo "1) Fix the issues and retry"
                echo "2) Skip this commit and handle manually later"
                echo "3) Force commit (not recommended)"
                echo ""
                read -p "Choose option (1/2/3): " -n 1 -r
                echo ""

                case $REPLY in
                    1)
                        echo "Please fix the issues above and press Enter to retry..."
                        read -r
                        ;;
                    2)
                        echo "⏭️  Skipping commit. You can run 'git commit -m \"Initial commit\"' manually later."
                        return 0
                        ;;
                    3)
                        echo "⚠️  Force committing (bypassing pre-commit hooks)..."
                        git commit -m "Initial commit" --no-verify
                        echo "✅ Force commit successful!"
                        return 0
                        ;;
                    *)
                        echo "Invalid option. Retrying..."
                        ;;
                esac
            else
                echo "❌ All attempts failed. Please fix the issues manually and run:"
                echo "   git add ."
                echo "   git commit -m \"Initial commit\""
                return 1
            fi

            attempt=$((attempt + 1))
        fi
    done
}

commit_with_retry

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