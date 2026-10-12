set nocompatible
set nomore

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:plugin_root = s:root . '/pack/user_define/start/user_define'
execute 'set runtimepath^=' . fnameescape(s:plugin_root)

let s:errors = []

function! s:AssertEqual(expected, actual, message) abort
    if string(a:expected) !=# string(a:actual)
        call add(s:errors, a:message . ': expected '
        \   . string(a:expected) . ', got ' . string(a:actual))
    endif
endfunction

let s:sample = [
\ 'module data_pipe #(',
\ '    parameter integer DATA_WIDTH = 8,',
\ '    parameter [3:0] RESET_VALUE = 4''b0010,',
\ '    parameter DEPTH = DATA_WIDTH * 2',
\ ')(',
\ '    input  wire                     clk,',
\ '    input  wire                     rst_n,',
\ '    input  wire [DATA_WIDTH-1:0]    data_a, data_b,',
\ '    output reg signed [7:0]         result,',
\ '    inout  wire [15:0]              bus',
\ ');',
\ 'endmodule',
\]

let s:module = verilog_tools#ParseLines(s:sample)
call s:AssertEqual('data_pipe', s:module.name, 'module name')
call s:AssertEqual(
\ ['DATA_WIDTH', 'RESET_VALUE', 'DEPTH'],
\ map(copy(s:module.parameters), 'v:val.name'),
\ 'parameter names'
\)
call s:AssertEqual(
\ ['clk', 'rst_n', 'data_a', 'data_b', 'result', 'bus'],
\ map(copy(s:module.ports), 'v:val.name'),
\ 'port names and source order'
\)
call s:AssertEqual(
\ ['[DATA_WIDTH-1:0]'],
\ s:module.ports[2].packed_dimensions,
\ 'packed width on first shared declaration'
\)
call s:AssertEqual(
\ ['[DATA_WIDTH-1:0]'],
\ s:module.ports[3].packed_dimensions,
\ 'packed width inherited by second port'
\)

let s:commented = [
\ '/* file header */',
\ 'module commented #(',
\ '    parameter URL = "http://example",',
\ '    parameter VALUE = choose(1, 2)',
\ ')(',
\ '    input wire a, /* keep b */ b,',
\ '    output wire [3:0] y // trailing comment',
\ '); // module header end',
\ 'endmodule',
\]
let s:commented_module = verilog_tools#ParseLines(s:commented)
call s:AssertEqual(
\ ['URL', 'VALUE'],
\ map(copy(s:commented_module.parameters), 'v:val.name'),
\ 'comments and commas inside expressions'
\)
call s:AssertEqual(
\ ['a', 'b', 'y'],
\ map(copy(s:commented_module.ports), 'v:val.name'),
\ 'comments inside port list'
\)

let s:empty_module = verilog_tools#ParseLines(['module empty();', 'endmodule'])
call s:AssertEqual([], s:empty_module.ports, 'module without ports')

let s:caught_non_ansi = 0
try
    call verilog_tools#ParseLines([
    \ 'module legacy(a, b);',
    \ 'input a;',
    \ 'output b;',
    \ 'endmodule',
    \])
catch /^verilog-tools:/
    let s:caught_non_ansi = 1
endtry
call s:AssertEqual(1, s:caught_non_ansi, 'non-ANSI declaration error')

if !empty(s:errors)
    for s:error in s:errors
        echomsg s:error
    endfor
    cquit
endif

qa!
