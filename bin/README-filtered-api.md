# Filtered API Documentation Generator

This script generates API documentation from an OpenAPI specification while excluding internal and admin endpoints.

## Usage

```bash
# Use default source file (Downloads directory)
./bin/generate-filtered-api.sh

# Use custom source file
./bin/generate-filtered-api.sh /path/to/your/openapi.yaml
```

**Note:** The script will create a filtered `openapi.yaml` file in the current directory for Mintlify to use.

## What gets filtered out

The script automatically excludes:

1. **Admin APIs**: All paths starting with `/v1/admin/`
   - Examples: `/v1/admin/user/search`, `/v1/admin/team/change_owner`

2. **Internal APIs**: Endpoints tagged with `internal`
   - Any endpoint with `"internal"` in its tags array

## Output

- Creates filtered API documentation in the `api-reference/` directory
- Removes existing `internal/` and `admin/` folders before regenerating
- Uses Mintlify scraping to generate MDX files for each endpoint
- Provides detailed console output showing what was filtered

## Requirements

- Node.js and npm/npx
- Internet connection (to download @mintlify/scraping package)
- Valid OpenAPI 3.x specification file

## Integration with existing workflow

You can replace the existing `./bin/generate-api.sh` call in your build process with:

```bash
# Old way (includes internal/admin APIs)
./bin/generate-api.sh

# New way (excludes internal/admin APIs)  
./bin/generate-filtered-api.sh
```

## Troubleshooting

If you encounter errors:

1. **"OpenAPI source file not found"**: Ensure the file path is correct
2. **"Node.js is required"**: Install Node.js from https://nodejs.org
3. **Network errors**: Check internet connection for npm package downloads
4. **Permission errors**: Ensure the script is executable (`chmod +x bin/generate-filtered-api.sh`) 