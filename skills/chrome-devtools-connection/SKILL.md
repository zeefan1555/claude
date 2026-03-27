---
name: chrome-devtools-connection
description: Use when connecting or reconnecting to Chrome through the Chrome DevTools MCP tools, especially when page listing fails, the selected target is stale, or the session returns Target closed and similar attach errors.
---

# Chrome DevTools Connection

## Overview

This skill standardizes how to establish or recover a Chrome DevTools MCP session in Codex.

Use it to avoid ad hoc retries when the browser target is stale, the selected page is gone, or the MCP session is only partially attached.

## When to Use

- You need to start working with browser pages through `mcp__chrome_devtools__*`.
- `list_pages` fails with `Target.attachToTarget`, `Target closed`, or similar target/session errors.
- A page was previously selected, but follow-up actions fail because the tab was closed or replaced.
- You want a repeatable startup flow before taking snapshots, clicking, or navigating.

Do not use this skill for general web research. This is only for browser-session setup and recovery.

## Bundled Reference

Startup script:

- `references/start-codex-chrome-mcp.sh`

Use that script instead of reconstructing the Chrome launch or `npx chrome-devtools-mcp@latest --autoConnect` command from memory.
Run it as:

```bash
zsh /absolute/path/to/chrome-devtools-connection/references/start-codex-chrome-mcp.sh
```

Important: the script is a foreground process. Keep that process alive while using the Chrome DevTools MCP session.

## Quick Start

1. Call `mcp__chrome_devtools__list_pages`.
2. If it succeeds and a useful page already exists, continue with `mcp__chrome_devtools__select_page`.
3. If it fails with a transient target/session error, retry `mcp__chrome_devtools__list_pages` once.
4. If retry succeeds, select the page you need and continue.
5. If retry still fails, run `references/start-codex-chrome-mcp.sh` from the skill directory to establish or re-establish the MCP-backed Chrome session.
6. After the script is running, call `mcp__chrome_devtools__list_pages` again once.
7. If `list_pages` still reports the previously selected page is closed or otherwise stays bound to a dead target, call `mcp__chrome_devtools__new_page` immediately to force a new live target.
8. Select a useful page with `mcp__chrome_devtools__select_page`, or continue on the page returned by `mcp__chrome_devtools__new_page`.
9. Verify the session is healthy with `mcp__chrome_devtools__take_snapshot` before doing real work.

## Recovery Rules

### `list_pages` failed once

Treat a single `Target closed` style failure as recoverable. Retry once before doing anything else.

### Selected page is stale

If a later tool call fails because the selected target disappeared:

1. Call `mcp__chrome_devtools__list_pages`.
2. Select a live page with `mcp__chrome_devtools__select_page`.
3. If no suitable page exists, create one with `mcp__chrome_devtools__new_page`.

### No usable page exists

Open a new tab instead of trying to repair an unknown browser state:

- Use the user’s destination URL if one is known.
- Otherwise use `about:blank` as a clean anchor.

### Chrome is not reachable at all

If `list_pages` and `new_page` both fail because no browser session is available, use the bundled startup script first.

Preferred recovery:

1. Run `references/start-codex-chrome-mcp.sh`.
2. Re-run `mcp__chrome_devtools__list_pages` once.
3. If `list_pages` is still stuck on a closed selected page, call `mcp__chrome_devtools__new_page`.
4. If `new_page` also fails, then treat it as a deeper Chrome startup or environment issue.

Only escalate beyond the script if:

- Chrome is not installed or is too old.
- The script fails due to missing `node` or `npx`.
- The environment blocks launching or attaching to Chrome.

## Standard Tool Sequence

Preferred order:

```text
list_pages
retry list_pages once if needed
run references/start-codex-chrome-mcp.sh if session is unavailable
list_pages again
new_page if the selected target is still dead
select_page if list_pages succeeds with live pages
take_snapshot
```

Avoid jumping straight into `click`, `fill`, or `navigate_page` before the session is verified.

## Output Style

When using this skill, keep user updates short and operational:

- State whether the first `list_pages` succeeded or failed.
- State whether you retried.
- State which page you selected or whether you opened a new one.
- State when the browser context is ready.

## Common Mistakes

- Retrying the same failing action repeatedly instead of retrying `list_pages` once and then moving to `new_page`.
- Continuing to use a stale selected page after the tab has already been closed.
- Assuming a DevTools error means the page is bad when the real issue is the selected target binding.
- Reconstructing the startup command manually instead of using `references/start-codex-chrome-mcp.sh`.
- Killing or letting the startup script exit while still expecting the MCP-backed Chrome session to remain available.
- Re-running `list_pages` over and over after Chrome restart even though the binding is still pinned to a dead selected target.
- Starting browser interactions before confirming the session with `take_snapshot`.

## Invocation Notes

When you need the startup script, resolve it relative to this skill directory and run it directly. Do not duplicate the script inline in your response.

If you launch it via `exec_command`, use a long-running session and keep the returned session alive while using Chrome DevTools MCP.
