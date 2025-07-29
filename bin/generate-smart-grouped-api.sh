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

echo -e "${GREEN}[INFO]${NC} Starting smart auto-grouped API documentation generation..."

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

# Create a Node.js script to filter OpenAPI and later group files
echo -e "${YELLOW}[STEP 1]${NC} Creating OpenAPI filter script..."

cat > filter_and_group.js << 'EOF'
const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');

function filterOpenAPI(inputFile, outputApiFile) {
    try {
        // Read and parse the OpenAPI file
        const fileContents = fs.readFileSync(inputFile, 'utf8');
        const openApiSpec = yaml.load(fileContents);
        
        console.log(`📖 Loaded OpenAPI spec with ${Object.keys(openApiSpec.paths || {}).length} total paths`);
        
        // Track filtered endpoints
        let filteredCount = 0;
        
        // Filter paths
        const filteredPaths = {};
        
        for (const [pathName, pathItem] of Object.entries(openApiSpec.paths || {})) {
            let shouldInclude = true;
            
            // Skip admin paths
            if (pathName.startsWith('/v1/admin/')) {
                console.log(`🚫 Filtering admin path: ${pathName}`);
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
                        console.log(`🚫 Filtering internal tagged endpoint: ${method.toUpperCase()} ${pathName}`);
                        includeMethod = false;
                        filteredCount++;
                    }
                    
                    if (includeMethod) {
                        filteredMethods[method] = operation;
                    }
                }
                
                // Only include path if it has at least one method left
                if (Object.keys(filteredMethods).length > 0) {
                    filteredPaths[pathName] = filteredMethods;
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
        
        fs.writeFileSync(outputApiFile, filteredYaml, 'utf8');
        console.log(`✅ Filtered OpenAPI spec written to: ${outputApiFile}`);
        console.log(`📊 Summary: ${filteredCount} endpoints filtered, ${Object.keys(filteredPaths).length} paths remaining`);
        
        return true;
    } catch (error) {
        console.error('❌ Error filtering OpenAPI spec:', error.message);
        return false;
    }
}

function groupGeneratedFiles(apiDir, mintConfigFile) {
    try {
        console.log(`📁 Reading generated files from: ${apiDir}`);
        
        // Read existing mint.json
        const mintConfig = JSON.parse(fs.readFileSync(mintConfigFile, 'utf8'));
        
        // Define logical group mappings
        const logicalGroups = {
            'Assets': ['assets', 'enumerations', 'asset', 'enumeration'],
            'Templates': ['templates', 'templatev2'],
            'Scans': ['scans', 'scan'],
            'Results': ['results', 'retests'],
            'Configurations': ['configurations'],
            'Users': ['users', 'user'],
            'Logs': ['elog', 'scan_log', 'history'],
            'Export': ['export'],
            'Automations': ['automations'],
            'Integration': ['oauth'],
            'Utilities': ['chaos', 'vulns', 'leaks', 'billing', 'usage']
        };
        
        // Recursively find all MDX files
        function findMdxFiles(dir, basePath = '') {
            const files = [];
            const items = fs.readdirSync(dir);
            
            for (const item of items) {
                const fullPath = path.join(dir, item);
                const relativePath = basePath ? `${basePath}/${item}` : item;
                
                if (fs.statSync(fullPath).isDirectory()) {
                    files.push(...findMdxFiles(fullPath, relativePath));
                } else if (item.endsWith('.mdx')) {
                    files.push(relativePath.replace('.mdx', ''));
                }
            }
            
            return files;
        }
        
        // Get all generated MDX files
        const allFiles = findMdxFiles(apiDir);
        console.log(`📄 Found ${allFiles.length} generated MDX files`);
        
        // Group files by their directory (which corresponds to OpenAPI tags)
        const groupedFiles = {};
        const ungroupedFiles = [];
        
        for (const file of allFiles) {
            if (file === 'introduction') {
                continue; // Skip introduction file
            }
            
            const parts = file.split('/');
            if (parts.length >= 2) {
                const directory = parts[0];
                const filePath = `api-reference/${file}`;
                
                // Find which logical group this directory belongs to
                let assignedGroup = null;
                for (const [groupName, directories] of Object.entries(logicalGroups)) {
                    if (directories.includes(directory)) {
                        assignedGroup = groupName;
                        break;
                    }
                }
                
                if (assignedGroup) {
                    if (!groupedFiles[assignedGroup]) {
                        groupedFiles[assignedGroup] = [];
                    }
                    groupedFiles[assignedGroup].push(filePath);
                } else {
                    console.log(`❓ Ungrouped directory "${directory}": ${filePath}`);
                    ungroupedFiles.push(filePath);
                }
            } else {
                ungroupedFiles.push(`api-reference/${file}`);
            }
        }
        
        // Generate new navigation structure
        const newGroups = [];
        
        // Add introduction
        newGroups.push("api-reference/introduction");
        
        // Add grouped files
        for (const [groupName, files] of Object.entries(groupedFiles)) {
            if (files.length > 0) {
                // Sort files alphabetically
                files.sort();
                newGroups.push({
                    group: groupName,
                    pages: files
                });
                console.log(`📁 ${groupName}: ${files.length} endpoints`);
            }
        }
        
        // Add ungrouped files if any
        if (ungroupedFiles.length > 0) {
            ungroupedFiles.sort();
            newGroups.push({
                group: "Other",
                pages: ungroupedFiles
            });
            console.log(`📁 Other: ${ungroupedFiles.length} endpoints`);
        }
        
        // Update mint.json navigation
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
        console.log(`📁 Created ${newGroups.length - 1} logical groups`); // -1 for introduction
        
        return true;
    } catch (error) {
        console.error('❌ Error grouping files:', error.message);
        return false;
    }
}

// Get command line arguments
const action = process.argv[2];

if (action === 'filter') {
    const inputFile = process.argv[3];
    const outputFile = process.argv[4];
    const success = filterOpenAPI(inputFile, outputFile);
    process.exit(success ? 0 : 1);
} else if (action === 'group') {
    const apiDir = process.argv[3];
    const mintConfigFile = process.argv[4];
    const success = groupGeneratedFiles(apiDir, mintConfigFile);
    process.exit(success ? 0 : 1);
} else {
    console.error('Usage: node filter_and_group.js <filter|group> [args...]');
    process.exit(1);
}
EOF

# Install js-yaml if not already installed
echo -e "${YELLOW}[STEP 2]${NC} Installing dependencies..."
if ! npm list js-yaml >/dev/null 2>&1; then
    npm install js-yaml
fi

# Step 1: Filter OpenAPI
echo -e "${YELLOW}[STEP 3]${NC} Filtering OpenAPI specification..."
node filter_and_group.js filter "$OPENAPI_SOURCE" "$FILTERED_OPENAPI"

if [[ ! -f "$FILTERED_OPENAPI" ]]; then
    echo -e "${RED}[ERROR]${NC} Failed to create filtered OpenAPI file!"
    exit 1
fi

# Step 2: Generate API documentation using Mintlify scraping
echo -e "${YELLOW}[STEP 4]${NC} Generating API documentation with Mintlify..."
npx @mintlify/scraping@latest openapi-file "$FILTERED_OPENAPI" -o "$OUTPUT_DIR"

# Step 3: Read actual generated files and create navigation
echo -e "${YELLOW}[STEP 5]${NC} Creating navigation based on actual generated files..."
node filter_and_group.js group "$OUTPUT_DIR" "$MINT_CONFIG"

# Clean up temporary files
echo -e "${YELLOW}[STEP 6]${NC} Cleaning up temporary files..."
rm -f filter_and_group.js

echo -e "${GREEN}[SUCCESS]${NC} Smart auto-grouped API documentation generated successfully!"
echo -e "${GREEN}[INFO]${NC} Documentation available in: $OUTPUT_DIR"
echo -e "${GREEN}[INFO]${NC} Navigation automatically updated in: $MINT_CONFIG"
echo -e "${GREEN}[INFO]${NC} All endpoints grouped based on actual generated files!"
echo -e "${BLUE}[NEXT]${NC} Run 'mintlify dev' to preview your documentation" 