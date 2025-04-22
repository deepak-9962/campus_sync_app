# Campus Sync App - Backend Setup Guide

This guide details how to set up the backend for the Campus Sync App using Supabase.

## Prerequisites

- A Supabase account (create one at [https://supabase.com/](https://supabase.com/))
- A Supabase project
- Access to Supabase SQL Editor

## Database Setup

1. Log in to your Supabase dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of the `supabase_setup.sql` file (provided in this repo)
4. Run the SQL queries to create the necessary tables and policies

## Tables Created

### Resources Table

This table stores all educational resources uploaded by users:

```sql
CREATE TABLE IF NOT EXISTS resources (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    subject TEXT NOT NULL,
    department TEXT NOT NULL,
    semester INTEGER NOT NULL,
    file_size TEXT NOT NULL,
    file_type TEXT NOT NULL,
    category TEXT NOT NULL,
    file_url TEXT,
    preview_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_by UUID REFERENCES auth.users(id) DEFAULT auth.uid()
);
```

### Profiles Table

This table stores user profile information:

```sql
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT,
    gender TEXT,
    department TEXT,
    semester INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

## Storage Buckets

The app uses the following storage buckets:

- `resource_files` - For storing uploaded PDF documents and other resources

## Authentication

The app uses Supabase Auth for user authentication with the following features:

- Email/password signup and login
- Password reset functionality
- User profile management

## App Configuration

To connect your app to Supabase, update the following in your `main.dart` file:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

## API Services

The app includes several service classes for interacting with the backend:

- `AuthService` - Handles user authentication and profile management
- `ResourceService` - Manages resource uploads, downloads, and queries

## Security

The backend uses Row Level Security (RLS) to control access to data:

- Anonymous users can view resources
- Authenticated users can create resources
- Users can only update/delete their own resources
- Files in the storage buckets are protected with similar policies
