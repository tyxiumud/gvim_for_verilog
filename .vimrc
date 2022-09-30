"---------User define set option-----------
"设置mapleader
:let mapleader = ","

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
set relativenumber "显示相对行号
set cursorcolumn "add cursor in column
set cursorline "add cursor in line 
"set guifont=Monospace\ 16 "gui style for linux
set guifont=Courier_new:h16"for windows
set lines=45 columns=138 "其中lines是窗口显示的行数，columns是窗口显示的列数
set expandtab "expandtab 选项把插入的 tab 字符替换成特定数目的空格。具体空格数目跟 tabstop 选项值有关
set tabstop=4 "tab键相当于4个空格键
set shiftwidth=4 "换行自动变为空格
set autoindent "设置自动缩进  自动缩进，当你第一行敲 tab + 文字 回车后 下一行自动给你加个 tab 
set backspace=2 "使用 backspace
set laststatus=2 "启动显示状态行
set encoding=utf-8 "文件编码
set completeopt=menu,preview,longest "自动补全相关的设置


"-------------------MAP OPTION-------------------
"imap
inoremap jk <ESC> g,"在编辑模式下使用jk替代ESC进入命令模式
"使用CTRL L 代替 CTRL X ＋CTRL L 就是整个句子的补全
inoremap <C-L> <C-X><C-L> 

"nmap

"进行版权声明的设置
"添加或更新头
nnoremap <F3> :call TitleDet()<cr>

"对齐例化后的信息,保证你的信号名称小于55个字符，否则会有错误。将数字55修改的稍微大一些
nnoremap <F6> 0i			<ESC>0dwi    <ESC>^f(i	                                                                    					<ESC>^55ldwa			<ESC>bldwf)i	            		         	                         <ESC>^f(55ldwj
"设置快速编辑.vimrc的快捷键
:nnoremap <leader>ev :vsplit $MYVIMRC<cr>
:nnoremap <leader>sv :source $MYVIMRC<cr>
"功能描述 输入<leader>ii <leader>oo 自动生成输入输入模板，需要输入端口信号位宽，信号名称
nnoremap <leader>ii <ESC>0i        <ESC>0dwi    input   wire						                                					<ESC>020li[<ESC>ldwwi						<ESC>028li-1: 0]<ESC>wi															<ESC>044ldwea																												<ESC>089li,<ESC>0f,a								<ESC>bldwj
nnoremap <leader>oo <ESC>0i        <ESC>0dwi    output  wire											<ESC>020li[<ESC>ldwwi						<ESC>028li-1: 0]<ESC>wi															<ESC>044ldwea																												<ESC>089li,<ESC>0f,a								<ESC>bldwj
"自动生成注释的模板
inoremap zu //*************************************************\<CR>//define parameter and intennal singles<CR>//*************************************************/<CR><CR>//*************************************************\<CR>//main code<CR>//*************************************************/<CR>
"切换buffer以及删除buffer
nnoremap <C-j> :bn<CR>
nnoremap <C-k> :bp<CR>
nnoremap <C-x> :bwipe<CR>

"----------------- PLUGIN -------------------
"air-line
let g:airline#extensions#tabline#enabled=1 "顶部tab显示"
let g:airline#extensions#tabline#buffer_idx_mode = 1 "显示buffer number"
let g:airline#extensions#whitespace#enabled = 0 "清楚traling的警告"

let g:airline_left_sep = '►'
let g:airline_left_alt_sep = '>'
let g:airline_right_sep = '◄'
let g:airline_right_alt_sep = '<'


" NERDTree
nnoremap <F2> :NERDTreeMirror<CR> 
nnoremap <F2> :NERDTreeToggle<CR>

"----------------- FUNCTION -------------------
function AddTitle()
    call append(0,"/*=============================================================================")
    call append(1,"#")
    call append(2,"# Author: mengguodong Email: 823300630@qq.com")
    call append(3,"#")
    call append(4,"# Personal Website: guodongblog.com")
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
