# Auto-Grouped API Documentation Generator

This script **automatically generates and maintains** API documentation with logical grouping based on OpenAPI tags. It combines the best of both worlds: auto-generation (no missing endpoints) and logical organization.

## Usage

```bash
# Use default source file (Downloads directory)
./bin/generate-auto-grouped-api.sh

# Use custom source file  
./bin/generate-auto-grouped-api.sh /path/to/your/openapi.yaml
```

## What it does

### 🤖 **Auto-Generation**
- Reads OpenAPI specification
- Filters out admin and internal APIs
- Generates MDX files for all public endpoints  
- **Never misses endpoints** - everything is included automatically

### 📁 **Logical Grouping** 
The script organizes endpoints into logical groups based on OpenAPI tags:

- **Assets** → `assets` + `enumerations` tags
- **Templates** → `templates` + `template/v2` tags  
- **Scans** → `scans` tag
- **Results** → `results` + `retests` tags
- **Configurations** → `configurations` tag
- **Users** → `users` + `user` tags
- **Logs** → `elog` + `scan_log` tags
- **Export** → `export` tag
- **Automations** → `automations` tag
- **Integration** → `oauth` tag  
- **Utilities** → `chaos`, `vulns`, `leaks`, `billing`, `usage` tags

### 🔄 **Auto-Updates Navigation**
- Automatically updates `mint.json` with new structure
- Maintains logical grouping
- Sorts endpoints alphabetically within groups
- Handles new endpoints automatically

## Benefits

✅ **No Manual Maintenance** - Add new endpoints to OpenAPI spec and they appear automatically  
✅ **Never Miss Endpoints** - All public endpoints are included  
✅ **Logical Organization** - Grouped by functionality, not alphabetically  
✅ **Consistent Naming** - Uses OpenAPI summaries and operation IDs  
✅ **Future-Proof** - Works with any OpenAPI specification changes

## Output Structure

After running, your `mint.json` will have clean navigation like:

```json
{
  "group": "API Reference",
  "pages": [
    "api-reference/introduction",
    {
      "group": "Assets", 
      "pages": [
        "api-reference/assets/get-asset-list",
        "api-reference/assets/upload-asset",
        "api-reference/enumerations/create-enumeration",
        "..."
      ]
    },
    {
      "group": "Templates",
      "pages": [
        "api-reference/templates/create-template",
        "api-reference/templates/get-template-list",
        "..."
      ]
    }
  ]
}
```

## Comparison with Manual Approach

| Feature | Manual (`generate-filtered-api.sh`) | Auto-Grouped (`generate-auto-grouped-api.sh`) |
|---------|--------------------------------------|-----------------------------------------------|
| **Missing Endpoints** | ❌ Requires manual addition to `mint.json` | ✅ Never - all endpoints auto-included |
| **Logical Grouping** | ✅ Full manual control | ✅ Smart tag-based grouping |
| **Maintenance** | ❌ High - update `mint.json` for new endpoints | ✅ Zero - fully automated |
| **Consistency** | ❌ Depends on manual updates | ✅ Always consistent |
| **New API Versions** | ❌ Manual review and updates needed | ✅ Automatically handles changes |

## When to Use

**Use Auto-Grouped when:**
- You want zero maintenance overhead
- You frequently add/remove API endpoints  
- You have a team that might forget to update navigation
- You want consistent organization based on API design

**Use Manual when:**
- You need very specific custom grouping that doesn't match tags
- You want to exclude certain public endpoints from docs
- You have complex navigation requirements

## Next Steps

After running this script:

1. **Preview:** `mintlify dev`
2. **Deploy:** Your CI/CD can run this script automatically when OpenAPI changes
3. **Customize:** Modify the `logicalGroups` mapping in the script if needed 