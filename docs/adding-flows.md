# Adding New Flows

This guide explains how to add new flows to the repository following the folder structure and namespace convention.

## Mapping Rule

The folder structure automatically determines the flow namespace:

```
kestra/flows/PART1/PART2/PART3/flow_name.yml
                ↓
namespace: PART1.PART2.PART3
id: flow_name
```

### Examples

| File Path | Expected Namespace | Expected ID |
|-------------------|-------------------|-------------|
| `kestra/flows/watxer/_services/github/search_repositories.yml` | `watxer._services.github` | `search_repositories` |
| `kestra/flows/watxer/pipelines/daily_sync.yml` | `watxer.pipelines` | `daily_sync` |
| `kestra/flows/analytics/reports/monthly.yml` | `analytics.reports` | `monthly` |

## Step by Step

### 1. Create Folder Structure

Organize flows by logical namespace. Recommendations:

- Use company/project name as root (e.g., `watxer/`)
- Group related flows in subfolders (e.g., `_services/`, `pipelines/`)
- Use descriptive names in lowercase with underscores

```bash
mkdir -p kestra/flows/watxer/pipelines
```

### 2. Create Flow File

Create the `.yml` file with the name matching the desired `id`:

```yaml
# kestra/flows/watxer/pipelines/daily_sync.yml
id: daily_sync
namespace: watxer.pipelines

description: Daily data synchronization

tasks:
  - id: fetch_data
    type: io.kestra.plugin.core.http.Request
    uri: https://api.example.com/data
    
  - id: process
    type: io.kestra.plugin.scripts.python.Script
    script: |
      print("Processing data...")
```

**IMPORTANT**: The `namespace` and `id` in the YAML **must** match the folder convention. The validation hook will reject if they don't match.

### 3. Validate Locally

Before committing, run the validation script:

```bash
npm run validate
```

The script validates:
- ✅ Flow `id` = file name
- ✅ Flow `namespace` = folder path (converted with `.`)
- ✅ Valid YAML syntax (via Docker)

### 4. Test Syntax Manually (Optional)

Use the Docker wrapper to validate a specific flow:

```bash
./bin/kestra.sh flow validate --local kestra/flows/watxer/pipelines/daily_sync.yml
```

### 5. Commit and Push

```bash
git add kestra/flows/watxer/pipelines/daily_sync.yml
git commit -m "Add daily sync pipeline"
git push origin staging  # or prod, depending on environment
```

GitHub Actions will:
1. Validate structure (if PR)
2. Automatically deploy to Kestra (if push to `prod` or `staging`)

## Naming Conventions

### Namespaces

- Use short, descriptive names
- Prefer lowercase
- Use underscore `_` if needed (e.g., `_services`)
- Avoid too many levels (maximum 4-5 recommended)

**Good:**
- `watxer._services.github`
- `analytics.reports`
- `etl.daily`

**Avoid:**
- `MyCompany.Services.Integration.External.GitHub` (too long)
- `temp` (not descriptive)

### Flow IDs

- Use snake_case (lowercase with underscores)
- Be descriptive about what the flow does
- Avoid generic IDs like `flow1`, `test`

**Good:**
- `search_repositories`
- `send_slack_notification`
- `monthly_report`

**Avoid:**
- `flow1` (not descriptive)
- `SearchRepositories` (use snake_case)
- `temp_test` (temporary)

## Organizing Flows by Type

### By Business Domain

```
kestra/flows/
  watxer/
    sales/          # Sales flows
    marketing/       # Marketing flows
    analytics/       # Analytics flows
```

### By Technical Function

```
kestra/flows/
  watxer/
    _services/      # External API integrations
    pipelines/      # ETL and data processing
    notifications/  # Alert sending
```

### Mixed (Recommended)

```
kestra/flows/
  watxer/
    _services/
      github/
      slack/
      salesforce/
    pipelines/
      daily/
      hourly/
    analytics/
      reports/
```

## Namespace Files (Static Files)

If the flow uses static files (configs, scripts, etc), place them in `kestra/files/` following the same namespace:

```
kestra/
  flows/
    watxer/
      pipelines/
        etl_process.yml          # namespace: watxer.pipelines
  files/
    watxer/
      pipelines/
        config.json              # Accessible by flow via namespace files
        transform_script.py
```

In the flow, access via:

```yaml
tasks:
  - id: read_config
    type: io.kestra.plugin.core.storage.LocalFiles
    inputs:
      config.json: "{{ namespace.files.read('config.json') }}"
```

## Troubleshooting

### Error: namespace mismatch

```
❌ kestra/flows/watxer/pipelines/daily_sync.yml
   Namespace mismatch: expected 'watxer.pipelines', got 'watxer.pipeline'
```

**Solution**: Fix the `namespace` in the YAML to match the folder path.

### Error: ID mismatch

```
❌ kestra/flows/watxer/pipelines/daily_sync.yml
   ID mismatch: expected 'daily_sync', got 'daily-sync'
```

**Solution**: Rename the file or fix the `id` in the YAML.

### Invalid Syntax

```
❌ Syntax validation failed: kestra/flows/watxer/pipelines/daily_sync.yml
```

**Solution**: Run `./bin/kestra.sh flow validate --local <file>` to see detailed error.
