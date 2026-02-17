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

### 1. Local Setup

```bash
# Clone the repository
git clone <your-repo>
cd kestra-gitops

# Install dependencies (automatically configures hooks)
npm install

# Validate everything is OK
npm run validate
```

After `npm install`, the **pre-commit hook** is automatically installed via Husky. Every time you commit, validation (`scripts/validate.sh`) runs automatically.

### 2. GitHub Environment Configuration (Required for Deployment)

Before pushing to `prod` branch, configure the **Production** environment in GitHub:

1. Go to your repository **Settings** → **Environments** → **New environment**
2. Create environment named: `Production`
3. Add the following **secrets**:
   - `KESTRA_HOST`: Your Kestra server URL (e.g., `https://kestra.example.com`)
   - `KESTRA_USER`: Email or username for authentication
   - `KESTRA_PASSWORD`: Password for authentication

**Without these secrets configured, deployments will fail.** This is expected behavior - the template requires you to configure your own Kestra instance.

For detailed instructions, see: **[docs/adding-environments.md](docs/adding-environments.md)**

## Project Structure

```
kestra-gitops/
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

#### Validation Modes

**Full validation** (validates all flows):
```bash
npm run validate
# or
./scripts/validate.sh
```

**Selective validation** (validates only specific files):
```bash
./scripts/validate.sh --files kestra/flows/company/example.yml kestra/flows/company/other.yml
```

**Performance optimization**: The pre-commit hook automatically validates only the files you changed, making commits much faster. Full validation runs in CI/CD.

**How selective validation works:**
- Pre-commit hook detects staged `.yml`/`.yaml` files in `kestra/flows/`
- Passes only those files to the validation script
- Skips files structure validation (runs only in full mode)
- Significantly faster for development workflow

### Automatic Deployment (CI/CD)

After configuring the GitHub Environment (see [Initial Setup](#2-github-environment-configuration-required-for-deployment)):

- Push to **`prod`** branch → automatic deployment to Production
- Pull requests → validation only (no deployment)
- Only changed namespaces are deployed (optimized for performance)

## Useful Commands

### Manual Validation

```bash
# Validate all flows (runs complete validation)
npm run validate

# Validate specific files only (much faster for development)
./scripts/validate.sh --files kestra/flows/company/example.yml

# Validate multiple specific files
./scripts/validate.sh --files \
  kestra/flows/company/flow1.yml \
  kestra/flows/company/flow2.yml
```

### Git Hooks

The project uses **Husky** to run automatic validation before each commit:
- ✅ Validates folder/namespace structure
- ✅ Validates YAML syntax of flows
- ⚡ Only validates files you changed (fast!)
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

## GitHub Actions Deployment

### How It Works

- Push to **`prod`** branch → automatic deployment to Production environment
- Pull requests → validation only (no deployment)
- The workflow dynamically discovers changed namespaces and deploys only what changed

### Adding More Environments

To add staging, dev, or other environments, see: **[docs/adding-environments.md](docs/adding-environments.md)**

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
