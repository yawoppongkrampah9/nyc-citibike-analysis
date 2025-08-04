--  Viewing all columns in dataset
SELECT *
FROM `bigquery-public-data.new_york_citibike.citibike_trips` 
LIMIT 10

-- Data Cleaning Methods
-- Creating a temp table and removing null and empty values, Removing Duplicates
WITH cleaned_trips AS (
  SELECT DISTINCT * 
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE starttime IS NOT NULL
    AND stoptime IS NOT NULL
    AND bikeid IS NOT NULL
    AND start_station_name IS NOT NULL
    AND end_station_name IS NOT NULL
    AND start_station_name != ""
    AND end_station_name != ""
    AND usertype IN ("Subscriber", "Customer") 
    AND tripduration > 60
)
--  Viewing the new temp table
SELECT *
FROM cleaned_trips
LIMIT 100

--  Sorting data into usertypes
SELECT usertype, COUNT(*) AS total_rides
FROM cleaned_trips
GROUP BY usertype
ORDER BY total_rides DESC

-- Calcualting average tripduration(mins) by usertype
SELECT usertype, ROUND(AVG(tripduration)/60, 2) AS avg_duration_mins
FROM cleaned_trips
GROUP BY usertype
ORDER BY avg_duration_mins 

--  Hours with the most trips
SELECT EXTRACT(Hour from starttime) AS hour_of_the_day, COUNT(*) as ridecounts
FROM cleaned_trips
GROUP BY hour_of_the_day
ORDER BY ridecounts DESC

--  Peak days for rides
SELECT FORMAT_DATE('%A', DATE(starttime)) AS day_of_week, usertype, COUNT(*) AS ridecounts
FROM cleaned_trips
GROUP BY day_of_week, usertype
ORDER BY day_of_week, ridecounts DESC;

--  Weekdays vs Weekends Ride Volume
SELECT
  CASE 
    WHEN EXTRACT(DAYOFWEEK from starttime) =1 OR EXTRACT(DAYOFWEEK from starttime) = 7 THEN 'Weekends'
    ELSE 'Weekdays'
  END AS day_type,
  COUNT(*) AS ride_counts
FROM cleaned_trips
GROUP BY day_type

#Most popular start and end stations
SELECT start_station_name, end_station_name, COUNT(*) AS trip_count,
FROM cleaned_trips
GROUP BY start_station_name,end_station_name
ORDER BY trip_count DESC
LIMIT 10

--  Total Rides By Seasons
SELECT 
  CASE
    WHEN EXTRACT(Month from starttime) IN (12,1,2) THEN "Winter"
    WHEN EXTRACT(Month from starttime) IN (6,7,8) THEN "Summer"
    WHEN EXTRACT(Month from starttime) IN (3,4,5) THEN "Spring"
    WHEN EXTRACT(Month from starttime) IN (9,10,11) THEN "Fall"
  END AS Season,
  COUNT(*) AS Totalrides
  FROM cleaned_trips
  GROUP BY Season
  ORDER BY Totalrides

--  Duration bucket by user type
SELECT 
  usertype,
  CASE 
    WHEN tripduration < 300 THEN 'Under 5 min'
    WHEN tripduration BETWEEN 300 AND 900 THEN '5-15 min'
    WHEN tripduration BETWEEN 901 AND 1800 THEN '15-30 min'
    WHEN tripduration BETWEEN 1801 AND 3600 THEN '30-60 min'
    ELSE 'Over 60 min'
  END AS duration_bucket,
  COUNT(*) AS trip_count
FROM cleaned_trips
GROUP BY usertype, duration_bucket
ORDER BY usertype, trip_count DESC;

# Finding top 10 bike types by id
SELECT bikeid, COUNT(*) AS totalrides
FROM cleaned_trips
GROUP BY bikeid
ORDER BY totalrides DESC
LIMIT 10

--  Joining tables - top 10 stations with the most rides
SELECT s.name AS station_name,
       s.capacity,
       COUNT(*) AS total_trips
FROM cleaned_trips c
JOIN `bigquery-public-data.new_york_citibike.citibike_stations` s
ON c.start_station_name = s.name
WHERE s.name IS NOT NULL
  AND s.capacity IS NOT NULL
GROUP BY s.name, s.capacity
ORDER BY total_trips DESC
LIMIT 10;

-- Selecting a random sample of 500 stations with their capacity and trip counts
SELECT *
FROM (
  SELECT 
    s.name AS station_name,           -- Get the official station name from metadata
    s.capacity,                       -- Get the number of docks (bike capacity)
    COUNT(*) AS total_trips           -- Count how many trips originated from each station
  FROM cleaned_trips c
  JOIN `bigquery-public-data.new_york_citibike.citibike_stations` s
    ON c.start_station_name = s.name  -- Join by station name 
  WHERE s.name IS NOT NULL            -- Remove null station names
    AND s.capacity IS NOT NULL        -- Only include stations with valid capacity info
  GROUP BY s.name, s.capacity         -- Group by station name and its capacity to count trips
)
ORDER BY RAND()                       -- Randomly shuffle the grouped results
LIMIT 500;                            -- Limit to 500 rows for visualization sampling



