# Log

Append-only ledger. One line per action: `## [YYYY-MM-DD HH:MM] action | summary`.
Parse the tail with `grep "^## \[" log.md | tail -5`.

## [{{TODAY}}] bootstrap | LLM Wiki scaffolded at {{VAULT_DIR}}
