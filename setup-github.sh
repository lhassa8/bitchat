#!/bin/bash

# GitHub Setup Script for bitchat
# This script helps set up the repository for GitHub

set -e

echo "🚀 Setting up bitchat for GitHub..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "project.yml" ] || [ ! -d "bitchat" ]; then
    print_error "This script must be run from the bitchat project root directory"
    exit 1
fi

print_status "Checking prerequisites..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git first."
    exit 1
fi

# Check if GitHub CLI is installed (optional)
if command -v gh &> /dev/null; then
    print_success "GitHub CLI found"
    GH_CLI_AVAILABLE=true
else
    print_warning "GitHub CLI not found. You'll need to create the repository manually."
    GH_CLI_AVAILABLE=false
fi

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    print_status "Initializing Git repository..."
    git init
    print_success "Git repository initialized"
else
    print_status "Git repository already exists"
fi

# Add all files to git
print_status "Adding files to Git..."
git add .

# Check if there are any changes to commit
if git diff --staged --quiet; then
    print_warning "No changes to commit"
else
    # Commit initial files
    print_status "Creating initial commit..."
    git commit -m "Initial commit: bitchat secure mesh messaging app

Features:
- Bluetooth LE mesh networking
- End-to-end encryption (X25519 + AES-256-GCM)
- Channel-based messaging with password protection
- Store & forward for offline peers
- Message delivery confirmations with retry logic
- Offline message queuing with size limits
- Network health monitoring and indicators
- Privacy-first design with no servers
- Universal iOS/macOS app
- Public domain license"
    
    print_success "Initial commit created"
fi

# Set up remote repository
print_status "Setting up remote repository..."

if [ "$GH_CLI_AVAILABLE" = true ]; then
    # Check if user is logged in to GitHub CLI
    if gh auth status &> /dev/null; then
        print_status "Creating GitHub repository..."
        
        # Create the repository
        gh repo create lhassa8/bitchat --public --description "Secure, decentralized, peer-to-peer messaging over Bluetooth mesh networks. No internet required, no servers, no phone numbers - just pure encrypted communication." --homepage "https://github.com/lhassa8/bitchat"
        
        # Add the remote
        git remote add origin https://github.com/lhassa8/bitchat.git
        
        print_success "GitHub repository created and remote added"
    else
        print_warning "Please log in to GitHub CLI first: gh auth login"
        print_status "Or manually create the repository at: https://github.com/new"
        print_status "Repository name: bitchat"
        print_status "Description: Secure, decentralized, peer-to-peer messaging over Bluetooth mesh networks"
        
        # Add remote manually
        git remote add origin https://github.com/lhassa8/bitchat.git
        print_status "Remote added (you'll need to create the repository manually)"
    fi
else
    print_status "Please create a new repository on GitHub:"
    print_status "1. Go to https://github.com/new"
    print_status "2. Repository name: bitchat"
    print_status "3. Description: Secure, decentralized, peer-to-peer messaging over Bluetooth mesh networks"
    print_status "4. Make it public"
    print_status "5. Don't initialize with README (we already have one)"
    
    # Add remote
    git remote add origin https://github.com/lhassa8/bitchat.git
    print_status "Remote added"
fi

# Set up main branch
print_status "Setting up main branch..."
git branch -M main

# Push to GitHub
print_status "Pushing to GitHub..."
if git push -u origin main; then
    print_success "Successfully pushed to GitHub!"
else
    print_error "Failed to push to GitHub. You may need to create the repository first."
    print_status "After creating the repository, run: git push -u origin main"
fi

# Set up branch protection (if GitHub CLI is available and user is authenticated)
if [ "$GH_CLI_AVAILABLE" = true ] && gh auth status &> /dev/null; then
    print_status "Setting up branch protection..."
    gh api repos/lhassa8/bitchat/branches/main/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["Build and Test"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
        --field restrictions=null \
        2>/dev/null || print_warning "Could not set up branch protection (may require admin access)"
fi

# Generate project if XcodeGen is available
if command -v xcodegen &> /dev/null; then
    print_status "Generating Xcode project..."
    xcodegen generate
    print_success "Xcode project generated"
else
    print_warning "XcodeGen not found. Install with: brew install xcodegen"
fi

print_success "🎉 GitHub setup complete!"
echo ""
print_status "Next steps:"
echo "1. Visit your repository: https://github.com/lhassa8/bitchat"
echo "2. Enable GitHub Pages (optional) for documentation"
echo "3. Set up repository topics/tags for discoverability"
echo "4. Configure repository settings as needed"
echo "5. Start accepting contributions!"
echo ""
print_status "Repository features enabled:"
echo "✅ Comprehensive README with setup instructions"
echo "✅ Contributing guidelines"
echo "✅ Issue templates (bug reports, feature requests, security)"
echo "✅ Pull request template"
echo "✅ Security policy"
echo "✅ GitHub Actions CI/CD workflow"
echo "✅ Comprehensive .gitignore"
echo "✅ Public domain license"
echo ""
print_status "Happy coding! 🚀"
