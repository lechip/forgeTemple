# forgeTemple

A small software factory for Claude Code, Google Antigravity, and OpenAI Codex. It is a cross-environment plugin, and this repository is also its marketplace. Projects install it, run `/forgetemple:init`, and keep their own rules in their repository.

This repository contains only the factory. It has no application code, no package, and no build step.

## Layout

- `.claude-plugin/marketplace.json`: the marketplace for Claude Code and Codex CLI. It lists one plugin, `forgetemple`.
- `.agents/plugins.json`: workspace plugin discovery for Antigravity 2.0.
- `plugins/forgetemple/.claude-plugin/plugin.json`: the Claude Code and Codex CLI plugin manifest. Its `userConfig` holds one model setting for each agent.
- `plugins/forgetemple/plugin.json`: the native Antigravity 2.0 plugin manifest.
- `plugins/forgetemple/skills/factory/SKILL.md`: the orchestrator. The `/forgetemple:factory` command.
- `plugins/forgetemple/skills/init/SKILL.md`: sets up the project files. The `/forgetemple:init` command.
- `plugins/forgetemple/agents/`: 5 agents: `spec-writer`, `implementer`, `reviewer-code`, `reviewer-security`, `approver`.
- `plugins/forgetemple/templates/coding-standards.md`: the code rules and test rules. `init` copies it to `docs/coding-standards.md` in the project, and `reviewer-code` applies them there.
- `plugins/forgetemple/templates/dashboard.html`: shows the state of each job. `init` copies it to `factory/dashboard.html` in the project.
- `plugins/forgetemple/scripts/rework-comment.sh`: writes the short PR comment of a rework from the job files and git.
- `factory/jobs/<job-id>/` in the project: runtime files of each job. Git ignores them.

## Design rules

Keep these when you edit the factory:

- **Two stages.** `implementer` makes it work with TDD. `reviewer-code` makes it good, with a fresh context, from the diff and `docs/coding-standards.md`.
- **Rules live in the project repository.** Code rules and test rules go in the project `docs/coding-standards.md`, not in agent prompts. The plugin only ships the template.
- **Agents are generic.** No project names, commands, or framework details in agent files. Project commands come from the "Commands" section of the project `CLAUDE.md` (or `AGENTS.md` / `GEMINI.md`).
- **Files carry the context.** Agents talk through files in the job folder. Each file has a status line that the orchestrator reads.
- **The orchestrator does not do the work.** It never writes code, specs, or reviews. It is the only writer of `job.json`.
- **Models.** Agents default to `sonnet` in Claude Code, `neon` in Antigravity, and `sol` in Codex. Each agent model is a plugin setting, and a "Factory models" section in the project `CLAUDE.md` (or `AGENTS.md` / `GEMINI.md`) overrides it. The orchestrator resolves the models and passes them when it starts each agent.
- **Two human stops.** Spec approval, and the pull request. The factory never merges.
- **Conventional Commits.** Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`) for every commit, and stage files by explicit path (never `git add -A` or `git add .`).
- **Keep it small.** Before you add an agent, a file, or a step, check that an existing one cannot do the job.

## Checks

Run these from the repository root to validate the manifests and agent files:

- Antigravity: `agy plugin validate plugins/forgetemple --strict`
- Claude Code: `claude plugin validate .`
- Codex: `codex plugin marketplace add .`

No other automatic checks exist. After a change, run the factory on a real project and read the job files. To load the plugin from this folder in Claude Code, start Claude Code with `--plugin-dir plugins/forgetemple`.

If you change the fields of `job.json` in `SKILL.md`, update `plugins/forgetemple/templates/dashboard.html` to match.

If you add an agent, add its model setting to `.claude-plugin/plugin.json`, to the "Agents and models" table in the factory `SKILL.md`, and to the models list in the init `SKILL.md`.

Change `version` in both `.claude-plugin/plugin.json` and `plugins/forgetemple/plugin.json` when you release a change. Users stay on the old version until it changes.
