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

# Build for web with CanvasKit renderer (better compatibility)
echo "🔨 Building web app..."
flutter build web --release --web-renderer canvaskit

# Inject environment variables if they exist
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "🔐 Environment variables detected"
    # The app should read these from .env or dart-define
fi

echo "✅ Build complete! Output in build/web/"
echo "📱 PWA is ready for deployment"

# List output files
ls -la build/web/
