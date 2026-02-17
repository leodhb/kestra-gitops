# Contributing to Kestra GitOps Boilerplate

Thank you for your interest in contributing! 🎉

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Provide clear reproduction steps for bugs
- Include environment details (OS, Docker version, etc.)

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Run validation: `npm run validate`
5. Commit with clear messages
6. Push and create a PR

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/kestra-gitops
cd kestra-gitops

# Install dependencies
npm install

# Validate all flows
npm run validate

# Or validate specific files only (faster)
bash ./scripts/validate.sh --files kestra/flows/company/example/flow.yml
```

### Code Style

- Use clear, descriptive commit messages
- Follow existing code structure
- Keep scripts simple and well-commented
- Test changes locally before pushing

### Testing Changes

Before submitting a PR:

1. Run `npm run validate` to ensure all checks pass
2. Test with local Kestra: `docker compose -f docker-compose.kestra.yml up`
3. Verify workflows syntax (GitHub validates on PR automatically)

**Note:** The pre-commit hook automatically validates only the files you changed, making commits faster. Full validation runs in CI/CD.

## Questions?

Open an issue or start a discussion!
