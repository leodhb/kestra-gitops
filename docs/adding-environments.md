# Adding New Environments

This guide explains how to add new environments (staging, development, etc) to the Kestra GitOps setup.

## Concept

In this repository, **there is no environment separation by folders**. The same flow structure is deployed to different Kestra servers, determined by GitHub Environment secrets.

## Step by Step

### 1. Create GitHub Environment

1. Go to **Settings → Environments** in the repository
2. Click **New environment**
3. Give it a name (e.g., `Staging`, `Development`)
4. Configure protections if needed:
   - **Required reviewers**: require manual approval before deployment
   - **Wait timer**: delay before deployment
   - **Deployment branches**: restrict to specific branches

### 2. Add Secrets to Environment

Within the created environment, add the following secrets:

| Secret | Description | Example |
|--------|-----------|---------|
| `KESTRA_HOST` | Kestra server URL | `https://kestra-staging.example.com` |
| `KESTRA_USER` | Authentication email/username | `admin@kestra.io` |
| `KESTRA_PASSWORD` | Authentication password | `your-secure-password` |

### 3. Create Corresponding Branch

Create a branch in the repository that corresponds to the environment:

```bash
git checkout -b staging
git push -u origin staging
```

### 4. Add Job to Workflow

Edit `.github/workflows/kestra-deploy.yml` and add a job for the new environment:

```yaml
  # Deploy flows for staging
  deploy-flows-staging:
    if: github.event_name == 'push' && github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    environment: Staging  # GitHub Environment name
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Kestra CLI
        run: curl -s https://get.kestra.io | bash
      
      - name: Deploy flows to Kestra
        env:
          KESTRA_HOST: ${{ secrets.KESTRA_HOST }}
          KESTRA_USER: ${{ secrets.KESTRA_USER }}
          KESTRA_PASSWORD: ${{ secrets.KESTRA_PASSWORD }}
        run: |
          # ... (same script as original deploy-flows)
```

Also duplicate the `deploy-files` job if you use namespace files.

### 5. Test Deployment

1. Commit a change to the new environment's branch
2. Push to remote: `git push origin staging`
3. Monitor execution in **Actions** on GitHub
4. Verify on the Kestra server that flows were deployed

## Typical Workflow

```
┌──────────────┐
│ Developer    │
│ push code    │
└──────┬───────┘
       │
       ├─── push to staging ──→ Automatic deploy to Kestra Staging
       │
       └─── push to prod ─────→ Automatic deploy to Kestra Production
```

## Best Practices

- **Always test in staging before prod**: create PR from `staging` → `prod`
- **Protect prod branch**: configure branch protection rules to require approval
- **Use required reviewers on Production environment**: prevents accidental deployments
- **Keep secrets separate per environment**: never share credentials between environments
- **Name environments with capital letter**: `Production`, `Staging` (GitHub standard)

## Troubleshooting

### Error: environment not found

Verify that the environment name in the workflow (`environment: Staging`) exactly matches the name created on GitHub (case-sensitive).

### Secrets not found

- Ensure secrets are in the **environment**, not in repository secrets
- The job must declare `environment: EnvironmentName` to access the secrets

### Deployment doesn't trigger

- Verify the job's `if` condition is correct for the branch
- Confirm the push was to the branch monitored in `on.push.branches`
