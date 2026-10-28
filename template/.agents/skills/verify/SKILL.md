---
name: verify
description: Check that a change actually works before declaring a task done. Use after editing code, before finishing a task, or when asked whether something works.
---

# Verify

1. Run `.agents/verify.sh` from the project root.
2. If it exits non-zero, read the first failure, fix the cause, and run it again.
   Do not edit tests or the verify script to make them pass unless the task is
   to change them.
3. If `verify.sh` only prints "no checks configured", find the project's real
   test and lint commands (package.json scripts, Makefile, pyproject, CI config)
   and run those instead. Suggest adding them to `verify.sh`.
4. Report the command you ran and its result. If you stop with failures, say
   which ones remain and why.
