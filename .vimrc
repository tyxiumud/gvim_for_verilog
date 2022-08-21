"---------User define set option-----------
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

"禁止相关文件的产生
set noundofile "禁止un~文件
set nobackup "禁止~文件
set noswapfile "禁止swp文件

"辅助编码显示栏目

set nu  "显示行号
set relativenumber "显示相对行号
set cursorcolumn "add cursor in column
set cursorline "add cursor in line 
set guifont=Monospace\ 16 "gui style

set expandtab "expandtab 选项把插入的 tab 字符替换成特定数目的空格。具体空格数目跟 tabstop 选项值有关
set tabstop=4 "tab键相当于4个空格键
set shiftwidth=4 "换行自动变为空格
set autoindent "设置自动缩进  自动缩进，当你第一行敲 tab + 文字 回车后 下一行自动给你加个 tab 
set backspace=2 "使用 backspace

set laststatus=2 "启动显示状态行
set encoding=utf-8 "文件编码
set completeopt=menu,preview,longest "自动补全相关的设置


"-------------------MAP OPTION-------------------
inoremap ( ()<ESC>i
inoremap [ []<ESC>i

"ban up and also keys 
"imap <Up> <Nop>
"imap <Down> <Nop>
"imap <Left> <Nop>
"imap <Right> <Nop>
"nmap <Up> <Nop>
"nmap <Down> <Nop>
"nmap <Left> <Nop>
"nmap <Right> <Nop>

imap jk <ESC> g,"在编辑模式下使用jk替代ESC进入命令模式
imap <C-L> <C-X><C-L> “使用CTRL L 代替 CTRL X ＋CTRL L 就是整个句子的补全
nmap ,l ^
nmap ,r $

map <F2> :NERDTreeMirror<CR> 
map <F2> :NERDTreeToggle<CR>

"进行版权声明的设置
"添加或更新头
map <F3> :call TitleDet()<cr>

"对齐例化后的信息
:map <F6> :s/^ *\./        ./<cr>^f(i                              <ESC>f)i                               <ESC>^24ldw24ldwa  

"----------------- FUNCTION -------------------
function AddTitle()
    call append(0,"/*=============================================================================")
    call append(1,"#")
    call append(2,"# Author: meng  - email@vip.qq.com")
    call append(3,"#")
    call append(4,"# QQ : xxxxxxxxx ")
    call append(5,"#")
    call append(6,"# Last modified: ".strftime("%Y-%m-%d %H:%M"))
    call append(7,"#")
    call append(8,"# Filename: ".expand("%:t"))
    call append(9,"#")
    call append(10,"# Description: ")
    call append(11,"#")
    call append(12,"=============================================================================*/")
    echohl WarningMsg | echo "Successful in adding the copyright." | echohl None
endf
"更新最近修改时间和文件名
function UpdateTitle()
    normal m'
    execute '/# *Last modified:/s@:.*$@\=strftime(":\t%Y-%m-%d %H:%M")@'
    normal ''
    normal mk
    execute '/# *Filename:/s@:.*$@\=":\t\t".expand("%:t")@'
    execute "noh"
    normal 'k
    echohl WarningMsg | echo "Successful in updating the copy right." | echohl None
endfunction
"判断前10行代码里面，是否有Last modified这个单词，
"如果没有的话，代表没有添加过作者信息，需要新添加；
"如果有的话，那么只需要更新即可
function TitleDet()
    let n=1
    "默认为添加
    while n < 10
        let line = getline(n)
        if line =~ '^\#\s*\S*Last\smodified:\S*.*$'
            call UpdateTitle()
            return
        endif
        let n = n + 1
    endwhile
    call AddTitle()
endfunction