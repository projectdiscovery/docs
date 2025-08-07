#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OPENAPI_SOURCE="${1:-/Users/nikhil/Downloads/openapi.yaml}"
FILTERED_OPENAPI="openapi.yaml"
OUTPUT_DIR="api-reference"
MINT_CONFIG="mint.json"

echo -e "${GREEN}[INFO]${NC} Starting auto-grouped API documentation generation..."

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

# Create a Node.js script to filter and auto-generate navigation
echo -e "${YELLOW}[STEP 1]${NC} Creating OpenAPI auto-generation script..."

cat > auto_generate_navigation.js << 'EOF'
const fs = require('fs');
const yaml = require('js-yaml');

function generateFilteredAPIAndNavigation(inputFile, outputApiFile, mintConfigFile) {
    try {
        // Read and parse the OpenAPI file
        const fileContents = fs.readFileSync(inputFile, 'utf8');
        const openApiSpec = yaml.load(fileContents);
        
        console.log(`📖 Loaded OpenAPI spec with ${Object.keys(openApiSpec.paths || {}).length} total paths`);
        
        // Read existing mint.json
        const mintConfig = JSON.parse(fs.readFileSync(mintConfigFile, 'utf8'));
        
        // Track filtered endpoints and group by tags
        let filteredCount = 0;
        const tagGroups = {};
        const ungroupedEndpoints = [];
        
        // Filter paths and group by tags
        const filteredPaths = {};
        
        for (const [path, pathItem] of Object.entries(openApiSpec.paths || {})) {
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
                        
                        // Group by primary tag for navigation
                        const primaryTag = operation.tags && operation.tags[0];
                        if (primaryTag && primaryTag !== 'internal') {
                            if (!tagGroups[primaryTag]) {
                                tagGroups[primaryTag] = [];
                            }
                            
                            // Generate file path (this matches what @mintlify/scraping generates)
                            const operationId = operation.operationId || `${method}-${path.replace(/\//g, '-').replace(/[{}]/g, '')}`;
                            const summary = operation.summary || `${method.toUpperCase()} ${path}`;
                            
                            // Convert operationId to kebab-case filename
                            const fileName = operationId.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
                            const filePath = `api-reference/${primaryTag}/${fileName}`;
                            
                            tagGroups[primaryTag].push({
                                path: filePath,
                                method: method.toUpperCase(),
                                endpoint: path,
                                summary: summary
                            });
                        } else {
                            ungroupedEndpoints.push({
                                method: method.toUpperCase(),
                                endpoint: path,
                                summary: operation.summary || `${method.toUpperCase()} ${path}`
                            });
                        }
                    }
                }
                
                // Only include path if it has at least one method left
                if (Object.keys(filteredMethods).length > 0) {
                    filteredPaths[path] = filteredMethods;
                }
            }
        }
        
        // Update the OpenAPI spec with filtered paths
        openApiSpec.paths = filteredPaths;
        
        // Write the filtered OpenAPI spec
        const filteredYaml = yaml.dump(openApiSpec, {
            lineWidth: -1,
            noArrayIndent: true,
            quotingType: '"',
            forceQuotes: false
        });
        
        fs.writeFileSync(outputApiFile, filteredYaml, 'utf8');
        console.log(`✅ Filtered OpenAPI spec written to: ${outputApiFile}`);
        
        // Define logical group mappings and order
        const logicalGroups = {
            'Assets': ['assets', 'enumerations'],
            'Templates': ['templates', 'template/v2'],
            'Scans': ['scans'],
            'Results': ['results', 'retests'],
            'Configurations': ['configurations'],
            'Users': ['users', 'user'],
            'Logs': ['elog', 'scan_log'],
            'Export': ['export'],
            'Automations': ['automations'],
            'Integration': ['oauth'],
            'Utilities': ['chaos', 'vulns', 'leaks', 'billing', 'usage']
        };
        
        // Generate new navigation structure
        const newGroups = [];
        
        // Add introduction
        newGroups.push("api-reference/introduction");
        
        // Process each logical group
        for (const [groupName, tagNames] of Object.entries(logicalGroups)) {
            const groupPages = [];
            
            for (const tagName of tagNames) {
                if (tagGroups[tagName]) {
                    // Sort endpoints within each tag alphabetically by summary
                    tagGroups[tagName].sort((a, b) => a.summary.localeCompare(b.summary));
                    groupPages.push(...tagGroups[tagName].map(item => item.path));
                    
                    console.log(`📁 ${groupName} (${tagName}): ${tagGroups[tagName].length} endpoints`);
                }
            }
            
            if (groupPages.length > 0) {
                newGroups.push({
                    group: groupName,
                    pages: groupPages
                });
            }
        }
        
        // Handle any ungrouped endpoints
        const ungroupedPages = [];
        for (const [tagName, endpoints] of Object.entries(tagGroups)) {
            const isGrouped = Object.values(logicalGroups).some(tags => tags.includes(tagName));
            if (!isGrouped) {
                console.log(`❓ Ungrouped tag "${tagName}": ${endpoints.length} endpoints`);
                ungroupedPages.push(...endpoints.map(item => item.path));
            }
        }
        
        if (ungroupedPages.length > 0) {
            newGroups.push({
                group: "Other",
                pages: ungroupedPages
            });
        }
        
        // Update mint.json navigation
        // Find the API Reference group and replace it
        let updated = false;
        for (let i = 0; i < mintConfig.navigation.length; i++) {
            if (mintConfig.navigation[i].group === "API Reference") {
                mintConfig.navigation[i].pages = newGroups;
                updated = true;
                break;
            }
        }
        
        if (!updated) {
            console.log("⚠️  API Reference group not found in mint.json");
        }
        
        // Write updated mint.json
        fs.writeFileSync(mintConfigFile, JSON.stringify(mintConfig, null, 2), 'utf8');
        console.log(`✅ Updated navigation in: ${mintConfigFile}`);
        
        console.log(`📊 Summary: ${filteredCount} endpoints filtered, ${Object.keys(filteredPaths).length} paths remaining`);
        console.log(`📁 Created ${newGroups.length - 1} logical groups`); // -1 for introduction
        
        return true;
    } catch (error) {
        console.error('❌ Error:', error.message);
        return false;
    }
}

// Get command line arguments
const inputFile = process.argv[2];
const outputApiFile = process.argv[3];
const mintConfigFile = process.argv[4];

if (!inputFile || !outputApiFile || !mintConfigFile) {
    console.error('Usage: node auto_generate_navigation.js <input-openapi> <output-openapi> <mint-config>');
    process.exit(1);
}

// Run the generator
const success = generateFilteredAPIAndNavigation(inputFile, outputApiFile, mintConfigFile);
process.exit(success ? 0 : 1);
EOF

# Install js-yaml if not already installed
echo -e "${YELLOW}[STEP 2]${NC} Installing dependencies..."
if ! npm list js-yaml >/dev/null 2>&1; then
    npm install js-yaml
fi

# Run the auto-generation script
echo -e "${YELLOW}[STEP 3]${NC} Auto-generating navigation structure..."
node auto_generate_navigation.js "$OPENAPI_SOURCE" "$FILTERED_OPENAPI" "$MINT_CONFIG"

if [[ ! -f "$FILTERED_OPENAPI" ]]; then
    echo -e "${RED}[ERROR]${NC} Failed to create filtered OpenAPI file!"
    exit 1
fi

# Generate API documentation using Mintlify scraping
echo -e "${YELLOW}[STEP 4]${NC} Generating API documentation with Mintlify..."
npx @mintlify/scraping@latest openapi-file "$FILTERED_OPENAPI" -o "$OUTPUT_DIR"

# Clean up temporary files
echo -e "${YELLOW}[STEP 5]${NC} Cleaning up temporary files..."
rm -f auto_generate_navigation.js

echo -e "${GREEN}[SUCCESS]${NC} Auto-grouped API documentation generated successfully!"
echo -e "${GREEN}[INFO]${NC} Documentation available in: $OUTPUT_DIR"
echo -e "${GREEN}[INFO]${NC} Navigation automatically updated in: $MINT_CONFIG"
echo -e "${GREEN}[INFO]${NC} All endpoints are now auto-grouped by logical categories!"
echo -e "${BLUE}[NEXT]${NC} Run 'mintlify dev' to preview your documentation" 