# ============================================================
# gwt - Git worktree shortcuts
#
# 统一以 `gwt` 为前缀，封装常用的 git worktree 操作。
# 新增 worktree 时，路径固定基于 main worktree 计算：
#   <main-worktree 父目录>/<main-worktree 名>-worktrees/<branch>
# 这样无论从 main worktree 还是某个 linked worktree 执行，`gwt add`
# 都会把新 worktree 放到相对项目的同一位置。
# ============================================================

# 如果 oh-my-zsh git 插件等地定义了 gwt 别名，先取消，避免函数定义冲突
unalias gwt 2>/dev/null || true

# 主入口
function gwt {
    local cmd="${1:-}"
    [[ -n "$cmd" ]] && shift

    case "$cmd" in
        add)
            _gwt_add "$@"
            ;;
        checkout|co)
            # gwt checkout -b featxxx 等价于 gwt add -b featxxx && gwt checkout featxxx
            if [[ "${1:-}" == "-b" || "${1:-}" == "-B" ]]; then
                _gwt_add "$@" && _gwt_checkout "${2:-}"
            else
                _gwt_checkout "$@"
            fi
            ;;
        remove|rm)
            _gwt_remove "$@"
            ;;
        list|ls)
            git worktree list
            ;;
        lock|unlock|move|prune|repair)
            git worktree "$cmd" "$@"
            ;;
        mv)
            git worktree move "$@"
            ;;
        help|--help|-h|"")
            _gwt_help
            ;;
        *)
            git worktree "$cmd" "$@"
            ;;
    esac
}

_gwt_help() {
    cat <<'EOF'
gwt - Git worktree shortcuts

  gwt add [-b|-B] <branch> [<base>]     基于 <base>（默认当前分支）新建分支并创建 worktree
  gwt checkout <branch>                 进入 branch 对应的 worktree 目录（支持模糊匹配）
  gwt checkout -b <branch> [<base>]     等价于 gwt add -b ... && gwt checkout <branch>
  gwt co <branch>                       checkout 的别名
  gwt co -b <branch> [<base>]           checkout -b 的别名
  gwt remove [-f] <branch>              删除 branch 对应的 worktree（支持模糊匹配）
  gwt rm [-f] <branch>                  remove 的别名
  gwt list                              列出所有 worktree
  gwt lock <worktree>                   锁定 worktree
  gwt unlock <worktree>                 解锁 worktree
  gwt move <worktree> <new-path>        移动 worktree
  gwt prune [options]                   清理失效的 worktree 元数据
  gwt repair [<path>...]                修复 worktree 管理文件

worktree 统一位置：
  <main-worktree>-worktrees/<branch>
EOF
}

# 获取 main worktree 路径（git worktree list --porcelain 的第一个 worktree）
_gwt_main_worktree() {
    git worktree list --porcelain 2>/dev/null | awk '/^worktree / {print $2; exit}'
}

# 根据分支名计算统一的 worktree 路径
_gwt_worktree_path() {
    local branch="$1"
    local mainwt
    mainwt=$(_gwt_main_worktree) || return 1
    if [[ -z "$mainwt" ]]; then
        echo "gwt: 无法确定 main worktree" >&2
        return 1
    fi

    local parent="${mainwt:h}"
    local base="${mainwt:t}"
    local wt_dir="${parent}/${base}-worktrees"

    # 父目录必须存在，git worktree add 才会成功
    mkdir -p "$wt_dir"
    echo "${wt_dir}/${branch}"
}

_gwt_add() {
    local flag="" branch="" base="" explicit_branch=0

    # 解析可选的 -b / -B
    if [[ "${1:-}" == "-b" || "${1:-}" == "-B" ]]; then
        flag="$1"
        explicit_branch=1
        shift
    fi

    branch="${1:-}"
    if [[ -z "$branch" ]]; then
        echo "gwt add: 缺少分支名" >&2
        echo "用法: gwt add [-b|-B] <branch> [<base>]" >&2
        return 1
    fi
    shift

    base="${1:-}"

    local wt_path
    wt_path=$(_gwt_worktree_path "$branch") || return 1

    # 如果未显式传 -b/-B 且分支已存在，则直接检出该分支到 worktree
    local -a create_flag=()
    if [[ $explicit_branch -eq 1 ]]; then
        create_flag=("$flag" "$branch")
    elif git show-ref --verify --quiet "refs/heads/$branch"; then
        create_flag=()
    else
        create_flag=("-b" "$branch")
    fi

    if [[ -n "$base" ]]; then
        if [[ ${#create_flag} -gt 0 ]]; then
            git worktree add "${create_flag[@]}" "$wt_path" "$base"
        else
            echo "gwt add: 分支 '$branch' 已存在，忽略 base '$base'" >&2
            git worktree add "$wt_path" "$branch"
        fi
    else
        if [[ ${#create_flag} -gt 0 ]]; then
            git worktree add "${create_flag[@]}" "$wt_path"
        else
            git worktree add "$wt_path" "$branch"
        fi
    fi
}

# 根据分支名（支持模糊）查找 worktree 路径，输出到 stdout
_gwt_find_path() {
    local query="${1:-}"
    if [[ -z "$query" ]]; then
        echo "gwt: 缺少分支名" >&2
        return 1
    fi

    # 建立分支名 -> worktree 路径 的映射
    typeset -A branch_to_path
    local wt="" br=""
    while IFS= read -r line; do
        if [[ "$line" == worktree* ]]; then
            wt="${line#worktree }"
        elif [[ "$line" == branch* ]]; then
            br="${line#branch refs/heads/}"
            branch_to_path[$br]="$wt"
        elif [[ "$line" == detached* && -n "$wt" ]]; then
            branch_to_path[detached]="$wt"
        elif [[ -z "$line" ]]; then
            wt=""
            br=""
        fi
    done < <(git worktree list --porcelain 2>/dev/null)

    if [[ ${#branch_to_path} -eq 0 ]]; then
        echo "gwt: 未找到任何 worktree" >&2
        return 1
    fi

    # 精确匹配优先
    if [[ -n "${branch_to_path[$query]:-}" ]]; then
        echo "${branch_to_path[$query]}"
        return 0
    fi

    # 模糊匹配（只匹配分支名）
    local -a matches
    for b in "${(@k)branch_to_path}"; do
        if [[ "$b" == *"$query"* ]]; then
            matches+=("$b")
        fi
    done

    if [[ ${#matches} -eq 0 ]]; then
        echo "gwt: 没有 worktree 匹配 '$query'" >&2
        return 1
    elif [[ ${#matches} -eq 1 ]]; then
        echo "${branch_to_path[$matches[1]]}"
        return 0
    else
        if command -v fzf >/dev/null 2>&1; then
            local selected
            # fzf 只显示分支名，不再混入路径
            selected=$(printf '%s\n' "${matches[@]}" | fzf --prompt="branch> " --height=40% --reverse)
            if [[ -n "$selected" ]]; then
                echo "${branch_to_path[$selected]}"
                return 0
            fi
        else
            echo "gwt: '$query' 匹配到多个 worktree：" >&2
            printf '  %s\n' "${matches[@]}" >&2
        fi
        return 1
    fi
}

_gwt_checkout() {
    local query="${1:-}"
    local wt_path
    wt_path=$(_gwt_find_path "$query") || return 1
    cd "$wt_path"
    echo "gwt: 已切换到 $wt_path"
}

_gwt_remove() {
    local -a flags=()
    while [[ "${1:-}" == -* ]]; do
        flags+=("$1")
        shift
    done

    local query="${1:-}"
    if [[ -z "$query" ]]; then
        echo "gwt remove: 缺少分支名" >&2
        echo "用法: gwt remove [-f] <branch>" >&2
        return 1
    fi

    local wt_path
    wt_path=$(_gwt_find_path "$query") || return 1

    # 如果要删除的是当前目录所在的 worktree，先切到 main worktree，
    # 否则 git worktree remove 会因为 cwd 被删除而报错。
    local mainwt
    mainwt=$(_gwt_main_worktree) || return 1
    local cwd
    cwd=$(pwd -P)
    if [[ "$cwd" == "$wt_path"* ]]; then
        cd "$mainwt"
    fi

    echo "gwt: 正在删除 worktree $wt_path"
    git worktree remove "${flags[@]}" "$wt_path"
}

# ============================================================
# zsh 补全
# ============================================================

# 列出已有 worktree 的分支名
_gwt_worktree_branches() {
    local -a branches
    while IFS= read -r line; do
        if [[ "$line" == branch* ]]; then
            branches+=("${line#branch refs/heads/}")
        elif [[ "$line" == detached* ]]; then
            branches+=("detached")
        fi
    done < <(git worktree list --porcelain 2>/dev/null)
    _describe -t branches 'worktree branches' branches
}

# 列出本地分支名
_gwt_local_branches() {
    local -a branches
    branches=(${(f)"$(git branch --format='%(refname:short)' 2>/dev/null)"})
    _describe -t branches 'branches' branches
}

# 列出 worktree 路径
_gwt_worktree_paths() {
    local -a paths
    while IFS= read -r line; do
        if [[ "$line" == worktree* ]]; then
            paths+=("${line#worktree }")
        fi
    done < <(git worktree list --porcelain 2>/dev/null)
    _describe -t paths 'worktree paths' paths
}

_gwt() {
    local cmd="${words[2]:-}"
    local prev="${words[$((CURRENT-1))]:-}"

    # 补全第一个子命令
    if [[ $CURRENT -eq 2 ]]; then
        _values 'gwt command' \
            'add[create branch + worktree]' \
            'checkout[cd into worktree]' \
            'co[alias for checkout]' \
            'remove[remove worktree]' \
            'rm[alias for remove]' \
            'list[list worktrees]' \
            'lock[lock worktree]' \
            'unlock[unlock worktree]' \
            'move[move worktree]' \
            'prune[prune stale worktrees]' \
            'repair[repair worktree admin files]'
        return
    fi

    case "$cmd" in
        checkout|co)
            # gwt checkout -b <new-branch> 时补全新分支名（用本地分支做参考）
            if [[ "$prev" == "-b" || "$prev" == "-B" ]]; then
                _gwt_local_branches
            else
                _gwt_worktree_branches
            fi
            ;;
        remove|rm)
            _gwt_worktree_branches
            ;;
        add)
            if [[ "$prev" == "-b" || "$prev" == "-B" ]]; then
                _gwt_local_branches
            else
                _gwt_local_branches
            fi
            ;;
        lock|unlock|repair)
            _gwt_worktree_paths
            ;;
        move)
            _path_files -/
            ;;
        *)
            _files
            ;;
    esac
}

# 注册补全
if (( $+functions[compdef] )); then
    compdef _gwt gwt
fi
