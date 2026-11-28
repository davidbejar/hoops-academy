# Runbook: a separate GitHub credential for agent sessions

Finding AG-05 of the [agentic threat model](../security/agentic-threat-model.md), decision 126, ADR-0078. Today every
agent's shell uses the owner's `gh` login (scopes `repo`, `workflow`, `gist`, `read:org`; admin on the repository) and
the owner's git credential, so GitHub cannot tell an agent from the owner: a ruleset, a required review or `CODEOWNERS`
binds agents only once they use a narrower credential. This page says which one, how the owner sets it, and how to
check it. **The owner does this; an agent never creates, reads or changes the token.** Status: not set up yet (the
owner's pending action).

## Which token
A fine-grained personal access token of the owner's account (GitHub, Settings → Developer settings → Fine-grained
tokens):

| Setting | Value |
|---|---|
| Name | `hoops-academy agent sessions` |
| Expiration | 90 days (a calendar reminder to rotate it) |
| Resource owner | the owner's account |
| Repository access | Only select repositories: `hoops-academy` |

Repository permissions it **needs**:

| Permission | Access | For |
|---|---|---|
| Metadata | Read | mandatory for every fine-grained token |
| Contents | Read and write | `git fetch`, `git push origin <wp-slug>` (branches), the rebase merge |
| Pull requests | Read and write | `gh pr create`, `gh pr view`, `gh pr merge --rebase` |
| Actions | Read | `gh run list`, `gh run watch`, logs of a failed job |
| Commit statuses | Read | `gh pr checks` |

It **must not have**: Administration (repository settings, rulesets, branch protection), Workflows (changing
`.github/workflows`), Secrets, Variables, Environments, Deployments, Pages, Webhooks, any account permission, and access
to any other repository. Without Workflows, GitHub refuses a push of a branch that changes `.github/workflows`: such a
branch is pushed by the owner with their own login. That is intended, workflow changes get the owner's hands (AG-04).

The orchestrator pushes branches and merges pull requests (decision 125); work-package agents are told not to push
(brief Working rules). All agents of one session share its environment, so the token cannot tell them apart: the
narrower rights bind them all, the push rule stays a written one.

## Where it is set
Not in a file of the repository and not in `.env` (agents read the main checkout's files). In the macOS Keychain, put
there by the owner, who types the token at the prompt:

```bash
security add-generic-password -s hoops-agent-gh -a "$USER" -w     # asks for the token; it is never echoed
```

The owner starts Claude Code for this project with the token in the session's environment instead of their login,
from their own terminal:

```bash
GH_TOKEN="$(security find-generic-password -s hoops-agent-gh -w)" \
GH_CONFIG_DIR="$HOME/.config/gh-hoops-agent" \
GIT_CONFIG_COUNT=2 \
GIT_CONFIG_KEY_0=credential.https://github.com.helper GIT_CONFIG_VALUE_0= \
GIT_CONFIG_KEY_1=credential.https://github.com.helper GIT_CONFIG_VALUE_1='!gh auth git-credential' \
claude
```

- `GH_TOKEN` takes precedence over a stored `gh` login.
- `GH_CONFIG_DIR` points `gh` at an empty configuration, so the owner's stored login is not found by name.
- The two `GIT_CONFIG_*` pairs clear the credential helper for github.com (the owner's Keychain entry) and let `gh`
  answer git's credential requests with `GH_TOKEN`, so `git push` uses the token too.

The owner's own terminals keep the owner's admin login for repository settings, rulesets and workflow changes.

## How to check it
In the agent session (each line only reads; none prints the token):

```bash
gh auth status                       # "Logged in to github.com … (GH_TOKEN)"; not the keyring login
gh api repos/{owner}/{repo} --jq .full_name           # works: Metadata read
gh pr list --limit 1                                  # works: Pull requests read
gh run list --limit 1                                 # works: Actions read
gh secret list                                        # refused (HTTP 403): no Secrets permission
gh api repos/{owner}/{repo}/actions/permissions       # refused (HTTP 403): no Administration permission
git ls-remote origin HEAD                             # works through gh's credential helper
```

The first `git push origin <wp-slug>` of the next round proves Contents write; a push of a branch that changes a
workflow is refused, which proves the Workflows permission is absent. `gh api` writes and deletes ask the owner anyway
(the Claude hook, `gh-api-write`, `gh-delete`, `gh-repo-settings`).

## What it does not stop
- Commits still carry the owner's name as author (the git identity is the owner's). An agent identity for commits
  (`GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL` in the same start line) is an option the owner may add.
- Agents run as the owner's macOS user: a determined agent could unset the variables above, ask the Keychain for the
  owner's entries (macOS may show an access prompt) or read `~/.config/gh`. The token narrows what a mistake or an
  injected instruction can do on GitHub; it is not a sandbox. The operating-system sandbox is recorded as an open item
  (decision 127).

## Rotation and revocation
Before it expires, or at once after a suspected leak: create the new token with the same settings, replace the Keychain
item (`security delete-generic-password -s hoops-agent-gh`, then add it again), start a new session, revoke the old
token on GitHub. GitHub's security log of the account shows the token's use.
