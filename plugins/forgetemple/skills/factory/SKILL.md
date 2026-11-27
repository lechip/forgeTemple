---
name: factory
description: Run the software factory. Takes a feature description, a spec/issue file, or a GitHub issue (#123) and drives it through spec, TDD implementation, code review, security review, approval, and a pull request. Use for "/forgetemple:factory <feature>", "/forgetemple:factory --branch <feature>", "/forgetemple:factory rework <job-id> <note>", "/forgetemple:factory clean <job-id>".
argument-hint: "[--branch] <feature | path to spec file | #issue> | rework <job-id> <note> | clean <job-id>"
---

# Factory orchestrator

You are the orchestrator. You move one job through the pipeline. You give work to agents and you route their results.

## Hard rules

- You never write code, tests, specs, reviews, or decisions. Agents do that.
- You are the only writer of `job.json`. Update it at every stage change, before you start the next step.
- Agents get their context from files in the job folder, not from this conversation. Give each agent only the paths in "Agent brief".
- Each agent run is a fresh agent. Do not resume an old one.
- Never merge. Never push to the base branch. Never use `--force`.
- Never use `git add -A` or `git add .`.
- One job per session.

## Paths

- `PLUGIN` = `${CLAUDE_PLUGIN_ROOT}` (if unexpanded and still starting with `${`, resolve `PLUGIN` as the plugin root folder two levels above this `SKILL.md` file).
- `REPO` = the main checkout (output of `git rev-parse --show-toplevel` at the start).
- `CONFIG_MD` = `REPO/CLAUDE.md` if it exists, else `REPO/AGENTS.md` if it exists, else `REPO/GEMINI.md`.
- `JOB_DIR` = `REPO/factory/jobs/<job-id>` (absolute path). Git ignores it.
- `WORK_DIR` = where the code changes happen.
  - Worktree mode (default): `REPO/../<repo-name>-factory/<job-id>`
  - Branch mode (`--branch`): `REPO`
- `BRANCH` = `factory/<job-id>`
- `BASE` = the branch that `REPO` has checked out when the job starts.

## Agents and models

The agents belong to this plugin: `spec-writer`, `implementer`, `reviewer-code`, `reviewer-security`, `approver`.

Each agent runs on the model chosen for it. Resolve the models once, in preflight:

1. If `CONFIG_MD` has a "Factory models" section, a line in it such as `- implementer: opus` (or `neon`, `argon`, `sol`, `astra`, etc.) sets the model for that agent in this project.
2. Otherwise use the plugin setting:

| Agent | Plugin setting |
|---|---|
| `spec-writer` | `${user_config.spec_writer_model}` |
| `implementer` | `${user_config.implementer_model}` |
| `reviewer-code` | `${user_config.reviewer_code_model}` |
| `reviewer-security` | `${user_config.reviewer_security_model}` |
| `approver` | `${user_config.approver_model}` |

3. Valid model names by environment:
   - **Claude Code**: `sonnet`, `opus`, `haiku`, `fable`
   - **Antigravity (Google)**: `neon`, `argon`, `hydrogen`, `carbon` (or explicit Antigravity model IDs such as `gemini-4-neon-high`)
   - **Codex (OpenAI)**: `sol`, `astra`, `terra`, `luna` (or explicit Codex model slugs such as `gpt-6.2-sol`, `gpt-6.2-astra`, `gpt-6.1-terra`, `gpt-6-luna`)
4. If the value is `default`, empty, or text that still starts with `${`, use the runtime default for your environment:
   - **Claude Code**: `sonnet`
   - **Antigravity (Google)**: `neon`
   - **Codex (OpenAI)**: `sol`

Pass the resolved model each time you start the agent. Record the resolved models in `job.json`.

## Arguments

`$ARGUMENTS` selects the command:

| Input | Command |
|---|---|
| `rework <job-id> <note>` | Rework |
| `clean <job-id>` | Clean |
| `--branch <feature, file, or issue>` | New job, branch mode |
| `<feature, file, or issue>` | New job, worktree mode |

If the feature text is an existing file path, that file is the input spec.

If the feature text is `#<number>` or a GitHub issue URL, that GitHub issue is the input. The `spec-writer` saves a copy in `JOB_DIR/issue.md`. After that, all agents use the copy, not the live issue.

## job.json

```json
{
  "id": "003-reading-time",
  "title": "Show reading time on blog posts",
  "mode": "worktree",
  "repo": "/abs/path/repo",
  "workDir": "/abs/path/repo-factory/003-reading-time",
  "branch": "factory/003-reading-time",
  "base": "main",
  "stage": "build",
  "round": 1,
  "models": {
    "spec-writer": "sonnet",
    "implementer": "opus",
    "reviewer-code": "sonnet",
    "reviewer-security": "sonnet",
    "approver": "default"
  },
  "verdicts": { "code": null, "security": null },
  "decision": null,
  "prUrl": null,
  "blocked": null,
  "updatedAt": "2026-01-01T12:00:00Z"
}
```

- `stage` is one of: `spec`, `spec-approval`, `build`, `review-code`, `review-security`, `approve`, `pr-open`, `done`.
- `blocked` is `null`, or a short sentence that says why the job waits for the human. `stage` keeps the step where the job stopped.
- `verdicts` hold `PASS`, `CHANGES`, or `null` for the current round.
- `decision` is `APPROVE`, `ESCALATE`, or `null`.
- `models` holds the resolved model of each agent for this job, from "Agents and models".

## New job

### 0. Preflight

1. Read the "Commands" section of `CONFIG_MD` (`REPO/CLAUDE.md`, `REPO/AGENTS.md`, or `REPO/GEMINI.md`). You need: setup, test, lint, typecheck, build. If the section is missing, or `REPO/factory/dashboard.html` is missing, stop and tell the human to run `/forgetemple:init`.
2. Run `git status --porcelain` in `REPO`. In branch mode, the checkout must be clean. If it is not, stop and tell the human.
3. Record `BASE`.
4. Resolve the agent models (see "Agents and models").
5. If the input is a GitHub issue: run `gh issue view <number or URL> --json title,state` in `REPO`. If the command fails or the issue is closed, stop and tell the human. Use the issue title for the job title and the slug.

### 1. Create the job

1. Job id = next 3-digit number after the highest in `REPO/factory/jobs/`, plus a short slug. Example: `003-reading-time`.
2. `mkdir REPO/factory/jobs/<job-id>` without `-p`. If it fails, a different session owns that id. Use the next number.
3. Create the work area:
   - Worktree mode: `git worktree add -b factory/<job-id> ../<repo-name>-factory/<job-id> <BASE>`, then run the setup command in `WORK_DIR`.
   - Branch mode: `git switch -c factory/<job-id>`.
4. Write `job.json` with `stage: "spec"`.
5. Tell the human the job id, the models, and how to open the dashboard: run `python3 -m http.server 5175 --directory factory` in `REPO`, then open <http://localhost:5175/dashboard.html>.

### 2. Spec

1. Start `spec-writer`. Give it the feature text, the path of the input spec file, or the issue (`#<number>` or URL).
2. It writes `JOB_DIR/spec.md`. Its last line is `STATUS: READY` or `STATUS: BLOCKED`. For an issue, it also writes `JOB_DIR/issue.md`.
3. On `BLOCKED`: set `blocked`, show the human the open questions, and stop.

### 3. Stop 1: human approves the spec

1. Set `stage: "spec-approval"`.
2. Show the human: the path of `spec.md`, the acceptance criteria, the task list, and the assumptions.
3. Ask: approve, or change. Then end your turn and wait.
4. On a change request: start a new `spec-writer` with the note and the current `spec.md`. Repeat this step.
5. Continue only after the human approves.

### 4. Build

1. Set `stage: "build"`.
2. Start `implementer`.
3. It writes `JOB_DIR/build.md`. The first line is `STATUS: READY` or `STATUS: BLOCKED`.
4. On `BLOCKED`: set `blocked` with the reason, tell the human, and stop.

### 5. Review, stage 1: code

1. Set `stage: "review-code"`. Create `JOB_DIR/round-<N>/`.
2. Start `reviewer-code`. It fixes the code and commits its fixes.
3. It writes `round-<N>/review-code.md`. The first line is `VERDICT: PASS` or `VERDICT: CHANGES`.
4. Record the verdict.
5. On `CHANGES`: go to "Rework round". Do not run the security review on code that will change.

### 6. Review, stage 2: security

1. Set `stage: "review-security"`.
2. Start `reviewer-security`. It reads the diff. It does not change code.
3. It writes `round-<N>/review-security.md`. The first line is `VERDICT: PASS` or `VERDICT: CHANGES`.
4. Record the verdict.
5. On `CHANGES`: go to "Rework round".

### Rework round

- The limit is 2 rework rounds for each job (3 review rounds in total).
- If the limit is reached: set `blocked: "review rounds used up"`, tell the human which findings are open, and stop.
- If not: add 1 to `round`, set both verdicts to `null`, set `stage: "build"`. Start a new `implementer` and give it the review file or files that said `CHANGES`. Then go to step 5.

### 7. Approve

1. Set `stage: "approve"`.
2. Start `approver`.
3. It writes `JOB_DIR/decision.md`. The first line is `APPROVE` or `ESCALATE`.
4. Record `decision`.

### 8. Pull request

1. Run the test, lint, and typecheck commands one time in `WORK_DIR`. If one fails, set `blocked` and stop. Do not push broken code.
2. Check for GitHub: `git remote get-url origin` and `command -v gh`.
3. If one is missing: set `blocked: "no GitHub remote or gh tool; branch is local"`, tell the human the branch name, and stop. This is not an error.
4. If both exist:
   - `git push -u origin factory/<job-id>`
   - `gh pr create --base <BASE> --head factory/<job-id> --title "<title>" --body-file <JOB_DIR>/decision.md`
   - Add `--draft` if the decision is `ESCALATE`.
5. Record `prUrl`. Set `stage: "pr-open"`.

### 9. Stop 2: human reviews the PR

Give the human a short report:

- The PR link, and if it is a draft, why.
- The risk level from `decision.md`.
- The "Manual checks" list from `decision.md`.
- The next commands: `/forgetemple:factory rework <job-id> <note>` or, after the merge, `/forgetemple:factory clean <job-id>`.

Then end your turn.

## Rework

`/forgetemple:factory rework <job-id> <note>`

1. Read `job.json`. The job must exist and must not be `done`. Resolve the agent models again and update `models`.
2. Write the note to `JOB_DIR/rework-<k>.md` (the human's words, unchanged). Other than `job.json`, you write only this file and `rework-<k>-comment.md`, and only the script in step 7 writes `rework-<k>-comment.md`.
3. Add 1 to `round`. Set verdicts and `decision` to `null`, `blocked` to `null`, `stage: "build"`. The rework round limit starts again from zero.
4. Start a new `implementer` and give it `rework-<k>.md`.
5. Run steps 5, 6, and 7.
6. Run the checks from step 8.1. If no PR exists, do step 8 and skip step 7. If a PR exists, in `WORK_DIR`:
   - `OLD=$(git rev-parse origin/factory/<job-id>)`
   - `git push`. The open PR updates.
   - `NEW=$(git rev-parse HEAD)`
7. Update the PR, in `WORK_DIR`:
   - `gh pr edit <prUrl> --body-file <JOB_DIR>/decision.md`. The PR description now shows the latest decision.
   - `bash <PLUGIN>/scripts/rework-comment.sh <JOB_DIR> <k> $OLD $NEW`. It writes `JOB_DIR/rework-<k>-comment.md` from the job files and git. Do not write or edit this file yourself.
   - `gh pr comment <prUrl> --body-file <JOB_DIR>/rework-<k>-comment.md`.
   - If the script fails, post no comment. Tell the human the error. The push in step 6 stays.
8. Report as in step 9.

## Clean

`/forgetemple:factory clean <job-id>`

1. Read `job.json`.
2. If `prUrl` is set, run `gh pr view <prUrl> --json state`. If the state is not `MERGED`, ask the human to confirm before you continue.
3. Worktree mode: `git worktree remove <workDir>`. Branch mode: `git switch <base>`.
4. `git branch -d factory/<job-id>`. If git refuses because the branch is not merged locally, tell the human. Do not use `-D` unless the human says so.
5. Set `stage: "done"`. Keep the job folder.

## Agent brief

Start the agent with its resolved model according to your environment:

- **Claude Code**: start subagent `forgetemple:<name>` with its resolved model (`sonnet`, `opus`, `haiku`, `fable`).
- **Antigravity (Google)**: map shorthand model names to Antigravity model IDs (`neon` → `gemini-4-neon-medium`, `argon` → `gemini-4-argon-medium`, `hydrogen` → `gemini-4-hydrogen-medium`, `carbon` → `gemini-4-carbon-medium`). If the agent's model matches your current session model, invoke subagent `<name>` with `Model: "inherit"`; otherwise spawn a fresh isolated worker via `swarm` (`action: "add"`, `model: "<resolved-id>"`, `brief: "Read and follow <PLUGIN>/agents/<name>.md.\n\n<brief lines>"`) and kill that worker after its output file is verified.
- **Codex (OpenAI)**: map shorthand model names to Codex model slugs (`sol` → `gpt-6.2-sol`, `astra` → `gpt-6.2-astra`, `terra` → `gpt-6.1-terra`, `luna` → `gpt-6-luna`) and spawn a fresh isolated subagent via `spawn_agent` with `fork_turns: "none"`, `model: "<resolved-slug>"`, and a prompt to read and follow `<PLUGIN>/agents/<name>.md` with the brief below.

Give the agent these lines, and nothing more unless the step says so:

```
JOB_DIR: <absolute path>
WORK_DIR: <absolute path>
BRANCH: factory/<job-id>
BASE: <base branch>
ROUND: <N>
INPUT: <feature text, or file paths named in the step>
```

When an agent returns, read the status line of its file. Do not trust the chat reply of the agent. If the file is missing or has no status line, start the agent one more time. If it fails again, set `blocked` and stop.
