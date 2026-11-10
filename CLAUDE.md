# forgeTemple

A small software factory for Claude Code. It is a template. You copy it into a TypeScript project and edit it.

This repository contains only the factory. It has no application code, no package, and no build step.

## Layout

- `.claude/skills/factory/SKILL.md`: the orchestrator. The `/factory` command.
- `.claude/agents/`: 5 agents: `spec-writer`, `implementer`, `reviewer-code`, `reviewer-security`, `approver`.
- `docs/coding-standards.md`: the code rules and test rules. `reviewer-code` applies them.
- `factory/dashboard.html`: shows the state of each job.
- `factory/jobs/<job-id>/`: runtime files of each job. Git ignores them.

## Design rules

Keep these when you edit the factory:

- **Two stages.** `implementer` makes it work with TDD. `reviewer-code` makes it good, with a fresh context, from the diff and `docs/coding-standards.md`.
- **Rules live in the repository.** Code rules and test rules go in `docs/coding-standards.md`, not in agent prompts.
- **Agents are generic.** No project names, commands, or framework details in agent files. Project commands come from the "Commands" section of the project `CLAUDE.md`.
- **Files carry the context.** Agents talk through files in the job folder. Each file has a status line that the orchestrator reads.
- **The orchestrator does not do the work.** It never writes code, specs, or reviews. It is the only writer of `job.json`.
- **Models.** Orchestrator: Opus. Agents: Sonnet.
- **Two human stops.** Spec approval, and the pull request. The factory never merges.
- **Keep it small.** Before you add an agent, a file, or a step, check that an existing one cannot do the job.

## Checks

No automatic checks exist for this repository. After a change, run the factory on a real project and read the job files.

If you change the fields of `job.json` in `SKILL.md`, update `factory/dashboard.html` to match.
