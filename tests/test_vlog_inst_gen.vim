set nocompatible
set nomore

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:plugin_root = s:root . '/pack/vlog_inst_gen/start/vlog_inst_gen'
let s:tools_root = s:root . '/pack/user_define/start/user_define'
execute 'set runtimepath^=' . fnameescape(s:plugin_root)
execute 'set runtimepath^=' . fnameescape(s:tools_root)
execute 'source ' . fnameescape(s:plugin_root . '/plugin/vlog_inst_gen.vim')
let g:vlog_inst_gen_mode = 1

let s:errors = []
function! s:AssertEqual(expected, actual, message) abort
    if string(a:expected) !=# string(a:actual)
        call add(s:errors, a:message . ': expected '
        \   . string(a:expected) . ', got ' . string(a:actual))
    endif
endfunction

function! s:PortLines(instance) abort
    return filter(split(a:instance, "\n"), 'v:val =~# ''^    \.[a-z]''')
endfunction

enew!
call setline(1, [
\ 'module mixed #(',
\ '    parameter DATA_WIDTH = 8',
\ ') (',
\ '    input wire clk,',
\ '    output wire [DATA_WIDTH-1:0] data_o,',
\ '    input wire [DATA_WIDTH-1:0] data_a, data_b,',
\ '    inout wire [3:0] bus',
\ ');',
\ 'endmodule',
\])

call s:AssertEqual(0, g:vlog_inst_gen_connect_width, 'width default')
call s:AssertEqual(0, g:vlog_inst_gen_direction_comment, 'comment default')
call Vlog_Inst_Gen()
let s:plain = s:PortLines(@")
call s:AssertEqual(5, len(s:plain), 'plain port count')
call s:AssertEqual(
\ ['clk', 'data_o', 'data_a', 'data_b', 'bus'],
\ map(copy(s:plain), 'matchstr(v:val, ''\.\zs[a-z_][a-z_]*'')'),
\ 'source port order'
\)
call s:AssertEqual(0, s:plain[1] =~# '\[', 'width disabled')
call s:AssertEqual(0, s:plain[1] =~# '//', 'comment disabled')

let g:vlog_inst_gen_connect_width = 1
let g:vlog_inst_gen_direction_comment = 1
call Vlog_Inst_Gen()
let s:annotated = s:PortLines(@")
call s:AssertEqual(
\ ['clk', 'data_o', 'data_a', 'data_b', 'bus'],
\ map(copy(s:annotated), 'matchstr(v:val, ''\.\zs[a-z_][a-z_]*'')'),
\ 'annotated port order'
\)
call s:AssertEqual(1, s:annotated[0] =~# '), // input$', 'scalar input direction')
call s:AssertEqual(1, s:annotated[1] =~# 'data_o\[DATA_WIDTH-1:0\]', 'output width')
call s:AssertEqual(1, s:annotated[1] =~# '), // output$', 'output direction')
call s:AssertEqual(1, s:annotated[2] =~# 'data_a\[DATA_WIDTH-1:0\]', 'first shared width')
call s:AssertEqual(1, s:annotated[3] =~# 'data_b\[DATA_WIDTH-1:0\]', 'inherited width')
call s:AssertEqual(1, s:annotated[4] =~# 'bus\[3:0\]', 'inout width')
call s:AssertEqual(1, s:annotated[4] =~# ') // inout$', 'last port direction')

let g:vlog_inst_gen_connect_width = 0
call Vlog_Inst_Gen()
let s:comments_only = s:PortLines(@")
call s:AssertEqual(0, s:comments_only[1] =~# '\[', 'comments without width')
call s:AssertEqual(1, s:comments_only[1] =~# '// output$', 'comment remains enabled')

let g:vlog_inst_gen_connect_width = 1
let g:vlog_inst_gen_direction_comment = 0
call Vlog_Inst_Gen()
let s:width_only = s:PortLines(@")
call s:AssertEqual(1, s:width_only[1] =~# 'data_o\[DATA_WIDTH-1:0\]', 'width remains enabled')
call s:AssertEqual(0, s:width_only[1] =~# '//', 'comments disabled independently')

" Width and direction metadata must stay attached to the right module.
enew!
call setline(1, [
\ 'module first(input wire [3:0] a);',
\ 'endmodule',
\ 'module second(output wire [9:0] b);',
\ 'endmodule',
\])
let g:vlog_inst_gen_direction_comment = 1
call Vlog_Inst_Gen()
let s:two_modules = s:PortLines(@")
call s:AssertEqual(2, len(s:two_modules), 'two-module port count')
call s:AssertEqual(1, s:two_modules[0] =~# 'a\[3:0\].*// input$', 'first module metadata')
call s:AssertEqual(1, s:two_modules[1] =~# 'b\[9:0\].*// output$', 'second module metadata')

if !empty(s:errors)
    for s:error in s:errors
        echomsg s:error
    endfor
    cquit
endif

qa!
