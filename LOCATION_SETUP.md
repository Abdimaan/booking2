# Location Integration Setup Guide

This guide explains how to add location functionality to your existing booking service database.

## 🗄️ Your Current Database Schema

You already have these tables:
- **`users`** - User profiles with id, name, role, created_at
- **`jobs`** - Job postings with id, title, description, status, created_by, accepted_by, created_at
- **`rejected_jobs`** - Job rejections with id, job_id, provider_id, rejected_at

## ➕ What to Add to Your Database

### Required: New Table
You need to add **ONE new table** to your existing database:

**`user_locations`** - Stores user location data
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users.id)
- `latitude` (DOUBLE PRECISION)
- `longitude` (DOUBLE PRECISION)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Optional: Additional Columns
If you want to store job locations directly in the jobs table, you can add:
- `job_latitude` (DOUBLE PRECISION) to `jobs` table
- `job_longitude` (DOUBLE PRECISION) to `jobs` table
- `job_address` (TEXT) to `jobs` table

## 🚀 Database Setup Steps

1. **Go to your Supabase dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the contents of `database_setup.sql`**
4. **Run the SQL commands**

The script will:
- ✅ Create the `user_locations` table
- ✅ Add proper indexes for performance
- ✅ Enable Row Level Security (RLS)
- ✅ Create security policies
- ✅ Add automatic timestamp updates
- ✅ Create helper functions for distance calculations

## 🔗 How Location Works with Your Existing Tables

### Current Flow:
1. User creates job → stored in `jobs` table
2. Provider sees job → can accept/reject
3. If rejected → stored in `rejected_jobs` table

### With Location Added:
1. User creates job → stored in `jobs` table
2. **User location** → stored in `user_locations` table
3. **Provider location** → stored in `user_locations` table
4. Provider sees job → **with distance calculation**
5. If rejected → stored in `rejected_jobs` table

## 📊 Database Relationships

```
users (existing)
├── id → user_locations.user_id
├── id → jobs.created_by
└── id → jobs.accepted_by

jobs (existing)
├── id → rejected_jobs.job_id
└── created_by → users.id

rejected_jobs (existing)
├── job_id → jobs.id
└── provider_id → users.id

user_locations (NEW)
└── user_id → auth.users.id
```

## 🎯 Location Features Added

### For Users:
- **Location tracking** when they post jobs
- **Distance display** to providers who accept their jobs
- **Location refresh** functionality

### For Providers:
- **Location tracking** for distance calculations
- **Distance display** to job locations
- **Nearby job filtering** (optional)

## 🔧 Platform Setup

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby jobs and providers.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby jobs and providers.</string>
```

## 📦 Dependencies

The `geolocator: ^13.0.1` dependency has been added to your `pubspec.yaml`.

Run `flutter pub get` to install it.

## 🚀 Next Steps After Database Setup

1. **Test the app** - Location features will work immediately
2. **Customize distance thresholds** - Currently 20 meters for updates
3. **Add location-based filtering** - Show only nearby jobs
4. **Implement push notifications** - Alert users of nearby jobs

## 🔒 Security & Privacy

- **Row Level Security (RLS)** ensures users only see their own location
- **Location permission** is requested explicitly
- **No location data** is shared without user consent
- **App works** even if location is denied

## ❓ FAQ

**Q: Will this break my existing app?**
A: No, the location features are additive and won't affect existing functionality.

**Q: Do I need to modify my existing tables?**
A: No, the new `user_locations` table is separate and doesn't change your existing schema.

**Q: Can I add job locations later?**
A: Yes, you can uncomment the optional columns in the SQL script anytime.

**Q: What if a user denies location permission?**
A: The app will work normally, just without distance features. 