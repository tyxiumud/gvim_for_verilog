" Expand compact "width signal" rows into aligned Verilog port declarations.
" Keep this file compatible with Vim 7.4: do not use Vim 8-only functions.

if exists('g:autoloaded_verilog_port')
    finish
endif
let g:autoloaded_verilog_port = 1

" Values are one-based display columns, not counts of literal spaces.
let s:default_columns = {
\   'direction': 5,
\   'type': 13,
\   'width': 21,
\   'width_suffix': 29,
\   'name': 45,
\   'comma': 90,
\}

function! s:ShowError(message) abort
    echohl ErrorMsg
    echomsg 'verilog-port: ' . a:message
    echohl None
endfunction

function! s:GetColumns() abort
    let l:columns = copy(s:default_columns)

    if !exists('g:verilog_port_columns')
        return l:columns
    endif

    if type(g:verilog_port_columns) != type({})
        call s:ShowError('g:verilog_port_columns must be a Dictionary')
        return {}
    endif

    for l:key in keys(g:verilog_port_columns)
        if !has_key(s:default_columns, l:key)
            call s:ShowError('unknown column name: ' . l:key)
            return {}
        endif

        let l:value = g:verilog_port_columns[l:key]
        if type(l:value) != type(0) || l:value < 1
            call s:ShowError(
            \   'g:verilog_port_columns.' . l:key
            \   . ' must be a positive Number'
            \)
            return {}
        endif

        let l:columns[l:key] = l:value
    endfor

    return l:columns
endfunction

" Append text at a target display column. If previous content is too long,
" keep one separating space and move the remaining fields to the right.
function! s:AppendAtColumn(line, text, target_column) abort
    let l:next_column = strdisplaywidth(a:line) + 1
    let l:padding = a:target_column - l:next_column

    if empty(a:line)
        let l:padding = max([0, l:padding])
    else
        let l:padding = max([1, l:padding])
    endif

    return a:line . repeat(' ', l:padding) . a:text
endfunction

function! verilog_port#Format(direction, width, name) abort
    let l:direction = tolower(a:direction)
    if index(['input', 'output', 'inout'], l:direction) < 0
        call s:ShowError('direction must be input, output, or inout')
        return ''
    endif

    if empty(a:width) || empty(a:name)
        call s:ShowError('width and signal name must not be empty')
        return ''
    endif

    let l:columns = s:GetColumns()
    if empty(l:columns)
        return ''
    endif

    let l:line = ''
    let l:line = s:AppendAtColumn(
    \   l:line, l:direction, l:columns.direction
    \)
    let l:line = s:AppendAtColumn(l:line, 'wire', l:columns.type)

    " Width 1 is a scalar port, so omit the [W-1: 0] range entirely.
    if a:width !=# '1'
        let l:line = s:AppendAtColumn(l:line, '[' . a:width, l:columns.width)
        let l:line = s:AppendAtColumn(
        \   l:line, '-1: 0]', l:columns.width_suffix
        \)
    endif

    let l:line = s:AppendAtColumn(l:line, a:name, l:columns.name)
    let l:line = s:AppendAtColumn(l:line, ',', l:columns.comma)
    return l:line
endfunction

function! verilog_port#Expand(direction) abort
    let l:fields = split(getline('.'))
    if len(l:fields) != 2
        call s:ShowError('expected one line in the form: width signal_name')
        return 0
    endif

    let l:formatted = verilog_port#Format(
    \   a:direction, l:fields[0], l:fields[1]
    \)
    if empty(l:formatted)
        return 0
    endif

    let l:current_line = line('.')
    if setline(l:current_line, l:formatted) != 0
        call s:ShowError('could not replace the current line')
        return 0
    endif

    " Preserve the old mappings' workflow: continue on the following row.
    call cursor(min([l:current_line + 1, line('$')]), 1)
    return 1
endfunction
