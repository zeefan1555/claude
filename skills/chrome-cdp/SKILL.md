# Chrome CDP 直连

通过 Chrome DevTools Protocol 直接连接本地 Chrome 浏览器，读取页面内容。保留完整登录态，无需 MCP。

## 前置条件

Chrome 必须以远程调试模式运行（端口 9222）。如果未开启，用以下命令启动：

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-profile-stable
```

或者在已运行的 Chrome 中：地址栏输入 `chrome://inspect/#remote-debugging`，勾选 "Allow remote debugging"。

## 使用方式

### 1. 检查 Chrome 是否可连接

```bash
curl -s http://127.0.0.1:9222/json/version
```

如果返回 JSON 说明连接正常。如果失败，说明 Chrome 未开启远程调试。

### 2. 列出所有标签页

```bash
curl -s http://127.0.0.1:9222/json/list | python3 -c "
import json, sys
tabs = json.load(sys.stdin)
for i, t in enumerate(tabs):
    if t.get('type') == 'page' and 'sw.js' not in t.get('url', '') and 'blob:' not in t.get('url', ''):
        print(f'{i}: {t.get(\"title\",\"\")} | {t.get(\"url\",\"\")}')
"
```

### 3. 导航到指定 URL

使用 `references/cdp.py navigate <url>` 在当前标签页导航，或打开新标签页。

### 4. 提取页面文本内容

使用 `references/cdp.py extract [url_keyword]` 提取指定标签页的文本内容。

### 5. 截图（可选）

使用 `references/cdp.py screenshot [url_keyword] [output_path]` 对页面截图。

## 完整工具脚本

所有操作通过 `references/cdp.py` 完成，支持以下子命令：

| 子命令 | 说明 |
|--------|------|
| `check` | 检查 Chrome 连接状态 |
| `tabs` | 列出所有标签页 |
| `navigate <url>` | 导航到 URL（复用已有标签页或新建） |
| `extract [url_keyword]` | 提取标签页文本（可按 URL 关键词匹配） |
| `screenshot [url_keyword] [path]` | 截图保存为 PNG |

### 典型流程

```bash
# 1. 检查连接
python3 /path/to/cdp.py check

# 2. 导航到目标页面
python3 /path/to/cdp.py navigate "https://x.com/some_user/status/123"

# 3. 等待页面加载后提取内容
sleep 3
python3 /path/to/cdp.py extract x.com
```

## 注意事项

- CDP 直连会访问 Chrome 的完整登录态（Cookie、Session），这是优势也是风险
- 操作浏览器时不要手动点击页面，避免干扰
- 默认端口 9222，如果冲突可以改为其他端口
- 需要 Python 3 和 `websockets` 库（`pip3 install websockets`）
