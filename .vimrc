"使用za进行打开关闭折叠
"---------User define set option-----------
"基本配置{{{
"设置mapleader
let mapleader = ","
let maplocalleader = ",,"
"高亮配色设置
syntax on  "语法高亮度显示
set t_Co=256  "开启256色支持
set hlsearch  "搜索设置高亮
colorscheme desert "配色方案
set background=dark "配置主题整体的色调，只有两个选择：dark和light（暗色调和亮色调）
highlight Function cterm=bold,underline ctermbg=red ctermfg=green "color set

"屏蔽相关功能设置
set nocompatible "不兼容vi 
set noerrorbells " 不让vim发出讨厌的滴滴声 
set shortmess=ati " 启动的时候不显示那个援助索马里儿童的提示 
set novisualbell "不要闪烁
"关闭各种按键叮叮声音和闪屏
set vb t_vb=
au GuiEnter * set t_vb=

"禁止相关文件的产生
set noundofile "禁止un~文件
set nobackup "禁止~文件
set noswapfile "禁止swp文件

"辅助编码显示栏目
set nu  "显示行号
"set relativenumber "显示相对行号
set cursorcolumn "add cursor in column
set cursorline "add cursor in line 
set lines=50 columns=230 "其中lines是窗口显示的行数，columns是窗口显示的列数
set expandtab "expandtab 选项把插入的 tab 字符替换成特定数目的空格。具体空格数目跟 tabstop 选项值有关
set tabstop=4 "tab键相当于4个空格键
set shiftwidth=4 "换行自动变为空格
set autoindent "设置自动缩进  自动缩进，当你第一行敲 tab + 文字 回车后 下一行自动给你加个 tab 
set backspace=2 "使用 backspace
set laststatus=2 "启动显示状态行
set encoding=utf-8 "文件编码
set completeopt=menu,preview,longest "自动补全相关的设置
"}}}
"guifont for windows or linux{{{
if has('win32') || has ('win64')
    set guifont=Courier_new:h12"for windows
else
    set guifont=Monospace\ 16 "gui style for linux
endif
"}}}

"-------------------MAP OPTION-------------------
inoremap jk <ESC> g,"在编辑模式下使用jk替代ESC进入命令模式
"对齐例化后的信息,保证你的信号名称小于55个字符，否则会有错误。将数字55修改的稍微大一些 F6{{{
nnoremap <F6> 0i            <ESC>0dwi    <ESC>^f(i                                                                                            <ESC>^55ldwa            <ESC>bldwf)i                                                              <ESC>^f(55ldwj
"}}}
"设置快速编辑.vimrc的快捷键 ,ev ,sv{{{
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
"}}}
"输入输出端口 形式必须为 位宽 + 信号信号名称 使用,ii ,oo 来声明{{{
"功能描述 输入<leader>ii <leader>oo 自动生成输入输入模板，需要输入端口信号位宽，信号名称
nnoremap <leader>ii <ESC>0i        <ESC>0dwi    input   wire                                                                            <ESC>020li[<ESC>ldwwi                        <ESC>028li-1: 0]<ESC>wi                                                            <ESC>044ldwea                                                                                                                <ESC>089li,<ESC>0f,a                                <ESC>bldwj
nnoremap <leader>oo <ESC>0i        <ESC>0dwi    output  wire                                            <ESC>020li[<ESC>ldwwi                        <ESC>028li-1: 0]<ESC>wi                                                            <ESC>044ldwea                                                                                                                <ESC>089li,<ESC>0f,a                                <ESC>bldwj
"}}}
"设置bffer的切换 使用 Ctrl J、K、H切换或者删除{{{ 
"切换buffer以及删除buffer
nnoremap <C-j> :bn<CR>
nnoremap <C-k> :bp<CR>
nnoremap <C-h> :bwipe<CR>
"}}}

"----------------- PLUGIN -------------------
"air-line {{{
let g:airline#extensions#tabline#enabled=1 "顶部tab显示"
let g:airline#extensions#tabline#buffer_idx_mode = 1 "显示buffer number"
let g:airline#extensions#whitespace#enabled = 0 "清楚traling的警告"

let g:airline_left_sep = '►'
let g:airline_left_alt_sep = '>'
let g:airline_right_sep = '◄'
let g:airline_right_alt_sep = '<'
"}}}
"rainbow {{{
let g:rainbow_active = 1
    let g:rainbow_conf = {
    \    'guifgs': ['cyan', 'yellow', 'lightred', 'lightgreen','lightyellow','magenta'],
    \    'ctermfgs': ['cyan', 'yellow', 'lightred', 'lightgreen','lightyellow','magenta'],
    \    'operators': '_,_',
    \    'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
    \    'separately': {
    \        '*': {},
    \        'tex': {
    \            'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
    \        },
    \        'lisp': {
    \            'guifgs': ['lightmagenta', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
    \        },
    \        'vim': {
    \            'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
    \        },
    \        'html': {
    \            'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
    \        },
    \        'nerdtree': 0, 
    \    }
    \}
"}}}
" NERDTree F2 {{{
nnoremap <F2> :NERDTreeMirror<CR> 
nnoremap <F2> :NERDTreeToggle<CR>
"}}}
" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END
execute "set fileformat=unix"
"}}}
"进行版权声明的设置,添加或更新头 F3 {{{
nnoremap <F3> :call TitleDet()<cr>
"}}}
"use ,in to generate instance{{{
nnoremap <leader>in :call Autoinstance()<cr>
"}}}
"use ,tb to generate testbench_file{{{
nnoremap <leader>tb :call Autotb()<cr>
"}}}

"----------------- FUNCTION -------------------
"Grep word attention only for linux{{{
if has('win32') || has ('win64')
else
    nnoremap <leader>g :set operatorfunc=<SID>GrepOperator<cr>g@
    vnoremap <leader>g :<c-u>call <SID>GrepOperator(visualmode())<cr>
endif
function! s:GrepOperator(type)
    let saved_unnamed_register = @@
    if a:type ==# 'v'
        normal! `<v`>y
    elseif a:type ==# 'char'
        normal! `[v`]y
    else
        return
    endif
    silent execute "grep! -R " . shellescape(@@) . " ."
    copen
    let @@ = saved_unnamed_register
endfunction
"}}}
"""ale for syntax check {{{
"确认你的linter那些是可用的
let b:ale_linters = ['iverilog']
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'
" Set this. Airline will handle the rest.
let g:airline#extensions#ale#enabled = 1
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))

    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors

    return l:counts.total == 0 ? 'OK' : printf(
    \   '%dW %dE',
    \   all_non_errors,
    \   all_errors
    \)
endfunction

set statusline=%{LinterStatus()}
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
" Write this in your vimrc file
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
"""

