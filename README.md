# Gerenciamento de Obrigações — visão geral

Documentação **raiz** do workspace `player-contabilidade`. Este README descreve o produto como um todo, como os repositórios se encaixam, como subir o ambiente completo e onde aprofundar (backend e frontend).

## Finalidade deste README

Servir de **ponto de entrada** para quem chega ao projeto: contexto do desafio, mapa dos repositórios, fluxo de execução ponta a ponta e decisões que atravessam API e app. Detalhes de build, variáveis e arquitetura interna ficam nos READMEs de cada módulo.

## Contexto do desafio

Sistema para escritório de contabilidade acompanhar **empresas clientes**, **usuários responsáveis**, **obrigações** (com status e prazo) e **anexos** documentais. O quadro de acompanhamento do desafio está em:

https://trello.com/b/WFkCNXHG/gerenciamento-de-obrigacoes

## Como obter o código (avaliador)

Os repositórios são **independentes** (sem Git submodules). Clone este repositório raiz e, em seguida, clone backend e frontend **dentro da mesma pasta**:

```bash
git clone https://github.com/marcosvrca/player-contabilidade.git
cd player-contabilidade

git clone https://github.com/marcosvrca/gerenciamento-obrigacoes-backend.git
git clone https://github.com/marcosvrca/gerenciamento-obrigacoes-frontend.git
```

| Repositório | URL |
|-------------|-----|
| **Raiz** (este) | https://github.com/marcosvrca/player-contabilidade |
| **Backend** | https://github.com/marcosvrca/gerenciamento-obrigacoes-backend |
| **Frontend** | https://github.com/marcosvrca/gerenciamento-obrigacoes-frontend |

## Repositórios neste workspace

| Pasta | Papel | Documentação |
|-------|--------|--------------|
| `gerenciamento-obrigacoes-backend/` | API REST Spring Boot + MySQL + anexos em disco | [README do backend](./gerenciamento-obrigacoes-backend/README.md) |
| `gerenciamento-obrigacoes-frontend/` | App Flutter (web/desktop) consumindo a API | [README do frontend](./gerenciamento-obrigacoes-frontend/README.md) |
| `start-frontend.cmd` | Atalho Windows para `flutter run -d chrome` no frontend | — |

## Tecnologias (visão de stack)

- **Backend:** Java 21, Spring Boot 3.4, JPA, Flyway, MySQL 8 (utf8mb4), Docker Compose, SpringDoc OpenAPI, Testcontainers  
- **Frontend:** Flutter / Dart 3, Riverpod, Dio, Material (`material_ui`), file_picker / path_provider / open_filex  
- **Qualidade:** GitHub Actions (Maven verify / Flutter analyze + test)

## Pré-requisitos (ambiente completo)

| Ferramenta | Versão / nota |
|------------|----------------|
| **Git** | Para clonar os três repositórios |
| **Docker Desktop** | Instalado e **em execução** (daemon ativo) antes do `docker compose` |
| **Flutter SDK** | **3.50+** (stable), Dart **3.11+**, no `PATH` — confira com `flutter --version` |
| **Chrome** (ou Edge) | Para `flutter run -d chrome` |
| **JDK 21** | Só se for rodar a API **fora** do Docker (`mvnw spring-boot:run`) |

**Windows (Flutter):** ative o [Developer Mode](ms-settings:developers) (Configurações → Sistema → Para desenvolvedores). Sem isso, `flutter pub get` / plugins podem falhar por falta de suporte a symlinks.

**Windows (atalho):** `start-frontend.cmd` usa o `flutter` do `PATH` — não depende de caminho fixo de máquina.

## Arquitetura lógica

```
┌─────────────────────────┐     HTTPS/HTTP JSON      ┌──────────────────────────┐
│  Flutter (UI + Riverpod)│ ◄──────────────────────► │  Spring Boot API :8080   │
│  web / windows / mobile │                          │  Controllers → Services  │
└─────────────────────────┘                          │  JPA + Flyway + MySQL    │
                                                     │  Filesystem (anexos)     │
                                                     └──────────────────────────┘
```

- O frontend não acessa o banco; toda regra de negócio e persistência passam pela API.  
- Anexos são gravados em diretório configurável (`STORAGE_PATH`) e referenciados por obrigação (`POST/GET /api/obrigacoes/{id}/anexos`).  
- Encoding UTF-8 / utf8mb4 é tratado de ponta a ponta (HTTP + JDBC + MySQL) para acentos (ç, ã, etc.).

## Execução rápida (ambiente completo)

Com os três repositórios na mesma pasta e o Docker Desktop **aberto**:

### 1. Backend (API + MySQL)

```bash
cd gerenciamento-obrigacoes-backend
docker compose up --build
```

Aguarde o MySQL ficar healthy e a API subir (primeira build pode demorar).

- API: http://localhost:8080  
- Swagger: http://localhost:8080/swagger-ui.html  
- MySQL: `localhost:3306` (usuário/senha `obrigacoes`)

Se aparecer erro de nome de container já em uso (`obrigacoes-mysql` / `obrigacoes-api`), remova os antigos e suba de novo:

```bash
docker rm -f obrigacoes-mysql obrigacoes-api
docker compose up --build
```

Seed opcional de demo (após containers saudáveis):

```powershell
# Windows
cd gerenciamento-obrigacoes-backend
.\scripts\seed-demo-data.ps1
```

```bash
# Linux / macOS
cd gerenciamento-obrigacoes-backend
chmod +x ./scripts/seed-demo-data.sh
./scripts/seed-demo-data.sh
```

### 2. Frontend

Com a API em `http://localhost:8080` e Flutter **3.50+** no `PATH`:

```bash
cd gerenciamento-obrigacoes-frontend
flutter pub get
flutter run -d chrome
# ou web-server local:
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5000
```

No Windows, também: `start-frontend.cmd` (na raiz deste monorepo; exige `flutter` no `PATH`).

## Configuração do ambiente (resumo)

| Item | Onde | Padrão |
|------|------|--------|
| Porta API | `SERVER_PORT` / `application.yml` | `8080` |
| JDBC / charset | `SPRING_DATASOURCE_URL` | MySQL + `characterEncoding=UTF-8` + `connectionCollation=utf8mb4_unicode_ci` |
| Pasta de anexos | `STORAGE_PATH` | `./uploads` (volume no Compose) |
| URL da API no app | `--dart-define=API_BASE_URL=...` | `http://localhost:8080` |

Detalhes completos: README do backend e do frontend.

## Estrutura do monorepo

```
player-contabilidade/
  README.md                          ← este arquivo (visão geral)
  start-frontend.cmd
  gerenciamento-obrigacoes-backend/  ← API + Docker + migrations + seed
  gerenciamento-obrigacoes-frontend/ ← app Flutter + design system
```

## Decisões arquiteturais (transversais)

### Produto e domínio

- Cadastros de empresa e usuário com situação **Ativo/Inativo** (inativos consultáveis, não atribuíveis em novas obrigações).  
- Obrigação com fluxo de status **PENDENTE → EM_ANDAMENTO → CONCLUIDA**; concluída não edita nem muda status.  
- Anexos vinculados à obrigação **já existente** (upload no detalhe), não no formulário de criação.

### Backend

- Camadas Controller → Service → Repository; validação Bean Validation; Flyway com `ddl-auto=validate`.  
- UTF-8 forçado em servlet + JDBC utf8mb4; migration `V5` converte schema/colunas.  
- Seed demo via SQL + scripts PowerShell/Bash que usam `docker cp` (evita corrupção de acentos no pipe do shell).

### Frontend (incluindo decisões recentes)

- **Shell unificado:** menu lateral e faixa de paginação compartilham a mesma superfície visual; não há footer separado com “costura” entre chrome e lista.  
- **Paginação:** 15 itens por página; slots por aba (`IndexedStack`) para a barra aparecer junto com a troca de módulo; em usuários a paginação permanece visível mesmo com uma só página.  
- **Dialogs padronizados:** criação/edição de empresa, usuário e obrigação em `AlertDialog` com **Cancelar** e **Salvar**.  
- **Searchable select:** `RawAutocomplete` com filtro ao digitar e visual alinhado aos filtros de status (empresa, responsável, situação).  
- **Mobile:** FAB de criação compacto (ícone `+`), elevado acima da paginação quando necessário.  
- **Splash web:** texto “Carregando aplicação…”, mantido até o primeiro frame Flutter.  
- Riverpod + repositórios Dio; design system Ledger Ink (tokens, tipografia, componentes compartilhados).

## Melhorias futuras (não implementadas agora)

Detalhamento por módulo nos READMEs de backend e frontend.

### Produto (priorizadas)

1. **Identidade e acesso** — login, cadastro e controle de usuários/papéis (quem vê e quem age em cada obrigação).  
2. **Home leve** — tela inicial antes das obrigações, com métricas básicas e alertas (visão geral, não dashboard completo).  
3. **Alertas internos** — notificações in-app por obrigação, respeitando o controle de acesso do usuário.  
4. **E-mail** — envio de notificações por e-mail, com preferências customizáveis por usuário (quais tipos receber: novas obrigações criadas, a vencer, do dia, da semana).  
5. **Configurações** — painel para temas, preferências de e-mail/alertas, parâmetros de ambiente e integrações (sistemas externos, WhatsApp quando fizer sentido).  
6. **Kanban de obrigações** — quadro por etapas (ex.: Pendente / Em andamento / Concluída), com ACL (admin vê o quadro completo).

### Sugestões adicionais (domínio)

7. **Prazos e atraso** — regras automáticas de “a vencer” / “vencida” alimentando a home e os canais de alerta.  
8. **Obrigações recorrentes** — modelos por competência (mensal/trimestral) para reduzir cadastro repetitivo.  
9. **Relatórios / exportação** — CSV ou PDF por período, empresa ou responsável.  
10. **Paginação e filtros na API** — listas grandes sem carregar tudo no cliente.  
11. **Auditoria de status** — histórico de quem avançou a obrigação e quando.

## CI/CD

- Backend: `.github/workflows/ci.yml` → `mvn -B verify`  
- Frontend: `.github/workflows/ci.yml` → `flutter analyze` e `flutter test`  

## Links úteis

- [README backend](./gerenciamento-obrigacoes-backend/README.md)  
- [README frontend](./gerenciamento-obrigacoes-frontend/README.md)  
- Quadro Trello do desafio: https://trello.com/b/WFkCNXHG/gerenciamento-de-obrigacoes  
