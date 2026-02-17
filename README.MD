# Kestra GitOps Boilerplate

Boilerplate simples para versionar flows do Kestra com validação local via Docker e deploy por GitHub Actions.

## O que este repositório entrega

- Estrutura de pastas para flows em `kestra/flows`
- Hook/script de validação em `.githooks/validate-kestra-structure.sh`
- Wrapper de CLI containerizada em `bin/kestra.sh`
- Exemplo de flow em `kestra/flows/watxer/_services/github/search_repositories.yml`
- Pipeline de deploy em `.github/workflows/kestra-deploy.yml`

## Como funciona a validação

O script `.githooks/validate-kestra-structure.sh` valida:

1. **Estrutura**:
   - `id` do flow igual ao nome do arquivo
   - `namespace` igual ao caminho da pasta
2. **Sintaxe**:
   - usa `bin/kestra.sh`
   - sempre roda em **container efêmero** (`docker run --rm`)
   - valida cada flow com `flow validate --local`

## Wrapper Kestra (Docker)

Use o wrapper como se fosse o binário local:

```bash
bash ./bin/kestra.sh --version
bash ./bin/kestra.sh flow validate --local kestra/flows/watxer/_services/github/search_repositories.yml
```

O wrapper:

- usa a imagem `kestra/kestra:latest` (por padrão)
- monta o repositório em `/ephemeral-kestra-cli-workdir` no container
- falha cedo se Docker não estiver instalado ou rodando

## Rodando validação local

```bash
bash ./.githooks/validate-kestra-structure.sh
```

## Estrutura esperada para flows

Regra:

- `namespace` = caminho relativo dentro de `kestra/flows` com `/` trocado por `.`
- `id` = nome do arquivo (sem extensão)

Exemplo:

```text
kestra/flows/team/services/my_flow.yml
namespace: team.services
id: my_flow
```

## GitHub Actions

O workflow em `.github/workflows/kestra-deploy.yml` está dividido em:

- validação em pull request
- deploy de flows em push (`main` e `develop`)
- deploy de files (quando existir `kestra/files`)

## Ambiente local (opcional)

Se quiser subir uma instância local do Kestra:

```bash
docker compose -f docker-compose.kestra.yml up -d
```

Interface web: `http://localhost:8080`

---

Se quiser, você pode criar um atalho local:

```bash
alias kestra='bash ./bin/kestra.sh'
```

# Kestra GitOps Setup Guide

Guia completo para configurar GitOps com Kestra no macOS.

## 📋 Pré-requisitos

- macOS com Homebrew instalado
- Git configurado
- Acesso a uma instância do Kestra (local ou remota)

---

## 🛠️ Instalação do Kestra CLI

### Opção 1: Homebrew (Recomendado para Mac)

```bash
brew install kestra-io/tap/kestra
```

Verificar instalação:
```bash
kestra --version
```

### Opção 2: Script de instalação

```bash
curl -s https://get.kestra.io | bash
```

### Opção 3: Docker Alias

Se preferir não instalar localmente:

```bash
# Adicionar ao ~/.zshrc ou ~/.bashrc
alias kestra='docker run --rm -v $(pwd):/app kestra/kestra:latest'
```

---

## 📁 Estrutura do Repositório

```
seu-repo/
├── .githooks/
│   └── validate-kestra-structure.sh
├── .github/
│   └── workflows/
│       └── kestra-deploy.yml
├── kestra/
│   ├── flows/
│   │   ├── production/
│   │   │   └── services/
│   │   │       └── meu_flow.yml
│   │   └── staging/
│   │       └── experiments/
│   │           └── test_flow.yml
│   └── files/  # Opcional - criar quando necessário
│       └── production/
│           └── services/
│               ├── config.json
│               └── scripts/
│                   └── process.py
└── README.md
```

### Regras de Estrutura

- **Caminho da pasta = Namespace** (usando `.` ao invés de `/`)
- **Nome do arquivo = ID do flow** (sem a extensão)

**Exemplo:**
```
kestra/flows/production/services/github_flow.yml
                ↓
namespace: production.services
id: github_flow
```

---

## 🔑 Configuração de Autenticação

### Para Validação Local (CLI)

**Validação de sintaxe NÃO precisa de API token:**

```bash
# Funciona offline, sem servidor
kestra flow validate kestra/flows/meu_flow.yml
kestra flow validate --directory kestra/flows/
```

### Para Deploy/Execução (CLI)

**Deploy e execução PRECISAM de API token:**

#### 1. Gerar API Token no Kestra

1. Acesse a UI do Kestra (ex: `http://localhost:8080` ou sua URL)
2. Vá em **Settings** → **Service Accounts** (ou **API Tokens**)
3. Clique em **Create**
4. Dê um nome (ex: `github-actions` ou `local-dev`)
5. Copie o token gerado (você só verá uma vez!)

#### 2. Configurar localmente

**Opção A: Variável de ambiente**

```bash
# Adicionar ao ~/.zshrc ou ~/.bashrc
export KESTRA_HOST="http://localhost:8080"
export KESTRA_API_TOKEN="seu-token-aqui"
```

Recarregar:
```bash
source ~/.zshrc
```

**Opção B: Passar direto no comando**

```bash
kestra flow namespace update \
  --server http://localhost:8080 \
  --api-token SEU_TOKEN_AQUI \
  --namespace production.services \
  kestra/flows/production/services/meu_flow.yml
```

---

## ✅ Validação Local

### 1. Validar Sintaxe (sem API token)

```bash
# Validar um flow específico
kestra flow validate kestra/flows/production/services/meu_flow.yml

# Validar todos os flows
kestra flow validate --directory kestra/flows/
```

### 2. Validar Estrutura de Pastas

```bash
# Tornar o script executável (primeira vez)
chmod +x .githooks/validate-kestra-structure.sh

# Rodar validação
./.githooks/validate-kestra-structure.sh
```

Este script valida:
- ✅ ID do flow = nome do arquivo
- ✅ Namespace do flow = caminho da pasta
- ✅ Sintaxe YAML (se CLI instalado)

---

## 🚀 Deploy Manual

### Deploy de Flows

```bash
# Deploy de um flow específico
kestra flow namespace update \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  --namespace production.services \
  kestra/flows/production/services/meu_flow.yml

# Deploy de todos os flows de um diretório
find kestra/flows -name "*.yml" -exec \
  kestra flow namespace update \
    --server $KESTRA_HOST \
    --api-token $KESTRA_API_TOKEN {} \;
```

### Deploy de Files

```bash
# Upload de um arquivo para namespace
kestra namespace files update \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services \
  config.json \
  kestra/files/production/services/config.json

# Listar files de um namespace
kestra namespace files list \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services
```

---

## 🔄 Git Hooks (Pre-commit)

### Instalação Manual

```bash
# Criar o hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./.githooks/validate-kestra-structure.sh
EOF

# Tornar executável
chmod +x .git/hooks/pre-commit
```

### Usando framework pre-commit (Opcional)

```bash
# Instalar
pip install pre-commit

# Instalar hooks
pre-commit install

# Rodar manualmente
pre-commit run --all-files
```

---

## 🤖 GitHub Actions

### Secrets Necessários

Configure no GitHub (Settings → Secrets and variables → Actions):

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `KESTRA_HOST` | URL da instância Kestra | `https://kestra.exemplo.com` |
| `KESTRA_API_TOKEN` | Token de autenticação | `kestra_xxxxxxxxxxxxx` |

### Workflow Automático

O arquivo `.github/workflows/kestra-deploy.yml` faz:

**Em Pull Requests:**
- ✅ Valida estrutura de pastas
- ✅ Valida sintaxe dos flows
- ❌ **NÃO faz deploy**

**Em Push para main/develop:**
- ✅ Valida estrutura
- ✅ Deploy de flows
- ✅ Deploy de files (se existirem)

---

## 🧪 Testando Localmente

### 1. Subir Kestra Local (Docker)

```bash
# docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  kestra:
    image: kestra/kestra:latest
    ports:
      - "8080:8080"
    environment:
      KESTRA_CONFIGURATION: |
        kestra:
          server:
            basic-auth:
              enabled: false
EOF

docker-compose up -d
```

Acesse: http://localhost:8080

### 2. Criar um Flow de Teste

```yaml
# kestra/flows/staging/test/hello.yml
id: hello
namespace: staging.test

tasks:
  - id: say_hello
    type: io.kestra.plugin.core.log.Log
    message: "Hello from GitOps!"
```

### 3. Validar e Deployar

```bash
# Validar
kestra flow validate kestra/flows/staging/test/hello.yml

# Deploy
kestra flow namespace update \
  --server http://localhost:8080 \
  --namespace staging.test \
  kestra/flows/staging/test/hello.yml

# Executar
kestra flow execute \
  --server http://localhost:8080 \
  staging.test hello
```

---

## 📝 Comandos Úteis

### Flows

```bash
# Listar flows de um namespace
kestra flow list \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  --namespace production.services

# Deletar um flow
kestra flow delete \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services meu_flow

# Executar um flow
kestra flow execute \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services meu_flow
```

### Files

```bash
# Listar files
kestra namespace files list \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services

# Download de um file
kestra namespace files download \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services \
  config.json

# Deletar um file
kestra namespace files delete \
  --server $KESTRA_HOST \
  --api-token $KESTRA_API_TOKEN \
  production.services \
  config.json
```

---

## ⚠️ Troubleshooting

### Erro: `kestra: command not found`

```bash
# Verificar instalação
which kestra

# Reinstalar
brew reinstall kestra-io/tap/kestra

# Ou usar Docker
alias kestra='docker run --rm -v $(pwd):/app kestra/kestra:latest'
```

### Erro: Validação falha no namespace

Verifique se:
- O caminho da pasta corresponde ao namespace (usando `.`)
- O nome do arquivo corresponde ao `id` do flow
- Exemplo: `kestra/flows/prod/services/etl.yml` → `namespace: prod.services` + `id: etl`

### Erro: `401 Unauthorized`

- Verifique se o `KESTRA_API_TOKEN` está correto
- Regenere o token no Kestra se necessário
- Confirme que o token tem permissões adequadas

---

## 🎯 Quick Start

```bash
# 1. Instalar CLI
brew install kestra-io/tap/kestra

# 2. Clonar seu repo
git clone seu-repo
cd seu-repo

# 3. Configurar secrets
export KESTRA_HOST="http://localhost:8080"
export KESTRA_API_TOKEN="seu-token"

# 4. Instalar hooks
chmod +x .githooks/validate-kestra-structure.sh
cp .githooks/validate-kestra-structure.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# 5. Validar tudo
./.githooks/validate-kestra-structure.sh

# 6. Fazer seu primeiro commit
git add .
git commit -m "Setup Kestra GitOps"
git push
```

---

## 📚 Recursos

- [Documentação Kestra](https://kestra.io/docs)
- [Kestra CLI Reference](https://kestra.io/docs/cli)
- [GitHub Actions para Kestra](https://github.com/kestra-io/deploy-action)