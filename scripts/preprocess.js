const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '../data/safety-navigation-data');
const CRIME_FILE = path.join(DATA_DIR, 'crime/raw.json');
const LIGHTING_FILE = path.join(DATA_DIR, 'lighting/raw.json');
const OUT_DIR = path.join(DATA_DIR, 'processed');
const OUT_FILE = path.join(OUT_DIR, 'output.json');

// Ensure output directory exists
if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

console.log("Starting Safety Data Preprocessing Pipeline (Mock S3)...");

// Read datasets
const crimeData = JSON.parse(fs.readFileSync(CRIME_FILE, 'utf8'));
const segmentData = JSON.parse(fs.readFileSync(LIGHTING_FILE, 'utf8'));

// Convert crime data to a lookup dictionary based on region_id
// We use geographic resolution of 'region_id' because exact road-level crime data is unavailable.
const crimeLookup = {};
crimeData.forEach(c => {
  // Normalize crime to a 0-1 density (mock logic: over 50 is max density)
  crimeLookup[c.region_id] = Math.min(c.incidents_reported / 50, 1.0).toFixed(2);
});

// Process each segment
const processedSegments = segmentData.map(segment => {
  // Normalize lighting density (lights per 10 meters)
  let lightingDensity = (segment.street_lights / (segment.length_meters / 10));
  lightingDensity = Math.min(lightingDensity, 1.0).toFixed(2);

  // Normalize activity level
  let activityDensity = 0.5;
  if (segment.activity_level === 'high') activityDensity = 0.9;
  if (segment.activity_level === 'medium') activityDensity = 0.6;
  if (segment.activity_level === 'low') activityDensity = 0.3;
  if (segment.activity_level === 'very_low') activityDensity = 0.1;

  // Retrieve regional crime density
  const crimeDensity = crimeLookup[segment.region_id] || 0.5;

  return {
    segment_id: segment.segment_id,
    crime_density: parseFloat(crimeDensity),
    lighting_density: parseFloat(lightingDensity),
    activity_density: activityDensity
  };
});

fs.writeFileSync(OUT_FILE, JSON.stringify(processedSegments, null, 2));

console.log(`Successfully processed ${processedSegments.length} road segments.`);
console.log(`Output saved to: ${OUT_FILE}`);
console.log("\nSample Output:");
console.log(JSON.stringify(processedSegments[0], null, 2));
