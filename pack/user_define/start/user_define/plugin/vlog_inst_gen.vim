" Generate an instance template for the ANSI-style Verilog module in the
" current Buffer. Parsing and rendering live in autoload/verilog_tools.vim.

if exists('g:loaded_user_verilog_instance_generator')
    finish
endif
let g:loaded_user_verilog_instance_generator = 1

function! Autoinstance() abort
    try
        let l:module = verilog_tools#ParseCurrentBuffer()
        let l:instance_lines = verilog_tools#BuildInstance(l:module)
        call verilog_tools#OpenInstanceBuffer(l:instance_lines, l:module.name)
    catch /^verilog-tools:/
        echohl ErrorMsg
        echomsg substitute(v:exception, '^verilog-tools:\s*', 'Autoinstance: ', '')
        echohl None
    endtry
endfunction
