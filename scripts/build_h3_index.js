const fs = require('fs');
const path = require('path');
const h3 = require('h3-js');

const DATA_DIR = path.join(__dirname, '../data/raw/bengaluru_safety_data/bengaluru_safety_data');
const OUT_DIR = path.join(__dirname, '../data/processed');
const OUT_FILE = path.join(OUT_DIR, 'h3_safety_scores.json');

const POI_URBAN = path.join(DATA_DIR, 'osm_pois_urban.json');
const POI_RURAL = path.join(DATA_DIR, 'osm_pois_rural.json');

const H3_RESOLUTION = 9;

if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

console.log("Starting H3 Heuristic Pipeline...");

// Initialize base scores
const h3Scores = {};
const h3Factors = {};

function processPOIFile(filePath) {
  if (!fs.existsSync(filePath)) {
    console.log(`Skipping missing file: ${filePath}`);
    return;
  }
  
  console.log(`Processing ${path.basename(filePath)}...`);
  const rawData = fs.readFileSync(filePath, 'utf8');
  const json = JSON.parse(rawData);
  
  if (!json.data || !Array.isArray(json.data)) return;
  
  json.data.forEach(node => {
    if (node.lat && node.lon && node.tags) {
      const h3Index = h3.latLngToCell(node.lat, node.lon, H3_RESOLUTION);
      
      if (!h3Scores[h3Index]) {
        h3Scores[h3Index] = 50; // Base score
        h3Factors[h3Index] = new Set();
      }
      
      const amenity = node.tags.amenity;
      const shop = node.tags.shop;
      
      if (amenity === 'police') {
        h3Scores[h3Index] += 30;
        h3Factors[h3Index].add('Police station nearby');
        // Boost neighbors
        const neighbors = h3.gridDisk(h3Index, 1);
        neighbors.forEach(n => {
            if (n !== h3Index) {
                h3Scores[n] = (h3Scores[n] || 50) + 10;
                if (!h3Factors[n]) h3Factors[n] = new Set();
                h3Factors[n].add('Police patrols nearby');
            }
        });
      }
      else if (amenity === 'hospital' || amenity === 'clinic') {
        h3Scores[h3Index] += 15;
        h3Factors[h3Index].add('Medical help nearby');
      }
      else if (amenity === 'pub' || amenity === 'bar' || amenity === 'nightclub') {
        h3Scores[h3Index] -= 15;
        h3Factors[h3Index].add('Late night venues');
      }
      else if (amenity === 'school' || amenity === 'university') {
        h3Scores[h3Index] += 5;
        h3Factors[h3Index].add('School zone');
      }
      else if (shop === 'alcohol' || shop === 'beverages') {
        h3Scores[h3Index] -= 10;
        h3Factors[h3Index].add('Liquor store area');
      }
    }
  });
}

processPOIFile(POI_URBAN);
processPOIFile(POI_RURAL);

// Normalize and format output
const finalData = {};
let maxScore = -1000;
let minScore = 1000;

Object.keys(h3Scores).forEach(hex => {
    let score = h3Scores[hex];
    // Clamp between 10 (Very Dangerous) and 95 (Very Safe)
    score = Math.max(10, Math.min(95, score));
    
    finalData[hex] = {
        score: score,
        factors: Array.from(h3Factors[hex] || [])
    };
    
    if (score > maxScore) maxScore = score;
    if (score < minScore) minScore = score;
});

fs.writeFileSync(OUT_FILE, JSON.stringify(finalData, null, 2));

console.log(`Pipeline complete! Indexed ${Object.keys(finalData).length} H3 cells.`);
console.log(`Scores range from ${minScore} to ${maxScore}`);
console.log(`Output saved to: ${OUT_FILE}`);
