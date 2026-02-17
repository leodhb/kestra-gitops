# Adicionando novos ambientes

Este guia explica como adicionar novos ambientes (staging, development, etc) ao setup GitOps do Kestra.

## Conceito

Neste repositório, **não existe separação de ambiente por pastas**. A mesma estrutura de flows é deployada para servidores Kestra diferentes, determinados pelos secrets do GitHub Environment.

## Passo a passo

### 1. Criar GitHub Environment

1. Vá em **Settings → Environments** no repositório
2. Clique em **New environment**
3. Dê um nome (ex: `Staging`, `Development`)
4. Configure proteções se necessário:
   - **Required reviewers**: exigir aprovação manual antes do deploy
   - **Wait timer**: atraso antes do deploy
   - **Deployment branches**: restringir a branches específicas

### 2. Adicionar secrets ao environment

Dentro do environment criado, adicione os seguintes secrets:

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `KESTRA_HOST` | URL do servidor Kestra | `https://kestra-staging.exemplo.com` |
| `KESTRA_USER` | Email/usuário de autenticação | `admin@kestra.io` |
| `KESTRA_PASSWORD` | Senha de autenticação | `sua-senha-segura` |

### 3. Criar branch correspondente

Crie uma branch no repositório que corresponda ao ambiente:

```bash
git checkout -b staging
git push -u origin staging
```

### 4. Adicionar job no workflow

Edite `.github/workflows/kestra-deploy.yml` e adicione um job para o novo ambiente:

```yaml
  # Deploy de flows para staging
  deploy-flows-staging:
    if: github.event_name == 'push' && github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    environment: Staging  # Nome do GitHub Environment
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
          # ... (mesmo script do deploy-flows original)
```

Duplique também o job `deploy-files` se você usar namespace files.

### 5. Testar o deploy

1. Faça commit de uma mudança na branch do novo ambiente
2. Push para o remote: `git push origin staging`
3. Acompanhe a execução em **Actions** no GitHub
4. Verifique no servidor Kestra se os flows foram deployados

## Fluxo de trabalho típico

```
┌──────────────┐
│ Developer    │
│ push código  │
└──────┬───────┘
       │
       ├─── push para staging ──→ Deploy automático para Kestra Staging
       │
       └─── push para prod ─────→ Deploy automático para Kestra Production
```

## Boas práticas

- **Sempre teste em staging antes de prod**: crie PR de `staging` → `prod`
- **Proteja a branch prod**: configure branch protection rules para exigir aprovação
- **Use required reviewers no environment Production**: evita deploys acidentais
- **Mantenha secrets separados por ambiente**: nunca compartilhe credenciais entre ambientes
- **Nomeie environments com maiúscula**: `Production`, `Staging` (padrão GitHub)

## Troubleshooting

### Erro: environment not found

Verifique se o nome do environment no workflow (`environment: Staging`) bate exatamente com o nome criado no GitHub (case-sensitive).

### Secrets não são encontrados

- Certifique-se de que os secrets estão no **environment**, não nos repository secrets
- O job precisa declarar `environment: NomeDoEnvironment` para ter acesso aos secrets

### Deploy não triggera

- Verifique se o `if` do job está correto para a branch
- Confirme que o push foi para a branch monitorada no `on.push.branches`
