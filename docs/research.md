# Agent harness research notes

Snapshot: October 2026. Sources: alphaXiv, pi 1.4.0 docs (from npm), web
search. Each finding lists what this repo does about it.

## Findings

### 1. Keep the harness minimal; the model and the shell matter most

- [Harness Engineering: Anatomy of Eleven Systems](https://www.alphaxiv.org/abs/2609.00006)
  (Jul 2026). Source-level study of Claude Code, Codex CLI, Gemini CLI, pi,
  opencode, OpenHands, Aider and others. None uses an agent framework
  (LangChain etc.) or vector RAG over code: all use hand-rolled loops plus
  grep/glob/tree-sitter and auto-discovered Markdown context files.
  Skills (`SKILL.md`, 9/11) now lead MCP (8/11). Recommendation 1: start with a
  linear loop and add only what observed failures demand.
- [How Much of a Harness Does a Strong Agent Need?](https://www.alphaxiv.org/abs/2609.40303)
  (Sep 2026, EPFL/Apple). Giving the model a coding-agent environment
  (shell + files) was the largest effect. On top of that, search trees,
  multi-agent orchestration, extra skills, MCP and time nudges gave no
  significant gain with frontier backbones. Built on opencode.
- [Don't Blame the LLM](https://www.alphaxiv.org/abs/2607.03691) and
  [When Agents Fail: Model or Harness?](https://www.alphaxiv.org/abs/2610.32483):
  harness changes move results, but often less than claimed; measure.

**Here:** no framework, no extra orchestration. pi and opencode as-is, a short
`AGENTS.md`, two small skills, and one verify script.

### 2. Tool interface shape changes behaviour

- [The Devil Is in the Interface](https://www.alphaxiv.org/abs/2608.11386)
  (COLM 2026, 11,700 trajectories). With equal capability: atomic
  search/view/edit tools raise run-to-run consistency (up to 4.7x for weaker
  models); code-execution interfaces use 41.6% fewer steps and 56.3% fewer
  tokens; scratchpad/"think" tools do almost nothing.

**Here:** nothing to build. pi already ships atomic tools plus an optional
`codemode` tool (`"defaultTools": ["+codemode"]` in `.pi/settings.json`) worth
trying for token-heavy work.

### 3. Close the loop with a verifier, not more prompting

- "Loop engineering" (Steinberger, Osmani, Jun 2026; cited in 2609.00006):
  outer loops that re-run the agent until a verifier passes. Seen in
  OpenHands `/goal` and Hermes' verify-on-stop guard.
- [MemoHarness](https://www.alphaxiv.org/abs/2607.14159) and
  [RRSI](https://www.alphaxiv.org/abs/2609.24972): harnesses that improve
  themselves from execution traces. Promising, but research-grade.

**Here:** `scripts/msb-loop` runs fresh headless sessions until
`.agents/verify.sh` exits 0, feeding the failing output back in.

### 4. Compaction is a trust boundary, and pi/opencode are exposed

- [Compaction Laundering](https://www.alphaxiv.org/abs/2610.29869) (Oct 2026).
  Harnesses that flatten history into `[User]: ...` text before summarising
  let a forged `[User]:` line in a fetched file become a "user approval" in
  memory. Laundering rate 87-100% on pi, opencode, Cline, Aider and OpenHands;
  0% on role-typed harnesses (Codex, Gemini CLI, Qwen Code, Continue). Live
  end-to-end `curl | sh` execution in the pi TUI at ~50%. Prompt-level rules
  only cut it by 7-26 points.
- pi 1.4.0's `docs/compaction.md` still documents `serializeConversation()`
  emitting `[User]: ...` labels.

**Here:** `msb-loop` uses short fresh sessions, so compaction rarely triggers.
State lives in `.agents/progress.md`, and the `handoff` skill says not to copy
fetched instructions into it. `AGENTS.md` names the forged-`[User]:` pattern.
The microVM plus placeholder secrets limits the damage if it does happen.
This is mitigation, not a fix. The real fix is upstream: escape role labels or
keep messages role-typed.

### 5. Approval prompts and allow-rules are not a security boundary

- [From Approval to Abuse](https://www.alphaxiv.org/abs/2610.22987) (Oct 2026).
  Repo content steers Claude Code and Codex into proposing broad allow-rules
  (`curl *`, `python *`): elicited in 58% of cases, then 81% silent goal
  completion once approved.
- [SideKernel](https://www.alphaxiv.org/abs/2610.02456) (microVM sandbox for
  agents on macOS) and [Toward Securing AI Agents Like Operating Systems](https://www.alphaxiv.org/abs/2605.14932)
  argue for OS-level isolation instead.

**Here:** the microVM is the boundary. Only `$PWD` and a read-only `~/.agents`
are mounted. Secrets are placeholders swapped at the network edge for named
hosts only. `MSB_NET` lets you tighten egress per run.

### 6. Skills are a supply chain

- [Can Agents Trust Their Skills?](https://www.alphaxiv.org/abs/2609.39065),
  [SkillSecurer](https://www.alphaxiv.org/abs/2609.14079),
  [Ciphered Skill Injection](https://www.alphaxiv.org/abs/2610.18262):
  installed skills auto-activate and can carry hidden instructions.
- [Agent Skill Evolution](https://www.alphaxiv.org/abs/2610.04832): skill
  revisions change agent behaviour like code changes do; review them like code.

**Here:** `~/.agents` stays mounted read-only. The template skills are plain
Markdown with no scripts. pi needs `--approve` to load project
`.agents/skills` in headless mode. Only use that on repos you trust, or rely
on the sandbox.

## Watch list

- [Self-Evolving Coding Agents via Harness-Policy Optimization](https://www.alphaxiv.org/abs/2610.22791)
- [CTXAgent: self-controlled context management](https://www.alphaxiv.org/abs/2610.34425)
- [Doc2Harness benchmark](https://www.alphaxiv.org/abs/2610.20344)
- [SKILL.state: long-horizon skills](https://www.alphaxiv.org/abs/2608.26263)
- [Memory as Infrastructure (months-long projects)](https://www.alphaxiv.org/abs/2609.05510)

## Where to look for newer material

- Papers: alphaXiv (hot feed, `harness engineering` search), arXiv cs.SE /
  cs.AI / cs.CR listings, Hugging Face Daily Papers, Semantic Scholar alerts.
- Vendor engineering blogs: Anthropic Engineering (effective agents, context
  engineering, tool writing), OpenAI ("Harness engineering"), Google DeepMind.
- Harness source and changelogs: pi (`npm view @earendil-works/pi-coding-agent`,
  `docs/` in the package), opencode, Codex CLI, Gemini CLI, OpenHands
  software-agent-sdk, mini-swe-agent, Hermes.
- Specs: agentskills.io (`SKILL.md`), AGENTS.md, MCP, ACP, A2A.
- Benchmarks and leaderboards: SWE-bench Verified/Live/Pro, Terminal-Bench,
  MLE-bench, tau-bench, OSWorld.
- Security: OWASP Top 10 for Agentic Applications (2026), microsandbox
  advisories.
- Commentary: Simon Willison, Latent Space, Interconnects, Hacker News.
