# Verification Command Selection

Select verification commands from repository evidence. Run only commands the project exposes or documents; this table is a starting map, not permission to invent a command.

## Application stacks

| Evidence | Typical commands |
|----------|------------------|
| `package.json` + `pnpm-lock.yaml` | `pnpm lint`, `pnpm typecheck`, `pnpm test` if scripts exist |
| `package.json` + `package-lock.json` | `npm run lint`, `npm run typecheck`, `npm test` if scripts exist |
| `package.json` + `yarn.lock` | `yarn lint`, `yarn typecheck`, `yarn test` if scripts exist |
| `pyproject.toml` | `ruff check .`, `mypy .`, `pytest` when configured |
| `Cargo.toml` | `cargo fmt --check`, `cargo clippy`, `cargo test` |
| `go.mod` | `go test ./...`, `go vet ./...` when applicable |
| `pom.xml` / `build.gradle` | `mvn -q test`, `./gradlew test`; configured style/check tasks |
| `*.csproj` / `*.sln` | `dotnet build`, `dotnet test`; `dotnet format --verify-no-changes` when available |
| `Gemfile` / `*.rb` | `bundle exec rake test` or `bundle exec rspec`; `rubocop` when configured |
| `composer.json` | `composer test` or `vendor/bin/phpunit`; configured lint/style task |
| `CMakeLists.txt` (C/C++) | configured build plus `ctest`; infer sanitizer/clang-tidy from config |
| `pubspec.yaml` (Dart/Flutter) | `flutter analyze`, `flutter test` |
| Other stacks | Inspect CI, README, Makefile, and project scripts; never invent commands |

## Configuration and IaC

| Evidence | Typical commands |
|----------|------------------|
| `.github/workflows/*.yml` | `actionlint` if available; otherwise inspect YAML syntax and secret references |
| `Dockerfile` / `docker-compose.yml` | `docker build` and `docker compose config` when safe and configured |
| `*.tf` / `*.tofu` | `terraform fmt -check`, `terraform validate`; `terraform plan` only in a prepared environment |
| `Chart.yaml` / `values.yaml` | `helm lint`, `helm template` |
| Generic `*.yml` / `*.yaml` | Configured YAML/schema linter |
| Kubernetes manifests | `kubectl apply --dry-run=server -f` with a safe cluster context, or offline validation |

## Safety and reporting

- Start with the actual `git diff`, then select the narrowest relevant gates.
- Never run `terraform apply` or `kubectl apply` as verification; they mutate external state.
- If no reliable command exists, say so under skipped checks. Never report a check as passed when it was not run.
