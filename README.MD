# Kestra GitOps Boilerplate

Boilerplate para versionar flows do Kestra com validação local via Docker e deploy automático por GitHub Actions.

## Pré-requisitos

- Docker instalado e rodando
- Node.js e npm (para Git hooks automáticos)

## Setup inicial

```bash
# 1. Clonar o repositório
git clone <seu-repo>
cd kestra-gitops-test

# 2. Instalar dependências (configura hooks automaticamente)
npm install

# 3. Validar que está tudo OK
npm run validate
```

Após o `npm install`, o **pre-commit hook** é instalado automaticamente via Husky. Toda vez que você commitar, a validação roda automaticamente.

## Estrutura do projeto

```
kestra-gitops-test/
├── bin/
│   └── kestra.sh                 # Wrapper Docker para CLI do Kestra
├── kestra/
│   ├── flows/                    # Flows organizados por namespace
│   │   └── watxer/
│   │       └── _services/
│   │           └── github/
│   │               └── search_repositories.yml
│   └── files/                    # Namespace files (opcional)
├── .githooks/
│   └── validate-kestra-structure.sh
├── .github/
│   └── workflows/
│       └── kestra-deploy.yml     # Pipeline de deploy
├── docs/
│   ├── adding-environments.md    # Como adicionar novos ambientes
│   └── adding-flows.md           # Como adicionar novos flows
├── docker-compose.kestra.yml     # Kestra local (desenvolvimento)
└── README.MD
```

## Como funciona

### Convenção de pastas → namespace

A estrutura de pastas determina automaticamente o namespace do flow:

```
kestra/flows/watxer/_services/github/search_repositories.yml
             └─────────────────────┘ └──────────────────┘
                  namespace             id do flow
                  (/ vira .)
```

No YAML do flow:
```yaml
id: search_repositories
namespace: watxer._services.github
```

### Validação local

O hook `.githooks/validate-kestra-structure.sh` valida:

1. **Estrutura**: `id` e `namespace` batem com caminho/nome do arquivo
2. **Sintaxe**: executa `flow validate --local` em container Docker efêmero

Execute manualmente:

```bash
bash ./.githooks/validate-kestra-structure.sh
```

### Deploy automático

- Push na branch **`prod`** → deploy para servidor de produção (environment `Production`)
- Pull requests → apenas validação (não faz deploy)

O workflow descobre dinamicamente todos os namespaces e faz deploy de cada um.

## Comandos úteis

### Validar manualmente

```bash
# Via npm script
npm run validate

# Ou diretamente
bash ./.githooks/validate-kestra-structure.sh
```

### Git hooks

O projeto usa **Husky** para rodar validação automática antes de cada commit:
- ✅ Valida estrutura de pastas/namespaces
- ✅ Valida sintaxe YAML dos flows
- ❌ Bloqueia commit se houver erros

Para bypassar (use com cuidado):
```bash
git commit --no-verify -m "mensagem"
```

### Validar sintaxe de um flow

```bash
./bin/kestra.sh flow validate --local kestra/flows/watxer/_services/github/search_repositories.yml
```

### Subir Kestra local

```bash
docker compose -f docker-compose.kestra.yml up -d
```

Acesse em: `http://localhost:8080`

### Criar atalho local

```bash
alias kestra='./bin/kestra.sh'
kestra --version
```

## GitHub Actions e Environments

O repositório usa **GitHub Environments** para separar credenciais por ambiente:

- Environment **Production** (branch `prod`)
  - `KESTRA_HOST`: URL do servidor Kestra de produção
  - `KESTRA_USER`: Email/usuário
  - `KESTRA_PASSWORD`: Senha

Para adicionar novos ambientes (staging, dev), consulte: **[docs/adding-environments.md](docs/adding-environments.md)**

## Adicionando novos flows

Siga a convenção de pastas e consulte o guia completo em: **[docs/adding-flows.md](docs/adding-flows.md)**

Exemplo rápido:

```bash
# 1. Criar estrutura
mkdir -p kestra/flows/watxer/pipelines

# 2. Criar flow
cat > kestra/flows/watxer/pipelines/daily_sync.yml << 'EOF'
id: daily_sync
namespace: watxer.pipelines

tasks:
  - id: sync
    type: io.kestra.plugin.core.log.Log
    message: "Syncing..."
EOF

# 3. Validar
bash ./.githooks/validate-kestra-structure.sh

# 4. Commitar
git add kestra/flows/watxer/pipelines/daily_sync.yml
git commit -m "Add daily sync pipeline"
git push origin prod
```

## Documentação

- **[Adicionando ambientes](docs/adding-environments.md)** - Como criar staging, dev, etc
- **[Adicionando flows](docs/adding-flows.md)** - Convenções e boas práticas

## Arquitetura de ambientes

Não existe separação de ambiente por pastas no repositório. O mesmo código é deployado para servidores diferentes, determinados pelo GitHub Environment da branch:

```
Repositório (mesma estrutura de flows)
  │
  ├─ branch prod ──────→ Kestra Production (via environment Production)
  │
  └─ branch staging ───→ Kestra Staging (via environment Staging, quando criado)
```

---

**Setup inicial**: valide que tudo funciona rodando `bash ./.githooks/validate-kestra-structure.sh` ✅
