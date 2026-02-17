# Adicionando novos flows

Este guia explica como adicionar novos flows ao repositório seguindo a convenção de estrutura de pastas e namespaces.

## Regra de mapeamento

A estrutura de pastas determina automaticamente o namespace do flow:

```
kestra/flows/PARTE1/PARTE2/PARTE3/nome_do_flow.yml
                ↓
namespace: PARTE1.PARTE2.PARTE3
id: nome_do_flow
```

### Exemplos

| Caminho do arquivo | Namespace esperado | ID esperado |
|-------------------|-------------------|-------------|
| `kestra/flows/watxer/_services/github/search_repositories.yml` | `watxer._services.github` | `search_repositories` |
| `kestra/flows/watxer/pipelines/daily_sync.yml` | `watxer.pipelines` | `daily_sync` |
| `kestra/flows/analytics/reports/monthly.yml` | `analytics.reports` | `monthly` |

## Passo a passo

### 1. Criar a estrutura de pastas

Organize os flows por namespace lógico. Recomendações:

- Use o nome da empresa/projeto como raiz (ex: `watxer/`)
- Agrupe flows relacionados em subpastas (ex: `_services/`, `pipelines/`)
- Use nomes descritivos e em minúsculas com underscore

```bash
mkdir -p kestra/flows/watxer/pipelines
```

### 2. Criar o arquivo do flow

Crie o arquivo `.yml` com o nome igual ao `id` desejado:

```yaml
# kestra/flows/watxer/pipelines/daily_sync.yml
id: daily_sync
namespace: watxer.pipelines

description: Sincronização diária de dados

tasks:
  - id: fetch_data
    type: io.kestra.plugin.core.http.Request
    uri: https://api.example.com/data
    
  - id: process
    type: io.kestra.plugin.scripts.python.Script
    script: |
      print("Processing data...")
```

**IMPORTANTE**: O `namespace` e o `id` no YAML **devem** bater com a convenção de pastas. O hook de validação vai rejeitar se não baterem.

### 3. Validar localmente

Antes de commitar, rode o script de validação:

```bash
bash ./.githooks/validate-kestra-structure.sh
```

O script valida:
- ✅ `id` do flow = nome do arquivo
- ✅ `namespace` do flow = caminho da pasta (convertido com `.`)
- ✅ Sintaxe YAML válida (via Docker)

### 4. Testar sintaxe manualmente (opcional)

Use o wrapper Docker para validar um flow específico:

```bash
./bin/kestra.sh flow validate --local kestra/flows/watxer/pipelines/daily_sync.yml
```

### 5. Commitar e fazer push

```bash
git add kestra/flows/watxer/pipelines/daily_sync.yml
git commit -m "Add daily sync pipeline"
git push origin staging  # ou prod, dependendo do ambiente
```

O GitHub Actions vai:
1. Validar a estrutura (se for PR)
2. Deployar automaticamente para o Kestra (se for push em `prod` ou `staging`)

## Convenções de nomenclatura

### Namespaces

- Use nomes curtos e descritivos
- Prefira minúsculas
- Use underscore `_` se necessário (ex: `_services`)
- Evite muitos níveis (máximo 4-5 recomendado)

**Bom:**
- `watxer._services.github`
- `analytics.reports`
- `etl.daily`

**Evitar:**
- `MyCompany.Services.Integration.External.GitHub` (muito longo)
- `temp` (não descritivo)

### IDs de flows

- Use snake_case (minúsculas com underscore)
- Seja descritivo sobre o que o flow faz
- Evite IDs genéricos como `flow1`, `test`

**Bom:**
- `search_repositories`
- `send_slack_notification`
- `monthly_report`

**Evitar:**
- `flow1` (não descritivo)
- `SearchRepositories` (use snake_case)
- `temp_test` (temporário)

## Organizando flows por tipo

### Por domínio de negócio

```
kestra/flows/
  watxer/
    sales/          # Flows de vendas
    marketing/      # Flows de marketing
    analytics/      # Flows de análise
```

### Por função técnica

```
kestra/flows/
  watxer/
    _services/      # Integrações com APIs externas
    pipelines/      # ETL e processamento de dados
    notifications/  # Envio de alertas
```

### Misto (recomendado)

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

## Namespace Files (arquivos estáticos)

Se o flow usar arquivos estáticos (configs, scripts, etc), coloque em `kestra/files/` seguindo o mesmo namespace:

```
kestra/
  flows/
    watxer/
      pipelines/
        etl_process.yml          # namespace: watxer.pipelines
  files/
    watxer/
      pipelines/
        config.json              # Acessível pelo flow via namespace files
        transform_script.py
```

No flow, acesse via:

```yaml
tasks:
  - id: read_config
    type: io.kestra.plugin.core.storage.LocalFiles
    inputs:
      config.json: "{{ namespace.files.read('config.json') }}"
```

## Troubleshooting

### Erro: namespace mismatch

```
❌ kestra/flows/watxer/pipelines/daily_sync.yml
   Namespace mismatch: expected 'watxer.pipelines', got 'watxer.pipeline'
```

**Solução**: Corrija o `namespace` no YAML para bater com o caminho da pasta.

### Erro: ID mismatch

```
❌ kestra/flows/watxer/pipelines/daily_sync.yml
   ID mismatch: expected 'daily_sync', got 'daily-sync'
```

**Solução**: Renomeie o arquivo ou corrija o `id` no YAML.

### Sintaxe inválida

```
❌ Syntax validation failed: kestra/flows/watxer/pipelines/daily_sync.yml
```

**Solução**: Rode `./bin/kestra.sh flow validate --local <arquivo>` para ver o erro detalhado.
