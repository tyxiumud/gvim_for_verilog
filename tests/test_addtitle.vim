set encoding=utf-8
scriptencoding utf-8

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'source ' . fnameescape(s:root . '/pack/user_define/start/user_define/plugin/addtitle.vim')
let s:border = '//============================================================================='
let s:date = strftime('%Y-%m-%d')

" Generate a personal header with its first version and the module skeleton.
file personal_demo.v
call TitleDet()
call assert_true(index(getline(1, '$'), '// Personal Website: https://tyxiumud.github.io/') >= 0)
call assert_true(index(getline(1, '$'), '// Version | Date | Author | Change Log') >= 0)
call assert_true(index(getline(1, '$'), '// 1.0 | ' . s:date . ' | Jelly |') >= 0)
call assert_true(index(getline(1, '$'), 'module PERSONAL_DEMO(') >= 0)
call assert_equal('endmodule', getline('$'))

" Use the configured company and author on an existing module.
enew!
file company_demo.sv
let g:verilog_title_template = 'company'
let g:verilog_title_copyright_holder = '示例公司'
let g:verilog_title_author = '示例作者'
let g:verilog_title_email = ''
let g:verilog_title_version = '2.3'
let s:body = ['module company_demo;', '// Last modified: body note', 'endmodule']
call setline(1, s:body)
call TitleDet()
let s:lines = getline(1, '$')
call assert_true(index(s:lines, '// Copyright: 示例公司') >= 0)
call assert_equal(-1, match(s:lines, '^// Personal Website:'))
call assert_true(index(s:lines, '// Author: 示例作者') >= 0)
let s:version = '// 2.3 | ' . s:date . ' | 示例作者 |'
call assert_true(index(s:lines, s:version) >= 0)
call assert_equal(s:body, s:lines[-3:])

" Refresh only the header, regardless of the cursor and current settings.
let s:old_version = '// 2.3 | 2000-01-01 | 示例作者 | 手工填写'
let s:version_line = index(s:lines, s:version) + 1
if s:version_line > 0
    call setline(s:version_line, s:old_version)
endif
let s:modified_line = match(s:lines, '^// Last modified:') + 1
call setline(s:modified_line, '// Last modified: 2000-01-01 00:00')
file renamed.sv
call cursor(line('$') - 1, 5)
let s:cursor = getpos('.')
let @/ = 'keep-this-search'
let g:verilog_title_template = 'personal'
let g:verilog_title_version = '3.0'
call TitleDet()
call assert_match('^// Last modified: ' . s:date . ' \d\d:\d\d$', getline(s:modified_line))
call assert_true(index(getline(1, '$'), '// Filename: renamed.sv') >= 0)
call assert_equal(s:old_version, getline(s:version_line))
call assert_equal(s:body, getline(line('$') - 2, '$'))
call assert_equal(len(s:lines), line('$'))
call assert_equal(s:cursor, getpos('.'))
call assert_equal('keep-this-search', @/)

" Existing headers still work, including old spacing and missing fields.
enew!
file legacy.v
call setline(1, [s:border, "// Last modified:\t2000-01-01 00:00", s:border,
    \ '// Filename: keep-this-body-comment', 'module legacy;', 'endmodule'])
call TitleDet()
call assert_match('^// Last modified: ' . s:date . ' \d\d:\d\d$', getline(2))
call assert_equal('// Filename: keep-this-body-comment', getline(4))
call assert_equal(6, line('$'))

" Legacy Chinese labels are rewritten to English on update, version rows kept.
enew!
file legacy_label.v
call setline(1, [s:border,
    \ '// Author: Jelly',
    \ '// 版权所有: 旧公司',
    \ '// Last modified: 2000-01-01 00:00',
    \ '// Filename: legacy_label.v',
    \ '// 版本 | 日期 | 作者 | 版本说明',
    \ '// 1.0 | 2000-01-01 | Jelly | 手工填写',
    \ s:border,
    \ 'module legacy_label;', 'endmodule'])
call TitleDet()
let s:legacy = getline(1, '$')
call assert_true(index(s:legacy, '// Copyright: 旧公司') >= 0)
call assert_true(index(s:legacy, '// Version | Date | Author | Change Log') >= 0)
call assert_equal(-1, match(s:legacy, '版权所有\|版本 |'))
call assert_true(index(s:legacy, '// 1.0 | 2000-01-01 | Jelly | 手工填写') >= 0)

if !empty(v:errors)
    for s:error in v:errors
        echomsg s:error
    endfor
    cquit
endif
qa!
