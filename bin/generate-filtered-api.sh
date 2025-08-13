#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
OPENAPI_SOURCE="${1:-/Users/nikhil/Downloads/openapi.yaml}"
FILTERED_OPENAPI="openapi.yaml"
OUTPUT_DIR="api-reference"

echo -e "${GREEN}[INFO]${NC} Starting filtered API documentation generation..."

# Check if source OpenAPI file exists
if [[ ! -f "$OPENAPI_SOURCE" ]]; then
    echo -e "${RED}[ERROR]${NC} OpenAPI source file '$OPENAPI_SOURCE' not found!"
    echo "Usage: $0 [openapi-file-path]"
    echo "Default: $0 /Users/nikhil/Downloads/openapi.yaml"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Using OpenAPI source: $OPENAPI_SOURCE"

# Check if required tools are installed
command -v node >/dev/null 2>&1 || { echo -e "${RED}[ERROR]${NC} Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v npx >/dev/null 2>&1 || { echo -e "${RED}[ERROR]${NC} npx is required but not installed. Aborting." >&2; exit 1; }

# Create a Node.js script to filter the OpenAPI spec
echo -e "${YELLOW}[STEP 1]${NC} Creating OpenAPI filter script..."

cat > filter_openapi.js << 'EOF'
const fs = require('fs');
const yaml = require('js-yaml');

function filterOpenAPI(inputFile, outputFile) {
    try {
        // Read and parse the OpenAPI file
        const fileContents = fs.readFileSync(inputFile, 'utf8');
        const openApiSpec = yaml.load(fileContents);
        
        console.log(`📖 Loaded OpenAPI spec with ${Object.keys(openApiSpec.paths || {}).length} total paths`);
        
        // Track filtered endpoints
        let filteredCount = 0;
        let totalCount = 0;
        
        // Filter paths
        const filteredPaths = {};
        
        for (const [path, pathItem] of Object.entries(openApiSpec.paths || {})) {
            totalCount++;
            let shouldInclude = true;
            
            // Skip admin paths
            if (path.startsWith('/v1/admin/')) {
                console.log(`🚫 Filtering admin path: ${path}`);
                shouldInclude = false;
                filteredCount++;
            }
            
            // Check each HTTP method in the path
            if (shouldInclude) {
                const filteredMethods = {};
                
                for (const [method, operation] of Object.entries(pathItem)) {
                    if (typeof operation !== 'object' || operation === null) {
                        filteredMethods[method] = operation;
                        continue;
                    }
                    
                    let includeMethod = true;
                    
                    // Check for internal tag
                    if (operation.tags && operation.tags.includes('internal')) {
                        console.log(`🚫 Filtering internal tagged endpoint: ${method.toUpperCase()} ${path}`);
                        includeMethod = false;
                        filteredCount++;
                    }
                    
                    if (includeMethod) {
                        filteredMethods[method] = operation;
                    }
                }
                
                // Only include path if it has at least one method left
                if (Object.keys(filteredMethods).length > 0) {
                    filteredPaths[path] = filteredMethods;
                }
            }
        }
        
        // Update the spec with filtered paths
        openApiSpec.paths = filteredPaths;
        
        // Write the filtered spec
        const filteredYaml = yaml.dump(openApiSpec, {
            lineWidth: -1,
            noArrayIndent: true,
            quotingType: '"',
            forceQuotes: false
        });
        
        fs.writeFileSync(outputFile, filteredYaml, 'utf8');
        
        console.log(`✅ Filtered OpenAPI spec written to: ${outputFile}`);
        console.log(`📊 Summary: ${filteredCount} endpoints filtered, ${Object.keys(filteredPaths).length} paths remaining`);
        
        return true;
    } catch (error) {
        console.error('❌ Error filtering OpenAPI spec:', error.message);
        return false;
    }
}

// Get command line arguments
const inputFile = process.argv[2];
const outputFile = process.argv[3];

if (!inputFile || !outputFile) {
    console.error('Usage: node filter_openapi.js <input-file> <output-file>');
    process.exit(1);
}

// Run the filter
const success = filterOpenAPI(inputFile, outputFile);
process.exit(success ? 0 : 1);
EOF

# Install js-yaml if not already installed
echo -e "${YELLOW}[STEP 2]${NC} Installing dependencies..."
if ! npm list js-yaml >/dev/null 2>&1; then
    npm install js-yaml
fi

# Run the filter script
echo -e "${YELLOW}[STEP 3]${NC} Filtering OpenAPI specification..."
node filter_openapi.js "$OPENAPI_SOURCE" "$FILTERED_OPENAPI"

if [[ ! -f "$FILTERED_OPENAPI" ]]; then
    echo -e "${RED}[ERROR]${NC} Failed to create filtered OpenAPI file!"
    exit 1
fi

# Remove existing internal and admin directories from api-reference
echo -e "${YELLOW}[STEP 4]${NC} Cleaning up existing internal/admin documentation..."
if [[ -d "$OUTPUT_DIR/internal" ]]; then
    echo "🗑️  Removing existing internal API docs..."
    rm -rf "$OUTPUT_DIR/internal"
fi

if [[ -d "$OUTPUT_DIR/admin" ]]; then
    echo "🗑️  Removing existing admin API docs..."
    rm -rf "$OUTPUT_DIR/admin" 
fi

# Generate API documentation using Mintlify scraping
echo -e "${YELLOW}[STEP 5]${NC} Generating API documentation with Mintlify..."
npx @mintlify/scraping@latest openapi-file "$FILTERED_OPENAPI" -o "$OUTPUT_DIR"

# Clean up temporary files
echo -e "${YELLOW}[STEP 6]${NC} Cleaning up temporary files..."
rm -f filter_openapi.js

echo -e "${GREEN}[SUCCESS]${NC} Filtered API documentation generated successfully!"
echo -e "${GREEN}[INFO]${NC} Documentation available in: $OUTPUT_DIR"
echo -e "${GREEN}[INFO]${NC} Filtered OpenAPI spec saved as: $FILTERED_OPENAPI"
echo -e "${GREEN}[INFO]${NC} Admin APIs (/v1/admin/*) and internal tagged endpoints have been excluded from the build" 