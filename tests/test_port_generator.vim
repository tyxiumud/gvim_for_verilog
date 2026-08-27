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

function! s:ColumnOf(text, token) abort
    let l:index = stridx(a:text, a:token)
    return l:index < 0 ? 0 : strdisplaywidth(strpart(a:text, 0, l:index)) + 1
endfunction

unlet! g:verilog_port_columns
let s:input = verilog_port#Format('input', '2', 'sig_two')
call s:AssertEqual(5, s:ColumnOf(s:input, 'input'), 'input column')
call s:AssertEqual(13, s:ColumnOf(s:input, 'wire'), 'type column')
call s:AssertEqual(21, s:ColumnOf(s:input, '[2'), 'width column')
call s:AssertEqual(29, s:ColumnOf(s:input, '-1: 0]'), 'width suffix column')
call s:AssertEqual(45, s:ColumnOf(s:input, 'sig_two'), 'signal column')
call s:AssertEqual(90, s:ColumnOf(s:input, ','), 'comma column')

let s:output = verilog_port#Format('output', '13', 'sig_thirteen')
call s:AssertEqual(5, s:ColumnOf(s:output, 'output'), 'output column')
call s:AssertEqual(13, s:ColumnOf(s:output, 'wire'), 'output type column')
call s:AssertEqual(29, s:ColumnOf(s:output, '-1: 0]'), 'two-digit width alignment')
call s:AssertEqual(
\   '[13     -1: 0]',
\   matchstr(s:output, '\[[^]]*\]'),
\   'two-digit width text'
\)

let s:scalar = verilog_port#Format('input', '1', 'clk')
call s:AssertEqual('', matchstr(s:scalar, '\[[^]]*\]'), 'scalar width omits range')
call s:AssertEqual(5, s:ColumnOf(s:scalar, 'input'), 'scalar input column')
call s:AssertEqual(13, s:ColumnOf(s:scalar, 'wire'), 'scalar type column')
call s:AssertEqual(45, s:ColumnOf(s:scalar, 'clk'), 'scalar signal column')
call s:AssertEqual(90, s:ColumnOf(s:scalar, ','), 'scalar comma column')

let g:verilog_port_columns = {
\   'direction': 1,
\   'type': 10,
\   'width': 20,
\   'width_suffix': 35,
\   'name': 50,
\   'comma': 75,
\}
let s:custom = verilog_port#Format('input', 'WIDTH', 'custom_data')
call s:AssertEqual(1, s:ColumnOf(s:custom, 'input'), 'custom direction column')
call s:AssertEqual(10, s:ColumnOf(s:custom, 'wire'), 'custom type column')
call s:AssertEqual(20, s:ColumnOf(s:custom, '[WIDTH'), 'custom width column')
call s:AssertEqual(35, s:ColumnOf(s:custom, '-1: 0]'), 'custom suffix column')
call s:AssertEqual(50, s:ColumnOf(s:custom, 'custom_data'), 'custom name column')
call s:AssertEqual(75, s:ColumnOf(s:custom, ','), 'custom comma column')

unlet! g:verilog_port_columns
let s:overflow = verilog_port#Format(
\   'input', 'EXTRA_LONG_PARAMETER_WIDTH', 'long_data_name'
\)
call s:AssertEqual(
\   '[EXTRA_LONG_PARAMETER_WIDTH -1: 0]',
\   matchstr(s:overflow, '\[[^]]*\]'),
\   'long width shifts suffix without overwriting it'
\)
if s:ColumnOf(s:overflow, 'long_data_name')
\   <= s:ColumnOf(s:overflow, '-1: 0]')
    call add(s:errors, 'long width must shift the signal name to the right')
endif

enew!
call setline(1, ['13 data_i', '2 data_o', 'invalid extra input fields'])
call cursor(1, 1)
call s:AssertEqual(1, verilog_port#Expand('input'), 'expand input result')
call s:AssertEqual(45, s:ColumnOf(getline(1), 'data_i'), 'expanded input')
call s:AssertEqual(2, line('.'), 'successful expansion moves to next line')
call s:AssertEqual(1, verilog_port#Expand('output'), 'expand output result')
call s:AssertEqual(45, s:ColumnOf(getline(2), 'data_o'), 'expanded output')
call s:AssertEqual(3, line('.'), 'second expansion moves to next line')
let s:invalid_before = getline(3)
silent! let s:invalid_result = verilog_port#Expand('input')
call s:AssertEqual(0, s:invalid_result, 'invalid input result')
call s:AssertEqual(s:invalid_before, getline(3), 'invalid input remains unchanged')

if !empty(s:errors)
    for s:error in s:errors
        echomsg s:error
    endfor
    cquit
endif

qa!
