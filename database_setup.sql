-- Location functionality setup for existing booking database
-- Run these SQL commands in your Supabase SQL editor

-- 1. Create user_locations table to store user location data
CREATE TABLE IF NOT EXISTS user_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 2. Create index for faster location queries
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON user_locations(user_id);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;

-- 4. Create policies for user_locations table
CREATE POLICY "Users can read their own location" ON user_locations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own location" ON user_locations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own location" ON user_locations
    FOR UPDATE USING (auth.uid() = user_id);

-- 5. Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 6. Create trigger to automatically update updated_at
CREATE TRIGGER update_user_locations_updated_at 
    BEFORE UPDATE ON user_locations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 7. Optional: Add location columns to jobs table (if you want to store job location)
-- Uncomment the following lines if you want to store job locations directly in the jobs table
/*
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS job_latitude DOUBLE PRECISION;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS job_longitude DOUBLE PRECISION;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS job_address TEXT;
*/

-- 8. Optional: Create a function to get nearby users (within a certain radius)
CREATE OR REPLACE FUNCTION get_nearby_users(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 5000
)
RETURNS TABLE (
    user_id UUID,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ul.user_id,
        ul.latitude,
        ul.longitude,
        (
            6371000 * acos(
                cos(radians(user_lat)) * 
                cos(radians(ul.latitude)) * 
                cos(radians(ul.longitude) - radians(user_lng)) + 
                sin(radians(user_lat)) * 
                sin(radians(ul.latitude))
            )
        ) AS distance_meters
    FROM user_locations ul
    WHERE (
        6371000 * acos(
            cos(radians(user_lat)) * 
            cos(radians(ul.latitude)) * 
            cos(radians(ul.longitude) - radians(user_lng)) + 
            sin(radians(user_lat)) * 
            sin(radians(ul.latitude))
        )
    ) <= radius_meters
    ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql;

-- 9. Optional: Create a function to get nearby jobs (if you add location to jobs table)
-- Uncomment if you add location columns to jobs table
/*
CREATE OR REPLACE FUNCTION get_nearby_jobs(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 5000
)
RETURNS TABLE (
    job_id UUID,
    title TEXT,
    description TEXT,
    status TEXT,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.status,
        (
            6371000 * acos(
                cos(radians(user_lat)) * 
                cos(radians(j.job_latitude)) * 
                cos(radians(j.job_longitude) - radians(user_lng)) + 
                sin(radians(user_lat)) * 
                sin(radians(j.job_latitude))
            )
        ) AS distance_meters
    FROM jobs j
    WHERE j.job_latitude IS NOT NULL 
    AND j.job_longitude IS NOT NULL
    AND (
        6371000 * acos(
            cos(radians(user_lat)) * 
            cos(radians(j.job_latitude)) * 
            cos(radians(j.job_longitude) - radians(user_lng)) + 
            sin(radians(user_lat)) * 
            sin(radians(j.job_latitude))
        )
    ) <= radius_meters
    ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql;
*/ 