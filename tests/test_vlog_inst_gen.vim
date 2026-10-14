set nocompatible
set nomore

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:plugin_root = s:root . '/pack/vlog_inst_gen/start/vlog_inst_gen'
let s:tools_root = s:root . '/pack/user_define/start/user_define'
execute 'set runtimepath^=' . fnameescape(s:plugin_root)
execute 'set runtimepath^=' . fnameescape(s:tools_root)
execute 'source ' . fnameescape(s:plugin_root . '/plugin/vlog_inst_gen.vim')
if g:vlog_inst_gen_mode != 2
    cquit
endif
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
call s:AssertEqual(0, g:vlog_inst_gen_keep_comments, 'source comments default')
call s:AssertEqual(0, exists(':VlogInstMod'), 'old mode command removed')
call s:AssertEqual('', maparg(',im'), 'old mode mapping removed')
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
call s:AssertEqual(1, s:annotated[0] =~# '),//input$', 'scalar input direction')
call s:AssertEqual(1, s:annotated[1] =~# 'data_o\[DATA_WIDTH-1:0\]', 'output width')
call s:AssertEqual(1, s:annotated[1] =~# '),//output$', 'output direction')
call s:AssertEqual(1, s:annotated[2] =~# 'data_a\[DATA_WIDTH-1:0\]', 'first shared width')
call s:AssertEqual(1, s:annotated[3] =~# 'data_b\[DATA_WIDTH-1:0\]', 'inherited width')
call s:AssertEqual(1, s:annotated[4] =~# 'bus\[3:0\]', 'inout width')
call s:AssertEqual(1, s:annotated[4] =~# ')//inout$', 'last port direction')

let g:vlog_inst_gen_connect_width = 0
call Vlog_Inst_Gen()
let s:comments_only = s:PortLines(@")
call s:AssertEqual(0, s:comments_only[1] =~# '\[', 'comments without width')
call s:AssertEqual(1, s:comments_only[1] =~# '//output$', 'comment remains enabled')

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
call s:AssertEqual(1, s:two_modules[0] =~# 'a\[3:0\].*//input$', 'first module metadata')
call s:AssertEqual(1, s:two_modules[1] =~# 'b\[9:0\].*//output$', 'second module metadata')

" Nested parameter expressions, conditional ports, and source comments.
enew!
call setline(1, [
\ 'module configurable #(',
\ '    parameter integer WIDTH = 8,',
\ '    parameter MASK = (1 << WIDTH) - 1,',
\ '    parameter CONFIG = `PACK(1, 2)',
\ ') (',
\ '    //mac to pcs',
\ '    input wire [WIDTH-1:0] pcs,',
\ '`ifdef HAS_CFG',
\ '    //config',
\ '    input wire [3:0] cfg,',
\ '`endif',
\ '    output wire ready',
\ '    //end ports',
\ ');',
\ 'endmodule',
\ ])
let g:vlog_inst_gen_keep_comments = 0
call s:AssertEqual(0, Vlog_Inst_Gen(), 'parameter and macro generation')
call s:AssertEqual(0, @" =~# '//mac to pcs', 'source comment omitted')
call s:AssertEqual(1, @" =~# '\.MASK.*( (1 << WIDTH) - 1', 'nested parameter value')
call s:AssertEqual(1, @" =~# '\.CONFIG.*( `PACK(1, 2)', 'macro parameter with nested comma')
call s:AssertEqual(1, @" =~# 'pcs\[WIDTH-1:0\]', 'width before conditional')
call s:AssertEqual(1, @" =~# 'cfg\[3:0\]', 'width inside conditional')
let g:vlog_inst_gen_keep_comments = 1
call s:AssertEqual(0, Vlog_Inst_Gen(), 'comment preserving generation')
call s:AssertEqual(1, @" =~# '//mac to pcs', 'source comment retained')
call s:AssertEqual(1, @" =~# '//config', 'conditional comment retained')
call s:AssertEqual(1, @" =~# '//end ports', 'trailing comment retained')
call s:AssertEqual(1, @" =~# 'ready.*)//output\n//end ports', 'trailing comment leaves final port valid')

enew!
call setline(1, [
\ 'module branches (',
\ '`ifdef USE_A',
\ '    input wire [7:0] a',
\ '`else',
\ '    input wire [15:0] b',
\ '`endif',
\ ');',
\ 'endmodule',
\ ])
let g:vlog_inst_gen_keep_comments = 0
call s:AssertEqual(0, Vlog_Inst_Gen(), 'conditional branch generation')
call s:AssertEqual(1, @" =~# 'a\[7:0\]', 'first branch width fallback')
call s:AssertEqual(1, @" =~# 'b\[15:0\]', 'second branch width fallback')

enew!
call setline(1, [
\ 'module packed(input wire [3:0][7:0] matrix);',
\ 'endmodule',
\ ])
call s:AssertEqual(0, Vlog_Inst_Gen(), 'multidimensional width generation')
call s:AssertEqual(1, @" =~# 'matrix\[3:0\]\[7:0\]', 'parsed packed dimensions preserved')

" Parameter defaults must be copied from the source, not the stripped header.
enew!
call setline(1, [
\ 'module values #(',
\ '    parameter SEL = BUS[3:0],',
\ '    parameter LABEL = "reg wire"',
\ ') (input wire clk);',
\ 'endmodule',
\ ])
call s:AssertEqual(0, Vlog_Inst_Gen(), 'parameter value generation')
call s:AssertEqual(1, @" =~# 'BUS\[3:0\]', 'parameter bit select preserved')
call s:AssertEqual(1, @" =~# '"reg wire"', 'parameter string preserved')

" Mode 2 should refresh one preview buffer, not append another copy.
let g:vlog_inst_gen_mode = 2
call s:AssertEqual(0, Vlog_Inst_Gen(), 'first preview generation')
let s:first_preview = getline(1, '$')
let s:window_count = winnr('$')
wincmd p
call s:AssertEqual(0, Vlog_Inst_Gen(), 'second preview generation')
call s:AssertEqual(s:first_preview, getline(1, '$'), 'preview content replaced')
call s:AssertEqual(s:window_count, winnr('$'), 'preview window reused')

" Preserve conditional branches in both parameter and port lists.
let g:vlog_inst_gen_mode = 1
enew!
call setline(1, [
\ '`define PICK(A,B) ((A)+(B))',
\ 'module conditional #(',
\ '`ifdef USE_FAST',
\ '    parameter int WIDTH = `PICK(4, 4),',
\ '`elsif USE_WIDE',
\ '    parameter int WIDTH = 16,',
\ '`else',
\ '    parameter int WIDTH = 8,',
\ '`endif',
\ '    parameter logic [3:0] RESET = 4''h0,',
\ '    parameter string LABEL = "reg wire"',
\ ') (',
\ '    input wire clk,',
\ '`ifndef NO_DATA',
\ '    input wire [WIDTH-1:0] data,',
\ '`endif',
\ '    output wire done',
\ ');',
\ 'endmodule',
\ ])
call s:AssertEqual(0, Vlog_Inst_Gen(), 'conditional parameter and port generation')
call s:AssertEqual(1, @" =~# '`ifdef USE_FAST\n', 'parameter ifdef retained')
call s:AssertEqual(1, @" =~# '`elsif USE_WIDE\n', 'parameter elsif retained')
call s:AssertEqual(1, @" =~# '`ifndef NO_DATA\n', 'port ifndef retained')
call s:AssertEqual(1, @" =~# '`PICK(4, 4)', 'macro arguments retained')
call s:AssertEqual(1, @" =~# '\.RESET.*4''h0', 'typed parameter retained')
call s:AssertEqual(1, @" =~# '"reg wire"', 'conditional parameter string preserved')
call s:AssertEqual(1, @" =~# 'data\[WIDTH-1:0\]', 'conditional width retained')

enew!
call setline(1, [
\ 'module no_trailing_comma #(',
\ '`ifdef PICK_SMALL',
\ '    parameter int WIDTH = BASE[3:0]',
\ '`else',
\ '    parameter int WIDTH = 16',
\ '`endif',
\ ') (',
\ '`ifdef PICK_SMALL',
\ '    input wire [WIDTH-1:0] small',
\ '`elsif PICK_WIDE',
\ '    input wire [3:0][WIDTH-1:0] medium',
\ '`else',
\ '    input wire [WIDTH-1:0] wide',
\ '`endif',
\ ');',
\ 'endmodule',
\ ])
call s:AssertEqual(0, Vlog_Inst_Gen(), 'branch-final declarations without comma')
call s:AssertEqual(1, @" =~# '\.WIDTH.*( BASE\[3:0\].*)\n`else', 'first branch keeps bit select and no comma')
call s:AssertEqual(1, @" =~# '\.WIDTH.*( 16.*)\n`endif', 'second branch has no comma')
call s:AssertEqual(1, @" =~# '`ifdef PICK_SMALL\n', 'first port directive retained')
call s:AssertEqual(1, @" =~# '\.small.*)//input\n`elsif PICK_WIDE', 'first port branch has no comma')
call s:AssertEqual(1, @" =~# '\.medium.*)//input\n`else', 'elsif port branch has no comma')
call s:AssertEqual(1, @" =~# 'medium\[3:0\]\[WIDTH-1:0\]', 'conditional packed dimensions preserved')
call s:AssertEqual(1, @" =~# '\.wide.*)//input\n`endif', 'second port branch has no comma')

" A macro standing in for declarations cannot be resolved without preprocessing.
let s:previous_instance = @"
enew!
call setline(1, [
\ 'module needs_preprocess (`PORT_DECLARATIONS);',
\ 'endmodule',
\ ])
call s:AssertEqual(3, Vlog_Inst_Gen(), 'macro-expanded port declaration rejected')
call s:AssertEqual(s:previous_instance, @", 'failed generation keeps clipboard')
enew!
call setline(1, [
\ 'module needs_param_preprocess #(`PARAM_DECLARATIONS) (input wire clk);',
\ 'endmodule',
\ ])
call s:AssertEqual(3, Vlog_Inst_Gen(), 'macro-expanded parameter declaration rejected')
call s:AssertEqual(s:previous_instance, @", 'parameter failure keeps clipboard')

if !empty(s:errors)
    for s:error in s:errors
        echomsg s:error
    endfor
    cquit
endif

qa!
