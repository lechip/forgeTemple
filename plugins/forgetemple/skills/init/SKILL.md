---
name: init
description: Set up or update the forgeTemple factory files in the current project. Copies the dashboard and the coding standards, adds the .gitignore lines, and drafts the "Commands" section of CLAUDE.md (or AGENTS.md / GEMINI.md). Use for "/forgetemple:init".
disable-model-invocation: true
---

# Factory init

You set up the project files the factory needs. The plugin holds the skill and the agents. The project holds the files below. You can run this skill again at any time: it adds what is missing, refreshes the dashboard, and keeps the human's own files.

`PLUGIN` = `${CLAUDE_PLUGIN_ROOT}` (if unexpanded and still starting with `${`, resolve `PLUGIN` as the plugin root folder two levels above this `SKILL.md` file).
`REPO` = output of `git rev-parse --show-toplevel`. If the folder is not a git repository, stop and tell the human.
`CONFIG_MD` = `REPO/CLAUDE.md` if it exists, else `REPO/AGENTS.md` if it exists, else `REPO/GEMINI.md` if it exists, else `REPO/CLAUDE.md`.

## Files

| Project file | Owner | What you do |
|---|---|---|
| `REPO/factory/dashboard.html` | plugin | Copy from `PLUGIN/templates/dashboard.html`. Overwrite it if it exists: it must match the `job.json` fields of this plugin version. |
| `REPO/factory/jobs/.gitkeep` | plugin | Create it if missing. |
| `REPO/docs/coding-standards.md` | human | Copy from `PLUGIN/templates/coding-standards.md` only if it does not exist. Never overwrite it. |
| `REPO/.gitignore` | human | Add the two lines below if they are not already in the file. Do not add them twice. |
| `CONFIG_MD` (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) | human | Add a "Commands" section only if none exists. See "Commands section". |

The `.gitignore` lines:

```
factory/jobs/*
!factory/jobs/.gitkeep
```

Use `cp` and `mkdir -p` in `REPO`. Do not change any other file.

## Commands section

The factory reads the project commands from the "Commands" section of `CONFIG_MD`. If the section exists, do not change it. Only check that it has `setup`, `test`, `lint`, and `typecheck`, and tell the human which are missing.

If the section does not exist:

1. Find the package manager from the lock file: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` or `bun.lock` → bun, else npm.
2. Read the `scripts` of `REPO/package.json`. Map them to the keys below. Use only scripts that exist. Do not invent a command.
3. Show the draft to the human and ask: write it, or change it. Then end your turn and wait.
4. After the human says yes, append the section to `CONFIG_MD`. Create `CLAUDE.md` if no config file exists yet.

```markdown
## Commands

- setup: `npm install`
- test: `npm test`
- test integration: `npm run test:integration`
- test e2e: `npm run test:e2e`
- lint: `npm run lint`
- typecheck: `npm run typecheck`
- build: `npm run build`
```

`setup`, `test`, `lint`, and `typecheck` are necessary. The others are optional. If a necessary script is missing, write `TODO` as its command and tell the human.

## Report

Tell the human:

1. Which files you created, refreshed, or left as they were.
2. The models of the agents (see below), and how to change them.
3. The next steps: edit `docs/coding-standards.md` for the project, then run `/forgetemple:factory <feature>`.

### Models

The plugin settings are:

- `spec-writer`: `${user_config.spec_writer_model}`
- `implementer`: `${user_config.implementer_model}`
- `reviewer-code`: `${user_config.reviewer_code_model}`
- `reviewer-security`: `${user_config.reviewer_security_model}`
- `approver`: `${user_config.approver_model}`

If `CONFIG_MD` has a "Factory models" section, its lines win for this project. If a setting is `default` (or unexpanded `${user_config.*}`), it resolves to the default for the active environment (`sonnet` in Claude Code, `neon` in Antigravity, `sol` in Codex). Tell the human which value each agent gets.

How to change them:

- For you, in all projects (Claude Code): `/config`, or `/plugin configure forgetemple@forgetemple`.
- For everyone in this project: a "Factory models" section in `CLAUDE.md` (or `AGENTS.md` / `GEMINI.md`), for example:

```markdown
## Factory models

- implementer: neon
- reviewer-code: neon
```

Valid models:
- **Claude Code** (default `sonnet`): `default`, `sonnet`, `opus`, `haiku`, `fable`
- **Antigravity / Google** (default `neon`): `default`, `neon`, `argon`, `hydrogen`, `carbon`
- **Codex / OpenAI** (default `sol`): `default`, `sol`, `astra`, `terra`, `luna`
