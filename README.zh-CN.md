[![en](https://img.shields.io/badge/lang-English-blue.svg)](README.md)
[![zh-CN](https://img.shields.io/badge/lang-中文-red.svg)](README.zh-CN.md)

# dotfiles

我个人的 macOS dotfiles，按"跨机器共享 vs 单机专属"分层，保证单机专属与私有配置不会进入 GitHub。部署用 [GNU Stow](https://www.gnu.org/software/stow/)，链接到 `~/.config/`。

## 目录结构

**GitHub 上的样子**（`git clone` 下来你看到的）：

```text
dotfiles/
├── README.md
├── README.zh-CN.md
├── .gitignore
├── .markdownlint-cli2.yaml  ← 本仓库 README lint 配置
├── install.sh                ← 可选的 brew 引导脚本（CLI + cask）
└── shared/                    ← 进 git，跨机器共享
    ├── ghostty/config
    ├── git/{config, dotfiles, ignore, gitignore_global, identity-personal, hooks/}
    ├── karabiner/karabiner.json
    ├── starship/starship.toml
    ├── wezterm/wezterm.lua
    ├── yazi/{yazi.toml, keymap.toml, package.toml, plugins/}
    └── zsh/main.zsh
```

**机器上手动添加 `local/` 之后**（gitignored，**永远不会** 上传）：

```text
dotfiles/
├── ... (同上) ...
└── local/                     ← gitignored，单机覆盖层
    ├── ghostty/local.conf     ← 背景图等含绝对路径的字段
    ├── git/config.local       ← 本机的 [user] name + email
    ├── wezterm/local.lua      ← 返回一个修改 wezterm config 的函数
    ├── yazi/local.lua         ← key → 目录路径 的表（yazi 书签）
    └── zsh/local.zsh          ← 本机 PATH / alias / 代理 / conda 初始化（任何单机覆盖）
```

> **重要**：`local/` 在 `.gitignore` 里。**一次干净的 `git clone` 不会带有 `local/` 目录** —— 它只在你手动创建后存在于需要单机配置的那台机器上。所有 `shared/` 配置都被写成"local 缺失则跳过"的形式，所以一台新机器开箱即用，不需要 `local/`。

`shared/` 和 `local/` 是两个独立的 stow package。stow 之后，`~/.config/<tool>/...` 是指向本仓库内文件的符号链接。

## 为什么这样分层

- **`shared/` = 跨机器**。可公开，不含任何单机专属或敏感/身份信息。
- **`local/` = 单机**。只存在于需要它的机器：身份、单机路径、代理/网络设置、私有书签、密钥 —— 任何按机器不同、或不宜公开的东西（工作专属配置只是其中一种情况）。
- **软加载桥接（soft-load bridges）**。每份 `shared/` 配置以"文件存在则加载、不存在静默跳过"的方式 source 对应的 `local/` 覆盖。干净 clone 没有 `local/` 也照常运行。

## 新机器快速部署

要求：macOS 和 Homebrew（见 [brew.sh](https://brew.sh)）。`stow` 及其它 CLI 依赖可通过下面第 2 步的 `install.sh` 一并安装。
本仓库按 `~/dotfiles` 这个 clone 路径设计；dotfiles 专属的 Git hook 和身份 include 也刻意只匹配这个路径。

```bash
# 1. Clone
git clone git@github.com:Sniperqwer/dotfiles.git ~/dotfiles

# 2. （可选）安装本仓库依赖的 brew 包。
#    详见 `bash install.sh -h`。若你自己管理 brew 包，跳过即可。
cd ~/dotfiles && bash install.sh        # 仅装 CLI
# bash install.sh --all                  # CLI + cask（Ghostty、WezTerm、Karabiner、Typora、字体）

# 3. 如果 ~/.config/<tool> 已经存在为实体目录，先备份再删，给 stow 让位：
#    cp -aR ~/.config ~/.config.bak.$(date +%F)
#    rm -rf ~/.config/{ghostty,git,karabiner,starship,wezterm,yazi,zsh}

# 4. 部署 shared（必做）
cd ~/dotfiles
stow -v --target="$HOME/.config" --no-folding shared

# 5. 部署 local（只在已经创建过 local/ 的机器上做，即需要单机覆盖的机器）
[ -d local ] && stow -v --target="$HOME/.config" --no-folding local

# 6. 确认 ~/.zshrc 源了部署后的 main.zsh
#    若没有，加上这行：
#    source "$HOME/.config/zsh/main.zsh"

# 7. （仅 yazi）安装 package.toml 里声明的上游插件
cd ~/.config/yazi && ya pkg install

# 8. 确认 pre-commit hook 已就位（README 同步守卫）。
#    `shared/git/config` 只会在 `~/dotfiles` 中加载 `shared/git/dotfiles`；
#    后者设置 `core.hooksPath = ~/.config/git/hooks`。钩子文件以 100755
#    模式入库，git 在 clone 时会保留 +x，正常情况下不需要 chmod。
git -C ~/dotfiles config core.hooksPath          # → ~/.config/git/hooks
ls -l ~/.config/git/hooks/pre-commit             # → 指向 shared/git/hooks/ 的符号链接
[ -x ~/.config/git/hooks/pre-commit ] && echo "hook executable: yes"

#    如果最后一行没输出（例如你是手动复制过来的，或本机文件系统关掉了
#    git 的 core.fileMode），手动补回执行位：
#    chmod +x ~/dotfiles/shared/git/hooks/pre-commit
```

`--no-folding` 必加 —— 它让 `~/.config/<tool>/` 保持为实体目录，karabiner-elements 和 `ya pkg install` 的回写就不会污染本仓库。

## 跟踪文件与加载机制

| 工具      | shared 入口                          | local 覆盖                       | 桥接机制                                                                    |
|-----------|---------------------------------------|--------------------------------|---------------------------------------------------------------------------|
| zsh       | `shared/zsh/main.zsh`                 | `local/zsh/local.zsh`          | `main.zsh` 末尾 `[ -f .../local.zsh ] && source`                           |
| git       | `shared/git/config`                   | `local/git/config.local`       | `[include] path = ~/.config/git/config.local`                             |
| git (dotfiles) | `shared/git/dotfiles`、`shared/git/identity-personal` | — | `[includeIf "gitdir:~/dotfiles/"]` 加载 dotfiles 专属 hook + 公开 noreply 身份 |
| ghostty   | `shared/ghostty/config`               | `local/ghostty/local.conf`     | `config-file = ?local.conf`（前缀 `?` 表示可选）                            |
| wezterm   | `shared/wezterm/wezterm.lua`          | `local/wezterm/local.lua`      | `pcall(dofile, "~/.config/wezterm/local.lua")` 返回一个修改函数             |
| yazi      | `shared/yazi/{*.toml, plugins/}`      | `local/yazi/local.lua`         | shared keymap 预注册了一组 `g+<letter>` 槽位，全部派发到 `goto-bookmark` 插件；插件用 `pcall(dofile, ...)` 读取 `local.lua` —— local 只改 `local.lua` 即可 |
| karabiner | `shared/karabiner/karabiner.json`     | —                              | （无 include 机制；规则全放 shared）                                        |
| starship  | `shared/starship/starship.toml`       | —                              | （纯主题，没有单机覆盖需求）                                                |
| git-hooks | `shared/git/hooks/pre-commit`         | —                              | `shared/git/dotfiles` 中 `core.hooksPath = ~/.config/git/hooks`，只在 `~/dotfiles` 加载 |

## 常见任务

### 修改已跟踪的配置

```bash
$EDITOR ~/dotfiles/shared/<tool>/<file>
# 符号链接已就位，下次程序加载时改动生效。
```

### 添加单机覆盖

```bash
mkdir -p ~/dotfiles/local/<tool>
$EDITOR ~/dotfiles/local/<tool>/<file>
cd ~/dotfiles && stow -v --restow --target="$HOME/.config" --no-folding local
```

例如 `alias gs='cd ~/self/'` 这种个人目录快捷方式应放在 `local/zsh/local.zsh`，不要放进 `shared/zsh/main.zsh`。

### 把一个新工具加入 shared

```bash
mkdir -p ~/dotfiles/shared/<tool>
cp ~/.config/<tool>/<file> ~/dotfiles/shared/<tool>/<file>
rm -rf ~/.config/<tool>          # 不确定先备份
cd ~/dotfiles && stow -v --restow --target="$HOME/.config" --no-folding shared
```

### 结构变化后重新 stow（新增 / 删除文件）

```bash
cd ~/dotfiles
stow -v -R --target="$HOME/.config" --no-folding shared
stow -v -R --target="$HOME/.config" --no-folding local
```

### 完全卸载（恢复成普通 `~/.config`）

```bash
cd ~/dotfiles
stow -D --target="$HOME/.config" --no-folding shared local
# 然后从 ~/.config.bak.* 备份恢复，或手动配置。
```

## 约定

- **local 文件命名**。`local/` 里的文件要么以 `.local` 结尾（如 `config.local`），要么以 `local.` 开头（如 `local.conf`）。`.gitignore` 用 `shared/**/*.local` + `shared/**/local.*` 兜底，防止 local 文件手滑落到 shared 还能进 git。
- **yazi 插件**。`shared/yazi/plugins/` 下只跟踪 3 个自写插件。`ya pkg install` 装的上游（piper、rich-preview、toggle-pane 等）被 `shared/yazi/plugins/*.yazi/` + `!`-放行 3 个自写的规则挡住。
- **git 身份**。借助 `includeIf "gitdir:~/dotfiles/"` 规则，`~/dotfiles` 中的 commit 都用公开 noreply 身份（`Sniper <169253722+Sniperqwer@users.noreply.github.com>`），无视当前机器的默认身份。
- **`CLAUDE.md` 全局 gitignored**。如果要写仓库级 Claude Code 指引，就直接加在本 README 里。
- **yazi bookmark 槽位**。`shared/yazi/keymap.toml` 预注册了一批 `g+<letter>`：`s w p r i j m n b k t u v x y z q`，全部派发到 `goto-bookmark` 插件。要在某台机器新增跳转，只改 `local/yazi/local.lua`（shared 不动）。未配置的字母会弹通知，不会报错。yazi 内置的 g 导航保留不动：`g+g`、`g+h`、`g+c`、`g+d`、`g+f`、`g+<Space>`。
- **README 必须与 `shared/` 结构同步**。`shared/git/hooks/pre-commit` 只在 `~/dotfiles` 中通过 `shared/git/dotfiles` 接入，新增或删除 `shared/<tool>/` 顶层目录时，如果没有同时 stage `README.md` 和 `README.zh-CN.md`，commit 会被拦下。有意绕过用 `git commit --no-verify`。
- **README lint 是仓库局部配置**。`.markdownlint-cli2.yaml` 只配置本仓库 README 的 `markdownlint-cli2` 规则，不是全机器 Markdown 策略。
- **Typora 依赖**。zsh 的 `md` alias 和 yazi 的 `open-typora` 插件都依赖 Typora。`bash install.sh --cask` 或 `bash install.sh --all` 会安装它。
- **zsh 集成有 guard**。`shared/zsh/main.zsh` 只在对应文件或命令存在时初始化可选 brew shell 集成，所以局部 bootstrap 不会让 shell 启动失败。

## 给 LLM agent 的说明（Claude Code 等）

**新增内容放哪里**：

- 跨机器、不含任何单机专属或敏感信息 → `shared/<tool>/...`
- 单机专属（机器身份/邮箱、本机或内网路径、代理/网络设置、私有书签、API token —— 任何按机器不同或不宜公开的东西）→ `local/<tool>/...`

**红线**：

1. **不要**把私有或机器标识字符串写进 `shared/` —— 它是公开的。凡是把配置绑定到某个人、某台机器或某个网络的东西都算：个人**或**雇主邮箱、公司名、内部域名、kube context 名、内部基础设施路径、绝对机器路径、token/密钥。不确定时默认归入 `local/`。
2. **不要** commit `local/` 下的任何东西。它已被 gitignore，但不要试图绕过。
3. **不要**往 `shared/git/config` 加 `user.name` / `user.email`。本机默认身份属于 `local/git/config.local`，或按仓库放到目标仓库自己的 `.git/config`。
4. **不要**在跑 stow 时省掉 `--no-folding`。karabiner-elements 和 `ya pkg` 依赖 `~/.config/<tool>/` 是实体目录。
5. **不要**往 `shared/yazi/plugins/<upstream>.yazi/` 里放文件。那些归 `ya pkg` 管，`.gitignore` 也会拦住。
6. **新增或删除 `shared/<tool>/` 顶层目录时，必须在同一个 commit 里同步更新 `README.md` 和 `README.zh-CN.md`**：包括 "目录结构" 树、"跟踪文件与加载机制" 表，以及该工具特有的红线。pre-commit hook 要求两份 README 都被 stage。
7. **新增的"红线"（hard rule）也要同步到两份 README**。两份 README 的红线列表是人和 agent 共同遵循的唯一来源。

**侦查上下文的常用命令**：

```bash
git ls-files                            # 所有被跟踪的文件
rg -l '~/\.config/' shared/             # 引用了部署路径的文件
git config --show-origin user.email     # 当前身份来自哪个文件
markdownlint-cli2 README.md README.zh-CN.md
readlink ~/.config/<tool>/<file>        # 确认符号链接指向
```

**新增"软加载桥接"**（让一份 `shared/` 配置去读取对应的 `local/` 覆盖）：优先用工具原生 include 机制 —— zsh `source`、git `[include]`、ghostty `config-file = ?...`。Lua 工具用 `pcall(dofile, ...)`。如果工具没有 include 机制（karabiner、starship），就把所有配置留在 `shared/`，不要自创一套。

## 排错

- **yazi 里按 `g w` 提示 "No bookmark key given"**：`goto-bookmark` 插件 entry 函数签名必须是 `function entry(self, job)` —— yazi 26.x 第一个参数是 `self`。如果升级 yazi 之后回归这个错，回去检查插件文件。
- **Karabiner-Elements 把符号链接覆盖成了实体文件**：GUI 偶尔会做原子 rename，把 symlink 替换掉。把改动复制回 `shared/karabiner/karabiner.json` 然后 `stow -R --no-folding shared`。
- **在 `~/dotfiles` 里 `git config user.email` 返回本机默认身份而非仓库 noreply**：`includeIf "gitdir:~/dotfiles/"` 规则需要末尾斜杠和准确路径，而且 restow `shared/` 后 `~/.config/git/dotfiles` 必须存在。在仓库内跑 `git config --show-origin user.email` 看是哪份配置生效。
- **首次部署时 stow 报 conflict**：目标路径已存在实体目录。备份后 `rm -rf` 掉，再 stow。
- **pre-commit hook 拦下了 commit，提示 README 未同步**：你新增或删除了 `shared/<tool>/` 顶层目录。更新 `README.md` 和 `README.zh-CN.md`，把两份都 stage 后再提交；只有明确要绕过时才用 `--no-verify`。
- **yazi 里按 `g+s`（或任意 `g+<letter>`）提示 "No bookmark for: X"**：在 `local/yazi/local.lua` 里加 `X = "..."`。shared keymap 中所有保留字母都派发到 bookmark 插件，路径由 local 提供。
