---
name: connect-chrome
description: Use when the goal is simply to connect or reconnect Chrome for browser control in Codex, especially when the user asks to link Chrome, reconnect Chrome, start Chrome DevTools MCP, or recover after Chrome was closed.
---

# Connect Chrome

## Overview

This is a thin trigger skill for short user requests like "connect Chrome" or "reconnect Chrome".

Use the full workflow defined in:

- `/Users/bytedance/.codex/skills/chrome-devtools-connection/SKILL.md`

## Rule

Do not invent a separate connection flow here.

Always follow the recovery and startup sequence from `chrome-devtools-connection`, including:

- retrying `list_pages` once
- starting the bundled Chrome DevTools MCP script if needed
- using `new_page` when the selected target remains dead after Chrome restart
- verifying with `take_snapshot`
