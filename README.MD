# Kestra GitOps Boilerplate

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions](https://img.shields.io/badge/CI-GitHub%20Actions-blue)](https://github.com/features/actions)
[![Kestra](https://img.shields.io/badge/Kestra-Latest-purple)](https://kestra.io)

> 🎯 **Template Repository**: [Use this template](../../generate) to create your own Kestra GitOps repository with automatic validation and deployment.

Boilerplate for versioning Kestra flows with local Docker validation and automatic deployment via GitHub Actions.

## Prerequisites

- Docker installed and running
- Node.js and npm (for automatic Git hooks)
- A Kestra instance (self-hosted or cloud)

> **Note**: This is a template repository. After creating your repo from this template, replace example flows in `kestra/flows/company/` with your own flows.

## Initial Setup

```bash
# 1. Clone the repository
git clone <your-repo>
cd kestra-gitops-test

# 2. Install dependencies (automatically configures hooks)
npm install

# 3. Validate everything is OK
npm run validate
```

After `npm install`, the **pre-commit hook** is automatically installed via Husky. Every time you commit, validation (`scripts/validate.sh`) runs automatically.

## Project Structure

```
kestra-gitops-test/
├── bin/
│   └── kestra.sh                 # Docker wrapper for Kestra CLI
├── scripts/
│   └── validate.sh               # Validation script (pre-commit)
├── kestra/
│   ├── flows/                    # Flows organized by namespace
│   │   └── company/
│   │       └── hello_world.yml   # Example flow (replace with yours)
│   └── files/                    # Namespace files (optional)
│       └── company/
│           └── example.txt       # Example file (replace with yours)
├── .husky/
│   └── pre-commit                # Automatic validation hook
├── .github/
│   └── workflows/
│       └── kestra-deploy.yml     # Deployment pipeline
├── docs/
│   ├── adding-environments.md    # How to add new environments
│   └── adding-flows.md           # How to add new flows
├── docker-compose.kestra.yml     # Local Kestra (development)
├── package.json                  # npm/Husky configuration
└── README.MD
```

## How It Works

### Folder Convention → Namespace

The folder structure automatically determines the flow namespace:

```
kestra/flows/company/hello_world.yml
             └─────┘ └─────────┘
             namespace  flow id
             (/ becomes .)
```

In the flow YAML:
```yaml
id: hello_world
namespace: company
```

### Local Validation

The `scripts/validate.sh` script validates:

1. **Structure**: `id` and `namespace` match file path/name
2. **Syntax**: executes `flow validate --local` in ephemeral Docker container

Run manually:

```bash
npm run validate
# or directly
./scripts/validate.sh
```

### Automatic Deployment

- Push to **`prod`** branch → deploy to production server (environment `Production`)
- Pull requests → validation only (no deployment)

The workflow dynamically discovers all namespaces and deploys each one.

## Useful Commands

### Manual Validation

```bash
# Via npm script
npm run validate

# Or directly
./scripts/validate.sh
```

### Git Hooks

The project uses **Husky** to run automatic validation before each commit:
- ✅ Validates folder/namespace structure
- ✅ Validates YAML syntax of flows
- ❌ Blocks commit if there are errors

To bypass (use with caution):
```bash
git commit --no-verify -m "message"
```

### Validate Flow Syntax

```bash
./bin/kestra.sh flow validate --local kestra/flows/company/hello_world.yml
```

### Start Local Kestra

```bash
docker compose -f docker-compose.kestra.yml up -d
```

Access at: `http://localhost:8080`

### Create Local Alias

```bash
alias kestra='./bin/kestra.sh'
kestra --version
```

## GitHub Actions and Environments

The repository uses **GitHub Environments** to separate credentials by environment:

- Environment **Production** (branch `prod`)
  - `KESTRA_HOST`: Kestra server URL
  - `KESTRA_USER`: Email/username
  - `KESTRA_PASSWORD`: Password

To add new environments (staging, dev), see: **[docs/adding-environments.md](docs/adding-environments.md)**

## Adding New Flows

Follow the folder convention and see the complete guide at: **[docs/adding-flows.md](docs/adding-flows.md)**

Quick example:

```bash
# 1. Create structure
mkdir -p kestra/flows/company/pipelines

# 2. Create flow
cat > kestra/flows/company/pipelines/daily_sync.yml << 'EOF'
id: daily_sync
namespace: company.pipelines

tasks:
  - id: sync
    type: io.kestra.plugin.core.log.Log
    message: "Syncing..."
EOF

# 3. Validate
./scripts/validate.sh

# 4. Commit
git add kestra/flows/company/pipelines/daily_sync.yml
git commit -m "Add daily sync pipeline"
git push origin prod
```

## Documentation

- **[Adding Environments](docs/adding-environments.md)** - How to create staging, dev, etc
- **[Adding Flows](docs/adding-flows.md)** - Conventions and best practices

## Environment Architecture

There is no environment separation by folders in the repository. The same code is deployed to different servers, determined by the GitHub Environment of the branch:

```
Repository (same flow structure)
  │
  ├─ branch prod ──────→ Kestra Production (via environment Production)
  │
  └─ branch staging ───→ Kestra Staging (via environment Staging, when created)
```

---

**Initial setup**: validate everything works by running `npm run validate` ✅

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.
