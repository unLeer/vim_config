#!/usr/bin/env bash
set -euo pipefail

# 防止被 source 执行
if [[ "$0" != "$BASH_SOURCE" ]]; then
    echo "错误：请直接执行 ./install.sh，不要用 source 或 . 运行"
    return 1
fi

# ============================================
# Vim 配置一键安装脚本
# 支持 macOS 和 Linux
# ============================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC}  $1"; exit 1; }

# 检测操作系统
detect_platform() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

PLATFORM=$(detect_platform)

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 确保 Homebrew 已安装（macOS）
ensure_brew() {
    if [[ "$PLATFORM" == "macos" ]]; then
        if ! command_exists brew; then
            info "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # 加载 brew 环境
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        ok "Homebrew"
    fi
}

# 检查并安装 Vim
check_vim() {
    if ! command_exists vim; then
        info "正在安装 Vim..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install vim
        else
            sudo apt-get update -qq
            sudo apt-get install -y -qq vim
        fi
    fi

    # 检查 Vim 版本 >= 8
    local vim_ver
    vim_ver=$(vim --version | head -1 | grep -o 'Vi IMproved [0-9]\+' | grep -o '[0-9]\+' || echo "0")
    if [[ "$vim_ver" -lt 8 ]]; then
        err "需要 Vim 8.0+，当前版本: $vim_ver"
    fi
    ok "Vim $vim_ver"

    # 检查 +clipboard 支持（.vimrc 中 set clipboard=unnamedplus 需要）
    if ! vim --version | grep -q '+clipboard'; then
        warn "Vim 未编译 +clipboard，系统剪贴板共享可能失效"
        if [[ "$PLATFORM" == "macos" ]]; then
            info "尝试通过 brew reinstall vim 获取 +clipboard..."
            brew reinstall vim
            if ! vim --version | grep -q '+clipboard'; then
                warn "仍然缺少 +clipboard，请检查 PATH 中 brew 的 vim 是否优先于系统 vim"
            fi
        fi
    else
        ok "Vim +clipboard"
    fi
}

# 检查并安装 Git
check_git() {
    if ! command_exists git; then
        info "正在安装 Git..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install git
        else
            sudo apt-get install -y -qq git
        fi
    fi
    ok "Git $(git --version | head -1)"
}

# 检查并安装 fzf
check_fzf() {
    if ! command_exists fzf; then
        info "正在安装 fzf..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install fzf
            # 安装 fzf 的 shell 集成（Ctrl-R 等）
            if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
                info "配置 fzf 快捷键..."
                "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish --no-update-rc
            fi
        else
            # 通过 git 安装 fzf
            if [[ ! -d ~/.fzf ]]; then
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                ~/.fzf/install --all --no-bash --no-fish --no-update-rc
            fi
            # 确保 PATH 中有 fzf
            if ! command_exists fzf; then
                export PATH="$PATH:$HOME/.fzf/bin"
                echo 'export PATH="$PATH:$HOME/.fzf/bin"' >> ~/.bashrc
            fi
        fi
    fi
    ok "fzf $(fzf --version | head -1)"
}

# 检查并安装 Go
check_go() {
    if ! command_exists go; then
        info "正在安装 Go..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install go
        else
            # 下载并安装最新稳定版 Go
            local GO_VERSION="1.23.4"
            local ARCH
            ARCH=$(uname -m)
            local GO_ARCH
            case "$ARCH" in
                x86_64) GO_ARCH="amd64" ;;
                aarch64|arm64) GO_ARCH="arm64" ;;
                *) err "不支持的架构: $ARCH" ;;
            esac
            local GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
            info "下载 Go ${GO_VERSION}..."
            wget -q "https://go.dev/dl/${GO_TAR}" -O "/tmp/${GO_TAR}" || \
                curl -fsSL "https://go.dev/dl/${GO_TAR}" -o "/tmp/${GO_TAR}"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "/tmp/${GO_TAR}"
            rm -f "/tmp/${GO_TAR}"
            # 添加到 PATH
            export PATH="$PATH:/usr/local/go/bin"
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        fi
    fi

    local go_ver
    go_ver=$(go version | awk '{print $3}')
    ok "Go $go_ver"

    # 确保 GOPATH/bin 在 PATH 中
    local GOPATH_BIN
    GOPATH_BIN="$(go env GOPATH)/bin"
    if ! echo "$PATH" | grep -q "$GOPATH_BIN"; then
        warn "Go 工具目录 $GOPATH_BIN 不在 PATH 中"
        info "已自动添加: export PATH=\"\$PATH:$GOPATH_BIN\""
        export PATH="$PATH:$GOPATH_BIN"
        echo "export PATH=\"\$PATH:$GOPATH_BIN\"" >> ~/.bashrc
    fi
}

# 检查并安装 Go 开发工具
check_go_tools() {
    local GOPATH_BIN
    GOPATH_BIN="$(go env GOPATH)/bin"
    export PATH="$PATH:$GOPATH_BIN"

    # gopls（Go 语言服务器，vim-go 核心依赖）
    if ! command_exists gopls; then
        info "正在安装 gopls..."
        go install golang.org/x/tools/gopls@latest
    fi
    ok "gopls"

    # gofumpt（.vimrc 中 go_fmt_command = 'gofumpt'）
    if ! command_exists gofumpt; then
        info "正在安装 gofumpt..."
        go install mvdan.cc/gofumpt@latest
    fi
    ok "gofumpt"

    # gotags（tagbar 的 Go 支持）
    if ! command_exists gotags; then
        info "正在安装 gotags..."
        go install github.com/jstemmer/gotags@latest
    fi
    ok "gotags"
}

# 创建软链接
setup_links() {
    info "配置软链接..."

    # 备份现有配置（仅当不是软链接时）
    if [[ -e ~/.vim && ! -L ~/.vim ]]; then
        local backup
        backup="$HOME/.vim.backup.$(date +%s)"
        mv ~/.vim "$backup"
        warn "备份 ~/.vim -> $backup"
    fi

    if [[ -e ~/.vimrc && ! -L ~/.vimrc ]]; then
        local backup
        backup="$HOME/.vimrc.backup.$(date +%s)"
        mv ~/.vimrc "$backup"
        warn "备份 ~/.vimrc -> $backup"
    fi

    # 删除旧软链接
    [[ -L ~/.vim ]] && rm -f ~/.vim
    [[ -L ~/.vimrc ]] && rm -f ~/.vimrc

    # 创建新软链接
    ln -sfn "$REPO_DIR/.vim" ~/.vim
    ln -sfn "$REPO_DIR/.vimrc" ~/.vimrc

    ok "~/.vim  -> $REPO_DIR/.vim"
    ok "~/.vimrc -> $REPO_DIR/.vimrc"
}

# 验证配置
verify_setup() {
    info "验证配置..."

    # 检查插件目录
    local plugin_count
    plugin_count=$(ls -d ~/.vim/pack/plugins/start/* 2>/dev/null | wc -l | tr -d ' ')
    ok "已加载 $plugin_count 个插件"

    # 检查核心命令
    local missing=()
    for cmd in vim git fzf go gopls gofumpt gotags; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "所有依赖检查通过"
    else
        err "以下依赖未安装: ${missing[*]}"
    fi
}

# 主流程
main() {
    echo "========================================"
    echo "  Vim 配置一键安装"
    echo "  平台: $PLATFORM"
    echo "  仓库: $REPO_DIR"
    echo "========================================"
    echo ""

    if [[ "$PLATFORM" == "unknown" ]]; then
        err "不支持的操作系统: $OSTYPE"
    fi

    ensure_brew
    check_git
    check_vim
    check_fzf
    check_go
    check_go_tools
    setup_links
    verify_setup

    echo ""
    echo "========================================"
    echo "  ✅ 安装完成！"
    echo "========================================"
    echo ""
    echo "常用快捷键:"
    echo "  <Space>ff   文件查找 (fzf)"
    echo "  <Space>fg   Git 文件查找"
    echo "  <Space>gd   跳转到定义 (gopls)"
    echo "  <Space>gr   查找引用"
    echo "  <Space>n    NERDTree 焦点"
    echo "  <C-n>       NERDTree 开关"
    echo "  <Space>t    Tagbar 开关"
    echo "  <Space>lb   Go Build"
    echo "  <Space>lt   Go Test"
    echo "  <Space>ld   Go Doc"
    echo "  gr          查找引用 (直接)"
    echo ""
    echo "运行 vim 测试配置是否生效:"
    echo "  vim +GoVimHelp"
    echo ""
}

main "$@"
