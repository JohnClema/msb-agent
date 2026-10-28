# msb agent

This is an opinionated `msb` setup with a base image for the `pi` and `opencode` coding agents.

## Pre-requisites

Building the image:
- docker/podman

Running the image:
- [msb](https://docs.microsandbox.dev/)
- `~/.agents` configuration on host (symlinks supported)
- `$PWD` the project directory for the agent to work in

*Inference providers*

3 inference providers are supported via environment variables:

- OpenRouter via `OPENROUTER_API_KEY`
- InceptionLabs via `INCEPTION_API_KEY`
- Ollama via local host access

*Podman*

By default, the image is built and exported using `docker`.  If you want to use `podman` instead of `docker`:

```bash
export DOCKER=podman
# build or load
```

*Utility scripts (Optional)*

The `scripts/` directory has some useful wrappers for the core `msb` commands to make it more ergonomic to work with sandboxes per directory.  Consider adding them to your `PATH`:

- `msb-run` - run a sandbox for the PWD and delete it afterwards
- `msb-create` - create a detached sandbox for the PWD
- `msb-list` - list all sandboxes for the PWD
- `msb-exec` - run a command in the first sandbox in the PWD
- `msb-clean` - delete all sandboxes for the PWD
- `msb-init` - copy the agent project template into the PWD (never overwrites)
- `msb-loop` - run a headless agent in the PWD sandbox until verification passes

Set `MSB_NET` to override the sandbox network setting (default `public,host`) for `msb-run` and `msb-create`.

## Agent project template

`template/` is a minimal, research-informed project scaffold for coding agents. See [docs/research.md](docs/research.md) for the findings behind each choice and where to find newer material.

```bash
cd my-project
msb-init
```

This creates:

- `AGENTS.md` - short project instructions, read by pi, opencode and others (`CLAUDE.md` is symlinked to it)
- `.agents/verify.sh` - the single "is it done?" check. Edit it to run your tests and lints
- `.agents/progress.md` - durable notes that survive compaction and restarts
- `.agents/skills/verify` and `.agents/skills/handoff` - Agent Skills (`SKILL.md`) that tell the agent to use the two files above

**Verify loop**

`msb-loop` runs fresh, short headless sessions in the existing sandbox for the PWD. After each one it runs the verify script, and it feeds any failure output into the next session:

```bash
msb-create
msb-loop "Fix the failing date parsing tests"

# Options
AGENT_CMD="opencode run" msb-loop "..."   # default: pi --print --approve
VERIFY_CMD="make test" msb-loop "..."     # default: .agents/verify.sh
MAX_ITERATIONS=10 msb-loop "..."          # default: 5
```

Short fresh sessions avoid context compaction, which is a known prompt injection channel in pi and opencode (see [docs/research.md](docs/research.md)). `--approve` lets pi load project `.agents/skills` in print mode. The microVM is the security boundary, not the agent's own approvals.

## Usage

**Prepare the base container image**

```bash
# Build base image
make build
# Load image into msb for use in sandboxes
make load
```

**Running a sandbox**

```bash
# Run a microvm for the current directory (auto removed)
scripts/msb-run
```

**Creating a sandbox**

Use `msb` as per [its docs](https://docs.microsandbox.dev/)

```bash
# Create a microvm for the current directory
scripts/msb-create

# Use it
scripts/msb-exec
scripts/msb-exec date
scripts/msb-exec pwd
scripts/msb-exec bash
# OR Use it manually
msb exec SANDBOX_ID
msb exec SANDBOX_ID -- date
msb exec SANDBOX_ID -- pwd
msb exec SANDBOX_ID -- bash

# Clean up all microvms for this directory
scripts/msb-list
scripts/msb-clean
# OR Clean them up selectively
msb stop SANDBOX_ID
msb rm SANDBOX_ID
```

**Inference providers from inside sandbox**

The create/run scripts both ensure that environment variables for inference providers are set to dummy values inside the sandbox, and intercept and amend any outgoing network requests to inference providers to use the correct values.

**Certificate authority inside the sandbox**

In order to proxy network requests the sandbox automatically provides a custom CA and overrides the CA chain inside the microvm (via the following environment variables) so applications accept the proxy CA:

```bash
$ env
...
CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
NODE_EXTRA_CA_CERTS=/.msb/tls/ca.pem
REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
...
```

**Certificate authority inside containers**

In order for containers inside the sandbox to accept the proxied traffic certificates, you need to propagate the relevant files and environment variables.

Example: `curl` inside container

```bash
podman run -ti --rm \
    --volume "$CURL_CA_BUNDLE":"$CURL_CA_BUNDLE" \
    --env CURL_CA_BUNDLE \
    ubuntu bash
```

Example: `node` inside container

```bash
podman run -ti --rm \
    --volume "$NODE_EXTRA_CA_CERTS":"$NODE_EXTRA_CA_CERTS" \
    --env NODE_EXTRA_CA_CERTS \
    node bash
```
