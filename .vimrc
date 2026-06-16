" ============================================================
"  Go 开发专用 Vim 配置 (Vim 8 兼容版)
"  插件管理：Vim 8 原生 pack 机制
" ============================================================

" --------------------
" 基础设置
" --------------------
set nocompatible              " 关闭 Vi 兼容模式
set number                    " 显示绝对行号
set norelativenumber          " 关闭相对行号（防止行号随光标跳动）
set cursorline                " 高亮当前行
set laststatus=2              " 始终显示状态栏
set showcmd                   " 显示正在输入的命令
set showmode                  " 显示当前模式
set wildmenu                  " 命令行补全增强
set wildmode=longest,list,full
set completeopt=menu,menuone,noselect

" 缩进与排版
set expandtab                 " Tab 转空格
set tabstop=4                 " Tab 宽度
set shiftwidth=4              " 自动缩进宽度
set softtabstop=4
set autoindent                " 自动缩进
set smartindent               " 智能缩进
set backspace=indent,eol,start

" 搜索设置
set hlsearch                  " 高亮搜索结果
set incsearch                 " 增量搜索
set ignorecase                " 忽略大小写
set smartcase                 " 智能大小写（有大写字母时区分大小写）

" 性能与体验
set lazyredraw                " 减少重绘，提升性能
set ttyfast                   " 快速终端连接
set updatetime=300            " 更快触发 CursorHold 事件（影响 gopls 诊断）
set hidden                    " 允许切换 buffer 不保存
set autoread                  " 文件外部修改时自动重载

" signcolumn（Vim 8.1.1564+ 支持 yes，低版本自动跳过）
if exists('+signcolumn')
    set signcolumn=yes
endif

set clipboard=unnamedplus     " 与系统剪贴板共享（需要 +clipboard 支持）

" 编码
set encoding=utf-8
set fileencodings=utf-8,gbk,gb2312,gb18030

" 备份与撤销
set nobackup
set nowritebackup
set noswapfile
set undofile                  " 持久化撤销历史
set undodir=~/.vim/undo//

" 创建必要目录
silent! call mkdir(expand('~/.vim/undo'), 'p')

" --------------------
" 快捷键前缀设置
" --------------------
let mapleader = "\<Space>"
let maplocalleader = "\<Space>"

" --------------------
" 配色与外观（gruvbox 官方推荐配置）
" 参考：https://github.com/morhetz/gruvbox/wiki/Installation
" --------------------
" 关键：禁用终端背景色查询，防止 Vim 启动几秒后跳回浅色
let &t_RB = ""
let &t_RF = ""

" 先设置 background=dark，再 syntax on，防止 syntax on 检测终端为浅色
set background=dark
syntax on
filetype plugin indent on

" gruvbox 配置（必须在 colorscheme 之前设置）
let g:gruvbox_bold = 1
let g:gruvbox_italic = 0                  " 终端常不支持斜体，关闭避免显示异常
let g:gruvbox_underline = 1
let g:gruvbox_undercurl = 1
let g:gruvbox_termcolors = 256
let g:gruvbox_contrast_dark = 'hard'      " hard = 最深对比，颜色更鲜明
let g:gruvbox_invert_selection = 1
let g:gruvbox_italicize_comments = 0      " 同上，避免终端斜体乱码
let g:gruvbox_italicize_strings = 0
let g:gruvbox_improved_strings = 0
let g:gruvbox_improved_warnings = 0

set clipboard=unnamed

" 真彩色支持
" 注意：macOS Terminal.app 不支持真彩色，开启后颜色反而更差
" iTerm2 / Alacritty / WezTerm 等现代终端建议开启
if has('termguicolors') && getenv('TERM_PROGRAM') != 'Apple_Terminal'
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

" 自定义高亮覆盖（autocmd ColorScheme 确保 colorscheme 重载后仍然生效）
autocmd ColorScheme * highlight Cursor guibg=Red guifg=White ctermbg=Red ctermfg=White
autocmd ColorScheme * highlight goType guifg=#83a598 ctermfg=109
autocmd ColorScheme * highlight goFunction guifg=#b8bb26 ctermfg=142
autocmd ColorScheme * highlight goField guifg=#fabd2f ctermfg=214

" 直接加载 gruvbox（Vim 8 pack/start 插件在启动早期已加载）
colorscheme gruvbox

" 兜底：gruvbox 未安装时依次尝试其他配色
if !exists('g:colors_name')
    silent! colorscheme molokai
endif
if !exists('g:colors_name')
    silent! colorscheme desert
endif
if !exists('g:colors_name')
    silent! colorscheme slate
endif
if !exists('g:colors_name')
    colorscheme default
endif

" 关键：VimEnter 后再次强制 background=dark 并重新加载 gruvbox
" 防止 NERDTree / vim-go 等插件加载时触发 background 自动检测，
" 把 background 改回 light 导致颜色变回浅黄色
" 同时修复 Go 文件的 ftplugin 在 pack 机制下未加载的问题
autocmd VimEnter * set background=dark | colorscheme gruvbox | if &filetype == 'go' | unlet! b:did_ftplugin | runtime! ftplugin/go.vim ftplugin/go/*.vim | endif | highlight Cursor guibg=Red guifg=White ctermbg=Red ctermfg=White | highlight goType guifg=#83a598 ctermfg=109 | highlight goFunction guifg=#b8bb26 ctermfg=142 | highlight goField guifg=#fabd2f ctermfg=214

" --------------------
" 字体设置
" --------------------
" 注意：终端 Vim 的字体大小由终端模拟器控制，Vim 本身无法调整。
" 如果你用的是 iTerm2 / Terminal.app / Alacritty 等，请去终端偏好设置里改字体大小。
"
" 以下是各终端的字体调整方式：
"   iTerm2:      Preferences → Profiles → Text → Font Size
"   Terminal.app: 设置 → 描述文件 → 文本 → 字体
"   Alacritty:   修改 ~/.config/alacritty/alacritty.yml 中 font.size
"   WezTerm:     修改 ~/.wezterm.lua 中 font_size
"   Windows Terminal: 设置 → 外观 → 字体大小
"
" 如果你用的是 GUI Vim（gVim / MacVim），可以在这里直接指定字体和大小：
if has('gui_running')
    " macOS / Linux (GTK)
    set guifont=JetBrainsMono\ Nerd\ Font:h14
    " Windows 用下面这行：
    " set guifont=JetBrainsMono_NF:h14:cANSI
endif

" --------------------
" NERDTree 配置
" --------------------
" 快捷键
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTreeToggle<CR>
" 在命令行输入 :dt 时自动展开为 :NERDTree
cnoreabbrev dt NERDTree
nnoremap dt :NERDTree<CR>

" 在 NERDTree 中定位当前文件
nnoremap <leader>f :NERDTreeFind<CR>

" 启动时自动打开（没有指定文件时）
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif

" 关闭 NERDTree 后如果只剩它一个窗口则退出
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" NERDTree 设置
let g:NERDTreeShowHidden = 1              " 显示隐藏文件
let g:NERDTreeMinimalUI = 1               " 最小化 UI
let g:NERDTreeIgnore = ['\.git$', '\.svn$', '\.hg$', 'node_modules$', '__pycache__$', '\.exe$', '\.o$', '\.a$']
let g:NERDTreeStatusline = ''               " 禁用 NERDTree 状态栏
" 使用 ASCII 箭头，避免终端字体不支持 Unicode 时显示乱码
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

" --------------------
" vim-go 配置（Go 开发核心）
" --------------------
" 启用 gopls（Go 语言服务器）提供跳转、补全、诊断等
let g:go_gopls_enabled = 1
let g:go_def_mode = 'gopls'
let g:go_info_mode = 'gopls'
let g:go_referrers_mode = 'gopls'
let g:go_implementations_mode = 'gopls'
let g:go_doc_url = 'https://pkg.go.dev'

" 代码检查（Lint / Vet / Build）
let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck', 'staticcheck']
let g:go_metalinter_autosave = 1          " 保存时自动运行 linter
let g:go_metalinter_autosave_enabled = ['vet', 'golint']
let g:go_metalinter_deadline = '5s'

let g:go_fmt_autosave = 1                 " 保存时自动格式化
let g:go_fmt_command = 'gofumpt'          " 使用 gofumpt（更严格的格式化）
let g:go_imports_autosave = 1             " 保存时自动管理 imports
let g:go_imports_mode = 'gopls'

" 高亮设置
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1

" 诊断（错误/警告显示）
let g:go_diagnostics_enabled = 1
let g:go_diagnostics_vulncheck = 'Off'
let g:go_list_type = 'quickfix'           " 使用 quickfix 列表显示错误

" 测试相关
let g:go_test_timeout = '30s'
let g:go_test_show_name = 1

" 其他
let g:go_auto_type_info = 1               " 自动显示类型信息（状态栏）
let g:go_auto_sameids = 0                 " 不自动高亮相同标识符（避免干扰）
let g:go_doc_popup_window = 1             " 使用浮动窗口显示文档

" --------------------
" Go 开发快捷键（vim-go）
" --------------------
" 跳转
" 跳转到定义
nnoremap <leader>gd :GoDef<CR>
" 在 split 中跳转到定义
nnoremap <leader>gs :GoDefSplit<CR>
" 在 vsplit 中跳转到定义
nnoremap <leader>gv :GoDefVertical<CR>
" 跳转到类型定义
nnoremap <leader>gt :GoDefType<CR>
" 查找引用 ★
nnoremap <leader>gr :GoReferrers<CR>
" 查找接口实现
nnoremap <leader>gi :GoImplements<CR>
" 查找调用者
nnoremap <leader>gc :GoCallers<CR>
" 查找被调用者
nnoremap <leader>gC :GoCallees<CR>
" 查找 channel peers
nnoremap <leader>gp :GoChannelPeers<CR>

" 直接 gr 查找引用（不依赖 leader 键）
nnoremap gr :GoReferrers<CR>

" 检查与构建
" 构建
nnoremap <leader>lb :GoBuild<CR>
" 运行当前测试
nnoremap <leader>lt :GoTest<CR>
" 运行当前函数测试
nnoremap <leader>lT :GoTestFunc<CR>
" 显示测试覆盖率
nnoremap <leader>lc :GoCoverage<CR>
" 运行 linter
nnoremap <leader>ll :GoLint<CR>
" 运行 go vet
nnoremap <leader>lv :GoVet<CR>
" 运行 errcheck
nnoremap <leader>le :GoErrCheck<CR>
" 运行全部 linter
nnoremap <leader>lm :GoMetaLinter<CR>

" 信息查看
" 查看文档
nnoremap <leader>ld :GoDoc<CR>
" 在浏览器中查看文档
nnoremap <leader>lD :GoDocBrowser<CR>
" 显示类型信息
nnoremap <leader>li :GoInfo<CR>
" 描述标识符
nnoremap <leader>ls :GoDescribe<CR>

" 代码操作
" 手动格式化
nnoremap <leader>lf :GoFmt<CR>
" 切换 .go / _test.go
nnoremap <leader>la :GoAlternate<CR>
" 重命名（会提示输入新名称）
nnoremap <leader>lr :GoRename<CR>
" 提取函数（需要 gopls）
nnoremap <leader>lx :GoExtract<CR>

" --------------------
" fzf 配置（模糊查找）
" --------------------
" 文件查找
nnoremap <leader>ff :Files<CR>
" Git 文件
nnoremap <leader>fg :GFiles<CR>
" Buffer 切换
nnoremap <leader>fb :Buffers<CR>
" 最近打开的文件
nnoremap <leader>fh :History<CR>
" 当前文件内行查找
nnoremap <leader>fl :BLines<CR>
" 所有打开文件的行查找
nnoremap <leader>fL :Lines<CR>
" Git commits
nnoremap <leader>fc :Commits<CR>
" 当前文件标签
nnoremap <leader>ft :BTags<CR>
" 项目标签
nnoremap <leader>fT :Tags<CR>
" 在所有文件中搜索内容（Ripgrep）
nnoremap <leader>rr :Rg<CR>

" fzf 打开方式
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit',
  \ 'enter': 'tab split',
  \ }

" fzf 窗口设置
let g:fzf_layout = { 'down': '40%' }
let g:fzf_preview_window = ['right:50%', 'ctrl-/']

" Rg 命令使用真正的 ripgrep（避免 shell 函数干扰）
let g:fzf_rg_bin = '/opt/homebrew/bin/rg'
command! -bang -nargs=* Rg call fzf#vim#grep(g:fzf_rg_bin . ' --column --line-number --no-heading --color=always --smart-case ' . shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)

" --------------------
" Tagbar 配置
" --------------------
nnoremap <leader>t :TagbarToggle<CR>
let g:tagbar_width = 35
let g:tagbar_autofocus = 1
let g:tagbar_autoclose = 1

" Go 语言 tagbar 支持（依赖 gotags，vim-go 会自动处理）
let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }

" --------------------
" Airline 配置
" --------------------
" Airline 主题与配色方案对应表（按需修改）：
"   gruvbox     -> 'gruvbox'
"   molokai     -> 'molokai'
"   dracula     -> 'dracula'
"   jellybeans  -> 'jellybeans'
"   onedark     -> 'onedark'
"   desert      -> 'dark' 或 'powerlineish'
"   slate       -> 'dark' 或 'powerlineish'
let g:airline_theme = 'gruvbox'

" 关闭 powerline 字体，避免未安装 Nerd Font / Powerline 字体时显示乱码方块
" 如果你已安装 Nerd Font，可将下面这行改为 1
let g:airline_powerline_fonts = 0

" 使用 ASCII 风格分隔符（兼容任何终端字体）
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_left_sep = ''
let g:airline_left_alt_sep = '|'
let g:airline_right_sep = ''
let g:airline_right_alt_sep = '|'
let g:airline_symbols.branch = 'BR'
let g:airline_symbols.readonly = 'RO'
let g:airline_symbols.linenr = 'LN'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.dirty = '*'

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#hunks#enabled = 1

" --------------------
" Git Gutter 配置
" --------------------
let g:gitgutter_enabled = 1
let g:gitgutter_signs = 1
let g:gitgutter_highlight_lines = 0
let g:gitgutter_highlight_linenrs = 1
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'

" --------------------
" 通用快捷键
" --------------------
" 窗口导航
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Tab 切换
nnoremap <C-u> :tabp<CR>
nnoremap <C-p> :tabn<CR>

" 在 iTerm2 打开当前文件目录
nnoremap <silent> <C-t> :call OpenItermInCurrentDir()<CR>

" 分屏
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>s :split<CR>

" Buffer 操作
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bl :ls<CR>

" 快速保存/退出
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :qa!<CR>
nnoremap <leader>x :x<CR>

" 取消搜索高亮
nnoremap <leader><Space> :nohlsearch<CR>

" 行移动
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" 系统复制粘贴（无 +clipboard 时的备选）
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>p "+p
vnoremap <leader>p "+p
nnoremap <leader>P "+P

" --------------------
" 自定义函数
" --------------------
" 在 iTerm2 打开当前文件目录（macOS）
function! OpenItermInCurrentDir()
    let l:dir = expand('%:p:h')
    if l:dir == ''
        let l:dir = getcwd()
    endif

    let l:cmd = 'osascript -e ''tell application "iTerm2"'' '
                \ . '-e ''tell current window'' '
                \ . '-e ''create tab with default profile'' '
                \ . '-e ''tell current session of current tab'' '
                \ . '-e ''write text "cd ' . shellescape(l:dir) . ' && clear"'' '
                \ . '-e ''end tell'' '
                \ . '-e ''end tell'' '
                \ . '-e ''end tell'''

    call system(l:cmd)
endfunction

" --------------------
" 自动命令
" --------------------
" 进入 Go 文件时的特殊设置
augroup GoSettings
    autocmd!
    " 保存时自动格式化、整理 imports、运行 linter
    autocmd BufWritePre *.go silent! GoFmt
    autocmd BufWritePre *.go silent! GoImports

    " 快速运行当前 Go 文件
    autocmd FileType go nnoremap <leader>r :GoRun %<CR>

    " 显示当前函数名在状态栏
    autocmd FileType go let b:airline_whitespace_disabled = 1
augroup END

" 返回上次编辑位置
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

" --------------------
" 帮助提示
" --------------------
" 首次启动显示快捷键提示
function! GoVimHelp()
    echo "=== Go Vim 快捷键速查 ==="
    echo "<Space>n    : NERDTree 焦点"
    echo "<C-n>       : NERDTree 开关"
    echo "<Space>gd   : 跳转到定义"
    echo "<Space>gr   : 查找引用"
    echo "<Space>gi   : 查找实现"
    echo "<Space>gt   : 跳转到类型定义"
    echo "<Space>lb   : Go Build"
    echo "<Space>lt   : Go Test"
    echo "<Space>ll   : Go Lint"
    echo "<Space>ld   : Go Doc"
    echo "<Space>ff   : 查找文件 (fzf)"
    echo "<Space>fb   : 查找 Buffer"
    echo "<Space>t    : Tagbar 开关"
    echo "gr          : 查找引用 (直接)"
    echo "========================"
endfunction

command! GoVimHelp call GoVimHelp()
nnoremap <leader>? :GoVimHelp<CR>

" 启动时显示提示（可选，注释掉则禁用）
" autocmd VimEnter * call GoVimHelp()
