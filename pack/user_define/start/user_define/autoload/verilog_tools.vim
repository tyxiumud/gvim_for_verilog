" Shared Verilog module-header parser and generators.
" Keep this file compatible with Vim 7.4: do not use Vim 8-only functions.

if exists('g:autoloaded_verilog_tools')
    finish
endif
let g:autoloaded_verilog_tools = 1

if !exists('g:verilog_gen_connect_width')
    let g:verilog_gen_connect_width = 1
endif

function! s:Throw(message) abort
    throw 'verilog-tools: ' . a:message
endfunction

function! s:Trim(text) abort
    let l:text = substitute(a:text, '^\_s\+', '', '')
    return substitute(l:text, '\_s\+$', '', '')
endfunction

function! s:CharAt(text, index) abort
    return strpart(a:text, a:index, 1)
endfunction

" Remove // and /* */ comments while preserving strings and newlines.
function! s:StripComments(text) abort
    let l:result = ''
    let l:index = 0
    let l:length = strlen(a:text)
    let l:in_block_comment = 0
    let l:in_string = 0
    let l:escaped = 0

    while l:index < l:length
        let l:char = s:CharAt(a:text, l:index)
        let l:next = l:index + 1 < l:length
        \   ? s:CharAt(a:text, l:index + 1)
        \   : ''

        if l:in_block_comment
            if l:char ==# '*' && l:next ==# '/'
                let l:result .= '  '
                let l:index += 2
                let l:in_block_comment = 0
            else
                let l:result .= l:char ==# "\n" ? "\n" : ' '
                let l:index += 1
            endif
            continue
        endif

        if l:in_string
            let l:result .= l:char
            if l:escaped
                let l:escaped = 0
            elseif l:char ==# '\\'
                let l:escaped = 1
            elseif l:char ==# '"'
                let l:in_string = 0
            endif
            let l:index += 1
            continue
        endif

        if l:char ==# '"'
            let l:in_string = 1
            let l:result .= l:char
            let l:index += 1
        elseif l:char ==# '/' && l:next ==# '*'
            let l:result .= '  '
            let l:index += 2
            let l:in_block_comment = 1
        elseif l:char ==# '/' && l:next ==# '/'
            while l:index < l:length && s:CharAt(a:text, l:index) !=# "\n"
                let l:result .= ' '
                let l:index += 1
            endwhile
        else
            let l:result .= l:char
            let l:index += 1
        endif
    endwhile

    if l:in_block_comment
        call s:Throw('unterminated block comment in module header')
    endif

    return l:result
endfunction

function! s:SkipWhitespace(text, start) abort
    let l:index = a:start
    while l:index < strlen(a:text) && s:CharAt(a:text, l:index) =~# '\_s'
        let l:index += 1
    endwhile
    return l:index
endfunction

function! s:FindMatching(text, open_index, open_char, close_char) abort
    let l:index = a:open_index
    let l:depth = 0
    let l:in_string = 0
    let l:escaped = 0

    while l:index < strlen(a:text)
        let l:char = s:CharAt(a:text, l:index)

        if l:in_string
            if l:escaped
                let l:escaped = 0
            elseif l:char ==# '\\'
                let l:escaped = 1
            elseif l:char ==# '"'
                let l:in_string = 0
            endif
        elseif l:char ==# '"'
            let l:in_string = 1
        elseif l:char ==# a:open_char
            let l:depth += 1
        elseif l:char ==# a:close_char
            let l:depth -= 1
            if l:depth == 0
                return l:index
            endif
        endif

        let l:index += 1
    endwhile

    call s:Throw('unmatched ' . a:open_char . ' in module header')
endfunction

function! s:FindTopLevelChar(text, target) abort
    let l:paren = 0
    let l:bracket = 0
    let l:brace = 0
    let l:in_string = 0
    let l:escaped = 0
    let l:index = 0

    while l:index < strlen(a:text)
        let l:char = s:CharAt(a:text, l:index)

        if l:in_string
            if l:escaped
                let l:escaped = 0
            elseif l:char ==# '\\'
                let l:escaped = 1
            elseif l:char ==# '"'
                let l:in_string = 0
            endif
        elseif l:char ==# '"'
            let l:in_string = 1
        elseif l:char ==# '('
            let l:paren += 1
        elseif l:char ==# ')'
            let l:paren -= 1
        elseif l:char ==# '['
            let l:bracket += 1
        elseif l:char ==# ']'
            let l:bracket -= 1
        elseif l:char ==# '{'
            let l:brace += 1
        elseif l:char ==# '}'
            let l:brace -= 1
        elseif l:char ==# a:target
        \ && l:paren == 0 && l:bracket == 0 && l:brace == 0
            return l:index
        endif

        let l:index += 1
    endwhile

    return -1
endfunction

function! s:SplitTopLevel(text, delimiter) abort
    let l:items = []
    let l:start = 0
    let l:index = 0
    let l:paren = 0
    let l:bracket = 0
    let l:brace = 0
    let l:in_string = 0
    let l:escaped = 0

    while l:index < strlen(a:text)
        let l:char = s:CharAt(a:text, l:index)

        if l:in_string
            if l:escaped
                let l:escaped = 0
            elseif l:char ==# '\\'
                let l:escaped = 1
            elseif l:char ==# '"'
                let l:in_string = 0
            endif
        elseif l:char ==# '"'
            let l:in_string = 1
        elseif l:char ==# '('
            let l:paren += 1
        elseif l:char ==# ')'
            let l:paren -= 1
        elseif l:char ==# '['
            let l:bracket += 1
        elseif l:char ==# ']'
            let l:bracket -= 1
        elseif l:char ==# '{'
            let l:brace += 1
        elseif l:char ==# '}'
            let l:brace -= 1
        elseif l:char ==# a:delimiter
        \ && l:paren == 0 && l:bracket == 0 && l:brace == 0
            call add(l:items, s:Trim(strpart(a:text, l:start, l:index - l:start)))
            let l:start = l:index + 1
        endif

        let l:index += 1
    endwhile

    call add(l:items, s:Trim(strpart(a:text, l:start)))
    return l:items
endfunction

function! s:StripTrailingDimensions(text) abort
    let l:remaining = s:Trim(a:text)
    let l:dimensions = []

    while !empty(l:remaining) && s:CharAt(l:remaining, strlen(l:remaining) - 1) ==# ']'
        let l:index = strlen(l:remaining) - 1
        let l:depth = 0
        let l:start = -1

        while l:index >= 0
            let l:char = s:CharAt(l:remaining, l:index)
            if l:char ==# ']'
                let l:depth += 1
            elseif l:char ==# '['
                let l:depth -= 1
                if l:depth == 0
                    let l:start = l:index
                    break
                endif
            endif
            let l:index -= 1
        endwhile

        if l:start < 0
            call s:Throw('unmatched array dimension in declaration: ' . a:text)
        endif

        let l:dimension = strpart(l:remaining, l:start)
        call insert(l:dimensions, substitute(l:dimension, '\_s\+', '', 'g'), 0)
        let l:remaining = s:Trim(strpart(l:remaining, 0, l:start))
    endwhile

    return {'text': l:remaining, 'dimensions': l:dimensions}
endfunction

function! s:ExtractDimensions(text) abort
    let l:dimensions = []
    let l:index = 0

    while l:index < strlen(a:text)
        if s:CharAt(a:text, l:index) ==# '['
            let l:end = s:FindMatching(a:text, l:index, '[', ']')
            let l:dimension = strpart(a:text, l:index, l:end - l:index + 1)
            call add(l:dimensions, substitute(l:dimension, '\_s\+', '', 'g'))
            let l:index = l:end + 1
        else
            let l:index += 1
        endif
    endwhile

    return l:dimensions
endfunction

function! s:ParseDeclarator(text) abort
    let l:equal = s:FindTopLevelChar(a:text, '=')
    let l:left = l:equal >= 0 ? strpart(a:text, 0, l:equal) : a:text
    let l:default = l:equal >= 0 ? s:Trim(strpart(a:text, l:equal + 1)) : ''
    let l:trailing = s:StripTrailingDimensions(l:left)
    let l:name = matchstr(l:trailing.text, '[A-Za-z_][A-Za-z0-9_$]*$')

    if empty(l:name)
        call s:Throw('cannot find a name in declaration: ' . s:Trim(a:text))
    endif

    let l:name_start = strlen(l:trailing.text) - strlen(l:name)
    let l:prefix = s:Trim(strpart(l:trailing.text, 0, l:name_start))

    return {
    \   'name': l:name,
    \   'prefix': l:prefix,
    \   'default': l:default,
    \   'unpacked_dimensions': l:trailing.dimensions,
    \}
endfunction

function! s:ParseParameters(text) abort
    let l:parameters = []
    let l:context_prefix = ''

    for l:raw_item in s:SplitTopLevel(a:text, ',')
        let l:item = s:Trim(l:raw_item)
        if empty(l:item)
            continue
        endif

        let l:has_keyword = l:item =~# '^\_s*\(parameter\|localparam\)\>'
        let l:item = substitute(l:item, '^\_s*\(parameter\|localparam\)\>\_s*', '', '')
        let l:declarator = s:ParseDeclarator(l:item)

        if l:has_keyword
            let l:context_prefix = l:declarator.prefix
        endif

        let l:prefix = empty(l:declarator.prefix)
        \   ? l:context_prefix
        \   : l:declarator.prefix

        call add(l:parameters, {
        \   'name': l:declarator.name,
        \   'default': l:declarator.default,
        \   'declaration_prefix': l:prefix,
        \})
    endfor

    return l:parameters
endfunction

function! s:ParsePorts(text) abort
    let l:ports = []
    let l:context = {}

    for l:raw_item in s:SplitTopLevel(a:text, ',')
        let l:item = s:Trim(l:raw_item)
        if empty(l:item)
            continue
        endif

        let l:direction_match = matchlist(
        \   l:item,
        \   '^\_s*\(input\|output\|inout\)\>\_s*\(\_.*\)$'
        \)

        if !empty(l:direction_match)
            let l:direction = l:direction_match[1]
            let l:declarator = s:ParseDeclarator(l:direction_match[2])
            let l:context = {
            \   'direction': l:direction,
            \   'declaration_prefix': l:declarator.prefix,
            \   'packed_dimensions': s:ExtractDimensions(l:declarator.prefix),
            \   'signed': l:declarator.prefix =~# '\<signed\>',
            \}
        else
            if empty(l:context)
                call s:Throw(
                \   'non-ANSI or unsupported port declaration: ' . l:item
                \)
            endif
            let l:declarator = s:ParseDeclarator(l:item)
            if !empty(l:declarator.prefix)
                call s:Throw('unsupported continued port declaration: ' . l:item)
            endif
        endif

        call add(l:ports, {
        \   'name': l:declarator.name,
        \   'direction': l:context.direction,
        \   'declaration_prefix': l:context.declaration_prefix,
        \   'packed_dimensions': copy(l:context.packed_dimensions),
        \   'unpacked_dimensions': copy(l:declarator.unpacked_dimensions),
        \   'signed': l:context.signed,
        \})
    endfor

    return l:ports
endfunction

function! verilog_tools#ParseLines(lines) abort
    let l:text = join(a:lines, "\n")
    let l:text = s:StripComments(l:text)
    let l:module_pattern = '\C\%(^\|\n\)\s*module\s\+'
    \   . '\%(\%(automatic\|static\)\s\+\)\?'
    \   . '\([A-Za-z_][A-Za-z0-9_$]*\)'
    let l:module_match = matchlist(l:text, l:module_pattern)

    if empty(l:module_match)
        call s:Throw('cannot find an ANSI-style module declaration')
    endif

    let l:module_name = l:module_match[1]
    let l:position = matchend(l:text, l:module_pattern)
    let l:position = s:SkipWhitespace(l:text, l:position)
    let l:parameter_text = ''

    if s:CharAt(l:text, l:position) ==# '#'
        let l:position = s:SkipWhitespace(l:text, l:position + 1)
        if s:CharAt(l:text, l:position) !=# '('
            call s:Throw('expected ( after # in module ' . l:module_name)
        endif
        let l:parameter_end = s:FindMatching(l:text, l:position, '(', ')')
        let l:parameter_text = strpart(
        \   l:text,
        \   l:position + 1,
        \   l:parameter_end - l:position - 1
        \)
        let l:position = s:SkipWhitespace(l:text, l:parameter_end + 1)
    endif

    if s:CharAt(l:text, l:position) !=# '('
        call s:Throw(
        \   'module ' . l:module_name
        \   . ' does not use an ANSI-style port list'
        \)
    endif

    let l:port_end = s:FindMatching(l:text, l:position, '(', ')')
    let l:port_text = strpart(
    \   l:text,
    \   l:position + 1,
    \   l:port_end - l:position - 1
    \)
    let l:after_header = s:SkipWhitespace(l:text, l:port_end + 1)

    if s:CharAt(l:text, l:after_header) !=# ';'
        call s:Throw('expected ; after the port list of module ' . l:module_name)
    endif

    return {
    \   'name': l:module_name,
    \   'parameters': empty(s:Trim(l:parameter_text))
    \       ? []
    \       : s:ParseParameters(l:parameter_text),
    \   'ports': empty(s:Trim(l:port_text))
    \       ? []
    \       : s:ParsePorts(l:port_text),
    \}
endfunction

function! verilog_tools#ParseCurrentBuffer() abort
    return verilog_tools#ParseLines(getline(1, '$'))
endfunction

function! s:MaxNameLength(items) abort
    let l:max_length = 0
    for l:item in a:items
        let l:max_length = max([l:max_length, strlen(l:item.name)])
    endfor
    return l:max_length
endfunction

function! verilog_tools#BuildInstance(module) abort
    let l:lines = []
    let l:name = a:module.name
    let l:instance_name = 'U_' . toupper(l:name) . '_0'
    let l:parameters = a:module.parameters
    let l:ports = a:module.ports

    if !empty(l:parameters)
        call add(l:lines, l:name . ' #(')
        let l:max_parameter = s:MaxNameLength(l:parameters)
        let l:index = 0
        for l:parameter in l:parameters
            let l:comma = l:index == len(l:parameters) - 1 ? '' : ','
            call add(l:lines, '    .' . l:parameter.name
            \   . repeat(' ', l:max_parameter - strlen(l:parameter.name) + 1)
            \   . '(' . l:parameter.name . ')' . l:comma)
            let l:index += 1
        endfor
        call add(l:lines, ') ' . l:instance_name . (empty(l:ports) ? ' ();' : ' ('))
    else
        call add(l:lines, l:name . ' ' . l:instance_name
        \   . (empty(l:ports) ? ' ();' : ' ('))
    endif

    if empty(l:ports)
        return l:lines
    endif

    let l:max_port = s:MaxNameLength(l:ports)
    let l:index = 0
    for l:port in l:ports
        let l:connection = l:port.name
        if get(g:, 'verilog_gen_connect_width', 1)
            let l:connection .= join(l:port.packed_dimensions, '')
        endif
        let l:comma = l:index == len(l:ports) - 1 ? '' : ','
        call add(l:lines, '    .' . l:port.name
        \   . repeat(' ', l:max_port - strlen(l:port.name) + 1)
        \   . '(' . l:connection . ')' . l:comma)
        let l:index += 1
    endfor
    call add(l:lines, ');')

    return l:lines
endfunction

function! s:GeneratedBufferName(module_name) abort
    let l:base = 'inst_' . tolower(a:module_name)
    let l:candidate = l:base . '.v'
    let l:index = 1

    while bufexists(l:candidate) || filereadable(l:candidate) || isdirectory(l:candidate)
        let l:candidate = l:base . '_' . l:index . '.v'
        let l:index += 1
    endwhile

    return l:candidate
endfunction

function! verilog_tools#OpenInstanceBuffer(lines, module_name) abort
    tabnew
    let l:buffer_name = s:GeneratedBufferName(a:module_name)
    execute 'file ' . fnameescape(l:buffer_name)
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal filetype=verilog
    call setline(1, a:lines)
    normal! gg
    let b:verilog_generated_kind = 'instance'
    let b:verilog_source_module = a:module_name
    return bufnr('%')
endfunction
