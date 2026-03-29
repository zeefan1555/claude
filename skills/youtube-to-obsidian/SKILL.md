---
name: youtube-to-obsidian
description: Save YouTube video transcript and content summary to Obsidian vault. Use after downloading a YouTube transcript, or when user asks to save/summarize a YouTube video to Obsidian.
allowed-tools: Bash,Read,Write,Edit,Glob
---

# YouTube to Obsidian

将 YouTube 视频的字幕转录和内容总结保存到 Obsidian 知识库。

## When to Use This Skill

- 用户要求将 YouTube 视频内容保存到 Obsidian
- 用户要求总结 YouTube 视频并存档
- 下载完 YouTube 字幕后，需要归档到 Obsidian
- 用户提到"保存到 Obsidian"、"存到笔记"等意图，且内容来源是 YouTube

## Obsidian Vault Path

`agent/` 是 Obsidian vault 的根目录，所有内容必须放在其下。

```
VAULT="/Users/yibeikongqiu/Library/Mobile Documents/iCloud~md~obsidian/Documents/agent"
```

## Directory Structure

```
agent/YouTube/
  视频标题.md              ← 内容总结笔记
agent/YouTube/字幕/
  视频标题-字幕.md          ← 完整转录文本
```

## Workflow

### Step 1: Ensure Directories Exist

```bash
VAULT="/Users/yibeikongqiu/Library/Mobile Documents/iCloud~md~obsidian/Documents"
mkdir -p "$VAULT/YouTube/字幕"
```

### Step 2: Get Transcript Content

If transcript is already downloaded (e.g., via `youtube-transcript` skill), read the existing transcript file.

If not yet available, call the `youtube-transcript` skill first to download.

### Step 3: Save Transcript to Obsidian

Save the plain text transcript as a Markdown file in `YouTube/字幕/`.

**Filename**: `{视频标题}-字幕.md`

**File format**:

```markdown
---
tags:
  - YouTube
  - 字幕
source: {YOUTUBE_URL}
date: {YYYY-MM-DD}
---

# {视频标题} - 字幕

{完整转录文本，每句一行}
```

### Step 4: Create or Update Summary Note

Save the content summary in `YouTube/`.

**Filename**: `{视频标题}.md`

**File format**:

```markdown
---
tags:
  - YouTube
  - {根据内容添加相关标签}
source: {YOUTUBE_URL}
date: {YYYY-MM-DD}
---

# {视频标题}

## 概述

{1-3 句话概括视频核心内容}

## 主要内容

{结构化的内容总结，根据视频内容分段整理}

## 关键要点

{提炼的关键信息、步骤或结论}

## 字幕原文

完整转录文本：[[{视频标题}-字幕]]
```

> **Important**: Use Obsidian wikilink `[[{视频标题}-字幕]]` to link to the transcript file. This creates a clickable link in Obsidian.

### Step 5: Confirm

Tell the user:
- Summary saved to: `YouTube/{视频标题}.md`
- Transcript saved to: `YouTube/字幕/{视频标题}-字幕.md`

## Notes

- If a summary note already exists in `YouTube/`, update it rather than overwrite — check first and ask user.
- Tags should include `YouTube` plus topic-relevant tags inferred from content.
- Date should be the current date (when the note is created), not the video upload date.
- Transcript filename must match the wikilink in the summary note exactly.
- Keep filenames clean: replace `/` `?` `"` `:` with `-` or remove them for filesystem compatibility.
