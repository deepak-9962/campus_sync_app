#!/bin/bash
# Vercel Build Script for Flutter Web PWA
# This script installs Flutter and builds the web app

set -e

echo "🚀 Starting Campus Sync PWA Build..."

# Check if Flutter is already installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Flutter not found. Installing Flutter..."
    
    # Clone Flutter SDK
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    
    # Add Flutter to PATH
    export PATH="$PATH:$(pwd)/flutter/bin"
    
    echo "✅ Flutter installed successfully"
else
    echo "✅ Flutter already available"
fi

# Show Flutter version
echo "📋 Flutter version:"
flutter --version

# Disable analytics
flutter config --no-analytics

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Create .env file from environment variables
echo "🔐 Creating .env file..."
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_URL=$SUPABASE_URL" > .env
    echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
    echo "✅ .env file created with environment variables"
else
    echo "⚠️ SUPABASE_URL or SUPABASE_ANON_KEY not found in environment variables"
    echo "Creating empty .env file to satisfy build requirements..."
    touch .env
fi

# Build for web (defaults to auto/canvaskit)
echo "🔨 Building web app..."
flutter build web --release

echo "✅ Build complete! Output in build/web/"
echo "📱 PWA is ready for deployment"

# List output files
ls -la build/web/
