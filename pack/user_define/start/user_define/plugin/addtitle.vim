scriptencoding utf-8

let s:border = '//============================================================================='
let s:modified_pattern = '^\%(//\|#\)\s*Last modified:'
let s:filename_pattern = '^\%(//\|#\)\s*Filename:'
let s:timestamp_format = '%Y-%m-%d %H:%M'

" Pad a cell to a fixed display width, centred. Width is measured with
" strdisplaywidth() so CJK names line up with ASCII ones.
function! s:CenterCell(text, width) abort
    let l:pad = a:width - strdisplaywidth(a:text)
    if l:pad <= 0
        return a:text
    endif
    let l:left = l:pad / 2
    return repeat(' ', l:left) . a:text . repeat(' ', l:pad - l:left)
endfunction


function! AddTitle() abort
    let l:author = get(g:, 'verilog_title_author', 'Jelly')
    let l:email = get(g:, 'verilog_title_email', '823300630@qq.com')
    let l:version = get(g:, 'verilog_title_version', '1.0')
    let l:now = localtime()
    " 0 选公司头（Copyright 行），1 选个人头（Personal Website 行）；旧的
    " 字符串写法 'company' / 'personal' 仍然识别，已有的 vimrc 不用改。
    let l:template = get(g:, 'verilog_title_template', 1)
    if type(l:template) == v:t_string
        let l:company = l:template ==# 'company'
    else
        let l:company = l:template == 0
    endif
    if l:company
        let l:identity = '// Copyright: ' . get(g:, 'verilog_title_copyright_holder', '')
    else
        let l:identity = '// Personal Website: ' . get(g:, 'verilog_title_website', 'https://tyxiumud.github.io/')
    endif

    " Version table: fixed column widths keep the '|' separators aligned and
    " every cell centred, measured in display columns so CJK names line up.
    let l:today = strftime('%Y-%m-%d', l:now)
    let l:w_version = max([strdisplaywidth('Version'), strdisplaywidth(l:version)])
    let l:w_date = max([strdisplaywidth('Date'), strdisplaywidth(l:today)])
    let l:w_author = max([strdisplaywidth('Author'), strdisplaywidth(l:author)])
    let l:version_heading = '// ' . s:CenterCell('Version', l:w_version)
        \ . ' | ' . s:CenterCell('Date', l:w_date)
        \ . ' | ' . s:CenterCell('Author', l:w_author) . ' | Change Log'
    let l:version_row = '// ' . s:CenterCell(l:version, l:w_version)
        \ . ' | ' . s:CenterCell(l:today, l:w_date)
        \ . ' | ' . s:CenterCell(l:author, l:w_author) . ' |'

    let l:header = [
        \ s:border,
        \ '//',
        \ '// Author: ' . l:author . (empty(l:email) ? '' : ' Email: ' . l:email),
        \ '//',
        \ l:identity,
        \ '//',
        \ '// Last modified: ' . strftime(s:timestamp_format, l:now),
        \ '//',
        \ '// Filename: ' . expand('%:t'),
        \ '//',
        \ '// Description: ',
        \ '//',
        \ l:version_heading,
        \ l:version_row,
        \ '//',
        \ s:border,
        \ ]
    if line('$') == 1 && getline(1) ==# ''
        call setline(1, l:header + [
            \ 'module ' . toupper(expand('%:t:r')) . '(',
            \ '',
            \ ');',
            \ '//********************define parameter and internal signals********************',
            \ '',
            \ '//*****************************main code***************************************',
            \ '',
            \ 'endmodule',
            \ ])
    else
        call append(0, l:header)
    endif
    echo 'File header added.'
endfunction

" Collect fields only in the leading comment block, up to its closing border.
function! s:HeaderFields() abort
    let l:fields = {'modified': 0, 'filename': 0}
    let l:line_number = 1
    let l:seen_comment = 0
    let l:seen_border = 0
    while l:line_number <= line('$')
        let l:line = getline(l:line_number)
        if l:line ==# s:border
            if l:seen_border || l:seen_comment
                break
            endif
            let l:seen_border = 1
            let l:seen_comment = 1
        elseif l:line =~# '^\%(//\|#\)'
            let l:seen_comment = 1
            if !l:fields.modified && l:line =~# s:modified_pattern
                let l:fields.modified = l:line_number
            elseif !l:fields.filename && l:line =~# s:filename_pattern
                let l:fields.filename = l:line_number
            endif
        elseif l:seen_comment || l:line !~# '^\s*$'
            break
        endif
        let l:line_number += 1
    endwhile
    return l:fields
endfunction

" Rewrite legacy Chinese header labels to the English ones while updating.
function! s:NormalizeHeaderLabels() abort
    let l:line_number = 1
    while l:line_number <= line('$')
        let l:line = getline(l:line_number)
        if l:line =~# '^\s*$'
            let l:line_number += 1
            continue
        endif
        if l:line !~# '^\%(//\|#\)'
            break
        endif
        let l:new = substitute(l:line, '^\(\s*\%(//\|#\)\)\s*版权所有:\s*', '\1 Copyright: ', '')
        let l:new = substitute(l:new, '^\(\s*\%(//\|#\)\)\s*版本\s*|.*版本说明\s*$', '\1 Version | Date | Author | Change Log', '')
        if l:new !=# l:line
            call setline(l:line_number, l:new)
        endif
        let l:line_number += 1
    endwhile
endfunction

function! UpdateTitle() abort
    let l:fields = s:HeaderFields()
    if !l:fields.modified
        return 0
    endif
    let l:prefix = matchstr(getline(l:fields.modified), s:modified_pattern)
    call setline(l:fields.modified, l:prefix . ' ' . strftime(s:timestamp_format))
    if l:fields.filename
        let l:prefix = matchstr(getline(l:fields.filename), s:filename_pattern)
        call setline(l:fields.filename, l:prefix . ' ' . expand('%:t'))
    endif
    echo 'File header updated.'
    call s:NormalizeHeaderLabels()
    return 1
endfunction

function! TitleDet() abort
    if !UpdateTitle()
        call AddTitle()
    endif
endfunction
