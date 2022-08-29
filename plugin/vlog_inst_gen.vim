""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       File Name       : vlog_inst_gen.vim
"       Author(s)       : ZhangLeiming @Xidian University
"       Contact Us      : mingforregister@163.com
"       Creat On        : 2012-07-02 17:12
"       Description     : generate verilog instance. If your file 
"           can accress syntax check, then this plugin can work.                                
"                           hot-keys
"                           ,ig         : instance generate
"                           ,im         : change working mode
"       Supported working mode:
"           mode 0(default): 
"               copy inst to clipboard and echo inst in commandline
"           mode 1:
"               only copy to clipboard
"           mode 2:
"               copy to clipboard and echo inst in split window
"           mode 3:
"               copy to clipboard and update inst_comment to file"
"
"       Reversion 1.0   20120702    ming
"                       file creation
"       Reversion 1.1   20120730    ming
"                       first success....
"       Reversion 1.2   20120730    ming
"                       1. add user defined command:
"                           VlogInstGen and VlogInstMod
"                       2. change key-mapping to ,ig and ,im
"                           ig: instance generation
"                           im: instance mode
"                       3. add my voice to zhizhi
"                           hot-key:,zz  ,,,  ,tc
"       Reversion 1.3   20120807    ming
"                       a little ~
"       Reversion 1.4   20120820    ming
"                       add one feature: copy instance also to clickboard
"                       ", so that you can use key 'p' to paste it. Also 
"                       you can disable this feature by modifying  this 
"                       script's line:
"                           let g:is_copy_inst_to_doublequotation = 1
"                       to:
"                           let g:is_copy_inst_to_doublequotation = 0
"       Reversion 1.5   20170829    ming
"                       1. Thank LongTang for bugs feedback
"                       2. Parameter support keywords signed/integer/real/realtime/time
"                       3. Support `ifdef/`else/`endif in module port declearation
"                       4. Disable port declearation check
"       Reversion 1.6   20220609    ming
"                       1. Thank LongTang for bugs feedback
"                       2. Fix bug when used in linux and ports more than 100
"                       3. Run faster than before
"                       4. vim script language reference: https://vimhelp.org/#reference_toc
"
"       For newest version please goto:
"       http://www.vim.org/scripts/script.php?script_id=4151
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('b:vlog_inst_gen') || &cp || version < 700
    finish
endif
let b:vlog_inst_gen = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       Key-Mapping
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"for debug
"restore this script
"if maparg("<F12>") != ""
    "silent! unmap <F12>
"endif
"map <F12> :unlet b:vlog_inst_gen<CR>:source C:/Program\ Files/Vim/vlog_inst_gen.vim<CR>
command     VlogInstGen     :call Vlog_Inst_Gen()
command     VlogInstMod     :call Vlog_Inst_Gen_Mode_Change()
if maparg(",ig") != ""
    silent! unmap ,ig
endif
if maparg(",im") != ""
    silent! unmap ,im
endif
nmap        ,ig             :VlogInstGen<CR>
nmap        ,im             :VlogInstMod<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       varibales
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"golobal setting
"hi  Vlog_Inst_Gen_Msg_0     gui=bold        guifg=#2E0CED       "lan tai liang
hi  Vlog_Inst_Gen_Msg_0     gui=bold        guifg=#1E56DB       "lan
"hi  Vlog_Inst_Gen_Msg_1     gui=NONE        guifg=#A012BA       "zi
hi  Vlog_Inst_Gen_Msg_1     gui=NONE        guifg=#DB26D2       "fen
"hi  Vlog_Inst_Gen_Msg_1     gui=NONE        guifg=#10E054       "lv
"golobal variables
let g:vlog_inst_gen_mode = 0            "0: echo generated instance in current window
                                        "1: do not echo generated instance, recommanded
                                        "2: echo generated instance in split window
                                        "3: insert generated instance in file head
let g:check_port_declaration = 0        " never set to '1', disabled by v1.5
let g:is_copy_inst_to_doublequotation = 1 "copy instance to clickboard,
                                        "so that you can use 'p' to 
                                        "paste..

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Clear_Parameter_List
"   Input           : a list
"   Output          : none
"   Return value    : none
"   Description     : clear given list.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Clear_Parameter_List(para_list)
    if empty(a:para_list) == 0
        call remove(a:para_list, 0, -1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Filter_Comment_Lines
"   Input           : start_line, end_line
"   Output          : non_comment_lines
"   Return value    : none
"   Description     : search from a:start_line to a:end_line, filter 
"       the commentlines, store non_comment lines to 
"       a:non_comment_lines list.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Filter_Comment_Lines(start_line, end_line, non_comment_lines)
    "check and clear non-comment line list
    call <SID>Clear_Parameter_List(a:non_comment_lines)
    let cur = a:start_line
    let end_line = a:end_line
    let mline_comment_flag = 0      "initial multi-line comment flag
    "start search
    while cur <= end_line
        let cur_line_content = getline(cur)
        "In multi-line comment
        if mline_comment_flag
            if cur_line_content =~ '^.*\*/\s*$'     "end of multi-line comment
                let cur = cur + 1
                let mline_comment_flag = 0
                continue
            else
                let cur = cur + 1
                continue
            endif
        "Not in multi-line comment
        else
            if cur_line_content =~ '\(^\s*//.*$\|^\s*/\*.*\*/\s*$\)'    "single line comment
                let cur = cur + 1
                continue
            elseif cur_line_content =~ '^\s*/\*.*$'                     "detect start of mcomment
                let cur = cur + 1
                let mline_comment_flag = 1
                continue
            elseif cur_line_content =~ '^\s*$'                          "remove empty lines
                let cur = cur + 1
                continue
            else                                                        "Non-comment lines
                call add(a:non_comment_lines, cur)
                let cur = cur + 1
                continue
            endif
        endif
    endw
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Search_Module
"   Input           : non_comment_lines
"   Output          : module_info_list
"   Return value    : module_num
"   Description     : search modules from given non_commentlines, and 
"       record module location infomation to list.
"   More            :
"       structure of module_info_list:
"               module_start_line   : keyword module appeare line
"               module_declare_line : the first ';' after keyword module
"               module_end_line     : keyword endmodule after module
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Search_Module(non_comment_lines, module_info_list)
    let line_num = len(a:non_comment_lines)     "number of lines
    let module_num = 0
    let i = 0
    "clear module_info_list
    if empty(a:module_info_list) == 0   "if not empty
        call remove(a:module_info_list, 1, -1)
    endif
    "search modules
    let in_module_flag = 0
    let find_declare_flag = 0
    let module_start_line = 0
    let module_declare_line = 0
    let module_end_line = 0
    while i < line_num
        let cur_line = a:non_comment_lines[i]   "get current search line
        let line_content = getline(cur_line)
        "search module start line
        if in_module_flag == 0
            if line_content =~ '^\s*\<module\>.*$'
                let module_start_line = cur_line
                let in_module_flag = 1
                let find_declare_flag = 0
            endif
            "incase declare in the same line
            if in_module_flag == 1
                if find_declare_flag == 0
                    if line_content =~ '^.*;.*$'        "the first semicolon is end of declareation
                        let module_declare_line = cur_line
                        let find_declare_flag = 1
                    endif
                endif
            endif
        "search module declare info and end module info
        else
            if find_declare_flag == 0       "find declare first
                if line_content =~ '^.*);.*$'
                    let module_declare_line = cur_line
                    let find_declare_flag = 1
                endif
            else
                if line_content =~ '^\s*\<endmodule\>\(\s*$\|\s*//.*$\|\s*/\*.*\*/\s*$\)'
                    let module_end_line = cur_line
                    call add(a:module_info_list, [module_start_line, module_declare_line, module_end_line])
                    let module_num = module_num + 1
                    let in_module_flag = 0
                endif
            endif
        endif
        let i = i+1
    endw
    return module_num
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Line_Pre_Process
"   Input           : a list
"   Output          : none
"   Return value    : none
"   Description     : preprocess given line's content
"       1. delete the comment at the end of line;
"       2. delete keyword(reg, wire, signed, integer, real, realtime, time);
"       3. delete vector identifier(eg. [7:0], [WIDTH-1:0]..);
"       4. delete attribute specified in verilog-2001(eg. (* keep=1*);
"       5. merge multi-spaces into one
"       6. delete the spaces at the start of line;
"       7. delete the spaces at the end of line;
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Line_Pre_Process(line_content)
    let lc = a:line_content
    "1. del comment at the end of line
    let lc = substitute(lc, '\s*\(//.*$\|/\*.*\*/\s*$\)', '', '')
    "2. del unused keyword: reg wire
    let lc = substitute(lc, '\(\<reg\>\|\<wire\>\|\<signed\>\|\<integer\>\|\<real\>\|\<realtime\>\|\<time\>\)', '', 'g')
    "3. del vector identifier (eg: [1:0])
    let lc = substitute(lc, '\[.\{-}\]', '', 'g')
    "4. del attributes
    let lc = substitute(lc, '(\*.\{-}\*)', '', 'g')
    "5. merge spaces into one
    let lc = substitute(lc, '\s+', '\b', 'g')
    "6. del the spaces at the beginning of line
    let lc = substitute(lc, '^\s*', '', '')
    "7. del the spaces at the end of line
    let lc = substitute(lc, '\s*$', '', '')
    return lc
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Merge_Module_Head
"   Input           : non_comment_lines, module_num, module_info_list
"   Output          : module_merged_list
"   Return value    : 0     Success         non_0   Error
"   Description     : merge module's head(eg. module xx(i1,i2,..);)
"       into one line.
"       module xx(i1,i2,`ifdef A,o1,`endif,o2,o3);
"       module xx(i1,i2,`ifdef A,o1@`else,o2@`endif,);
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Merge_Module_Head(non_comment_lines, module_num, module_info_list, module_merged_list)
    "parameter pre process
    call <SID>Clear_Parameter_List(a:module_merged_list)
    "merge module head
    let i = 0
    while i < a:module_num
        "get info
        let line_index = index(a:non_comment_lines, a:module_info_list[i][0])
        let line_index_end = index(a:non_comment_lines, a:module_info_list[i][1])
        "initial variable
        let module_merged_line = ""
        let line_content = ""
        while line_index <= line_index_end
            "get line content
            let line_content = getline(a:non_comment_lines[line_index])
            let line_content = <SID>Line_Pre_Process(line_content)
            if line_content =~ '^`\(\<ifdef\>\|\<else\>\|\<endif\>\).*'
                let line_content = line_content.','
                if empty(module_merged_line) == 0
                    if module_merged_line[len(module_merged_line)-1] != ","
                        let module_merged_line = module_merged_line."@".line_content
                    else
                        let module_merged_line = module_merged_line.line_content
                    endif
                else
                    let module_merged_line = module_merged_line.line_content
                endif
            else
                let module_merged_line = module_merged_line.line_content
            endif
            let line_index = line_index+1
        endw
        "del spaces between charactor
        "  1. spaces after module/parameter/input/output/inout only keep one
        "  2. spaces not after module/parameter/input/output/inout delete all
        "echo module_merged_line
        let module_merged_line = substitute(module_merged_line, '\(\<module\>\|\<parameter\>\|\<input\>\|\<output\>\|\<inout\>\|\<ifdef\>\)\@<!\s\+', '', 'g')
        "echo module_merged_line
        "store merged module info
        call add(a:module_merged_list, module_merged_line)
        let i = i+1
    endw
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Analysis_Module_Head
"   Input           : module_num, module_merged_list
"   Output          : module_name, para, vlog_95_flag, 
"                       port, port_i, port_o, port_io
"   Return value    : 0     success         1   error
"   Description     : analysis module head from module_merged_list, 
"       find the module_name, parameters, verilog_format, port info
"       and store into output list.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Analysis_Module_Head(module_num, module_merged_list, module_name, para, vlog_95_flag, port, port_i, port_o, port_io)
    "initiciate parameters
    call <SID>Clear_Parameter_List(a:module_name)
    call <SID>Clear_Parameter_List(a:para)
    call <SID>Clear_Parameter_List(a:vlog_95_flag)
    call <SID>Clear_Parameter_List(a:port)
    call <SID>Clear_Parameter_List(a:port_i)
    call <SID>Clear_Parameter_List(a:port_o)
    call <SID>Clear_Parameter_List(a:port_io)
    "begin analysis
    let i = 0
    while i < a:module_num
        let module_head = a:module_merged_list[i]
        "***********************************************
        "step 1: search module identifier
        "***********************************************
        let mname = ""
        "del key word: module
        if module_head =~ '^\<module\>\s'
            let module_head = substitute(module_head, '^\<module\>\s', '', '')
        else
            return 3            "Error 3: can't find keyword
        endif
        let mname = substitute(module_head, '^[a-zA-Z_][a-zA-Z_0-9]*\zs.*$', '', '')        "get module name
        let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z_0-9]*', '', '')       "delete module name
        "add info to list
        call add(a:module_name, mname)
        "***********************************************
        "step 2: judge weather this is a top module
        "***********************************************
        if module_head =~ '^;$'     "end of module
            call add(a:para, [])
            call add(a:vlog_95_flag, 0)
            call add(a:port, [])
            call add(a:port_i, [])
            call add(a:port_o, [])
            call add(a:port_io, [])
            let i = i+1
            continue
        endif
        "***********************************************
        "step 3: get parameter info
        "***********************************************
        if module_head =~ '^#(.*$'
            let para_key = ''
            let para_val = ''
            let para_list = []
            let module_head = substitute(module_head, '\<parameter\>\s*', '', 'g')  "del keyword: parameter
            let module_head = substitute(module_head, '^#(', '', '')                "del #(
            while 1
                if module_head =~ '^)'      "parameter fetch end
                    let module_head = substitute(module_head, '^)', '', '')         "del )
                    break
                elseif module_head =~ '^,'  "del ,
                    let module_head = substitute(module_head, '^,', '', '')
                    continue
                elseif module_head =~ '^[a-zA-Z_][a-zA-Z0-9_]*=.*[,)]'   "find para
                    let para_key = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*\zs.*$', '', '')
                    let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*=', '', '')
                    let para_val = substitute(module_head, '^.\{-}\zs[,)].*$', '', '')  "match the first , or )
                    let module_head = substitute(module_head, '^.\{-}\ze[,)]', '', '')
                    call add(para_list, [para_key, para_val])
                    continue
                else
                    return 4            "Error 4: when find parameter
                endif
            endw
            call add(a:para, para_list)     "store parameter list
        else        "if has none parameter, then fullfill the position of module in list with empty value
            call add(a:para, [])
        endif
        "***********************************************
        "step 4: judge vlog version 95 or 2001
        "***********************************************
        if module_head =~ '\(\<input\>\|\<output\>\|\<inout\>\)'
            call add(a:vlog_95_flag, 0)
        else
            call add(a:vlog_95_flag, 1)
        endif
        "***********************************************
        "step 5: analysis port
        "***********************************************
        if module_head !~ '^('
            return 5            "Error 5: start of analysis port
        endif
        "echo module_head
        let module_head = substitute(module_head, '^(', '', '')
        let p_dir = 0           " 0 none     1 input     2 output    3 inout
        let pid = ''
        let p_list = []
        let pi_list = []
        let po_list = []
        let pio_list = []
        while 1
            if module_head =~ '^);'         "end of analysis
                break
            elseif module_head =~ '^,.*'      "del ,
                let module_head = substitute(module_head, '^,', '', '')
                continue
            elseif module_head =~ '^@.*'      "del @
                let module_head = substitute(module_head, '^@', '', '')
                continue
            elseif module_head =~ '^\(\<input\>\|\<output\>\|\<inout\>\).*'         "find port direction
                if module_head =~ '^\<input\>'
                    let p_dir = 1
                elseif module_head =~ '^\<output\>'
                    let p_dir = 2
                elseif module_head =~ '^\<inout\>'
                    let p_dir = 3
                endif
                let module_head = substitute(module_head, '^\(\<input\>\|\<output\>\|\<inout\>\)\s*', '', '')
                continue
            elseif module_head =~ '^[a-zA-Z_][a-zA-Z0-9_]*[,)].*'                   "find port
                let pid = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*\zs[,)].*$', '', '')
                let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*', '', '')
                call add(p_list, pid)
                if p_dir == 1
                    call add(pi_list, pid)
                elseif p_dir == 2
                    call add(po_list, pid)
                elseif p_dir == 3
                    call add(pio_list, pid)
                endif
                continue
            elseif module_head =~ '^[a-zA-Z_][a-zA-Z0-9_]*@.*'                      "find predef last port
                let pid = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*\zs@.*$', '', '')
                let module_head = substitute(module_head, '^[a-zA-Z_][a-zA-Z0-9_]*', '', '')
                call add(p_list, pid."@")
                if p_dir == 1
                    call add(pi_list, pid)
                elseif p_dir == 2
                    call add(po_list, pid)
                elseif p_dir == 3
                    call add(pio_list, pid)
                endif
                continue
            elseif module_head =~ '^`\(\<ifdef\>\|\<else\>\|\<endif\>\).*'          "find `ifdef/`else/`endif
"                let pid = substitute(module_head, '^`ifdef\s[a-zA-Z0-9_]*\zs[,)].*$', '', '')
"                let pid = substitute(module_head, '^.*\zs[,)].*$', '', '')
"                let module_head = substitute(module_head, '^.*,', '', '')
                let pid = substitute(module_head, '^`\(\<ifdef\>\s[a-zA-Z0-9_]*\|\<else\>\|\<endif\>\)\zs[,)].*$', '', '')
                let module_head = substitute(module_head, '^`\(\<ifdef\>\s[a-zA-Z0-9_]*\|\<else\>\|\<endif\>\)', '', '')
                call add(p_list, pid)
                continue
            else
                return 6        "Error 6: when analysising port
            endif
        endw
        call add(a:port, p_list)
        call add(a:port_i, pi_list)
        call add(a:port_o, po_list)
        call add(a:port_io, pio_list)
        let i = i+1
    endw
    "echo po_list
    "check output list
    if          len(a:module_name)      != a:module_num     || 
            \   len(a:para)             != a:module_num     || 
            \   len(a:vlog_95_flag)     != a:module_num     || 
            \   len(a:port)             != a:module_num     || 
            \   len(a:port_i)           != a:module_num     || 
            \   len(a:port_o)           != a:module_num     || 
            \   len(a:port_io)          != a:module_num
        return 7                "Error 7: invalid return value
    endif
    return 0
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Analysis_Module_Body
"   Input           : non_comment_lines, module_num, module_info_list
"                       vlog_95_flag
"   Output          : port_declear, port_i, port_o, port_io
"   Return value    : 0     success         1   error
"   Description     : analysis module body to find port declaration
"       inforamtion, then update them to port io lists.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Analysis_Module_Body(non_comment_lines, module_num, module_info_list, vlog_95_flag, port_declare, port_i, port_o, port_io)
    "initiciate parameters
    call <SID>Clear_Parameter_List(a:port_declare)
    "start analysis
    let i = 0
    while i < a:module_num
        let pid = ''
        let p_dir = 0           " 0 none    1 input     2 output    3 inout
        let p_list = []
        let pi_list = []
        let po_list = []
        let pio_list = []
        if a:vlog_95_flag[i] == 1   "need analysis
            let line_index = index(a:non_comment_lines, a:module_info_list[i][1])
            let line_index_end = index(a:non_comment_lines, a:module_info_list[i][2])
            while line_index <= line_index_end
                let line_content = getline(a:non_comment_lines[line_index])
                let line_content = <SID>Line_Pre_Process(line_content)          "remove unused parts
                if line_content =~ '^\s*\(\<input\>\|\<output\>\|\<inout\>\)\s*'
                    let line_content = substitute(line_content, '\(\<input\>\|\<output\>\|\<inout\>\)\@<!\s\+', '', 'g') "remove spaces
                    if line_content =~ '^\<input\>'
                        let p_dir = 1
                    elseif line_content =~ '^\<output\>'
                        let p_dir = 2
                    elseif line_content =~ '^\<inout\>'
                        let p_dir = 3
                    else
                        let p_dir = 0
                    endif
                    let line_content = substitute(line_content, '^\(\<input\>\|\<output\>\|\<inout\>\)\s*', '', '')
                    while 1
                        if line_content =~ '^;'
                            break
                        elseif line_content =~ '^,'
                            let line_content = substitute(line_content, '^,', '', '')
                            continue
                        elseif line_content =~ '^[a-zA-Z_][a-zA-Z0-9_]*[,;]'
                            "get pid
                            let pid = substitute(line_content, '^[a-zA-Z_][a-zA-Z0-9_]*\zs[,;].*$', '', '')
                            "store pid
                            call add(p_list, pid)
                            if p_dir == 1
                                call add(pi_list, pid)
                            elseif p_dir == 2
                                call add(po_list, pid)
                            elseif p_dir == 3
                                call add(pio_list, pid)
                            endif
                            "del this pid
                            let line_content = substitute(line_content, '^[a-zA-Z_][a-zA-Z0-9_]*\ze[,;]', '', '')
                        else
                            return 4        "Error 4: when processing port declare line.
                        endif
                    endw
                endif
                let line_index = line_index+1
            endw
        endif
        call add(a:port_declare, p_list)
        let a:port_i[i] = pi_list
        let a:port_o[i] = po_list
        let a:port_io[i] = pio_list
        let i = i+1
    endw
    "check output list
    if          len(a:port_declare)     != a:module_num     || 
            \   len(a:port_i)           != a:module_num     || 
            \   len(a:port_o)           != a:module_num     || 
            \   len(a:port_io)          != a:module_num
        return 7                "Error 7: invalid return value
    endif
    return 0
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Locate_Inst_Position
"   Input           : first_module_line
"   Output          : inst_start, inst_end
"   Return value    : 0     success     1   error
"   Description     : find weather there is a instance existing in file,
"       if so, return it's start_line and end_line information; else
"       let start_line and end_line to empty.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Locate_Inst_Position(first_module_line, inst_start, inst_end)
    "init parameter
    call <SID>Clear_Parameter_List(a:inst_start)
    call <SID>Clear_Parameter_List(a:inst_end)
    let line_flag = 0
    let exist_flag = 0
    "search given lines
    let i = 1
    while i < a:first_module_line
        let line_content = getline(i)
        if line_flag == 0       "find none of the inst
            if line_content =~ '/\*\{77}'
                call add(a:inst_start, i)
                let line_flag = 1
            else
                call <SID>Clear_Parameter_List(a:inst_start)
            endif
        elseif line_flag == 1
            if line_content =~ '\*\{14}\s\{5}INST\sGENERATED\sBY\sVLOG_INST_GEN\sPLUGIN\s\{5}\*\{16}'
                let line_flag = 2
            else
                let line_flag = 0
            endif
        elseif line_flag == 2
            if line_content =~ '\*\{78}'
                let line_flag = 3
            else
                let line_flag = 0
            endif
        elseif line_flag == 3
            if line_content =~ '\*\{77}/'
                call add(a:inst_end, i)
                let exist_flag = 1
                break
            endif
        else
            return 1        "unknown flag
        endif
        let i = i+1
    endw
    "return value
    if exist_flag == 1
        if empty(a:inst_start)!=0 || empty(a:inst_end)!=0 || a:inst_start[0]>=a:inst_end[0]
            return 2
        endif
    endif
    return 0
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Inst_Part_Format
"   Input           : module_num, module_name, para_list, port_list
"   Output          : none
"   Return value    : inst_part
"   Description     : generate and return instance from given 
"       information.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! <SID>Inst_Part_Format(module_num, module_name, para_list, port_list)
    let inst = ""
    let has_para_flag = 0
    let i = 0
    while i < a:module_num
        "parameter process
        if empty(a:para_list[i])    "has no parameter
            let has_para_flag = 0
            let inst = inst.a:module_name[i]." U_".toupper(a:module_name[i])."_0(\n"
        else                        "has parameters
            let has_para_flag = 1
            let inst = inst.a:module_name[i]." #(\n"
            let list_len = len(a:para_list[i])
            let list_index = 0
            while 1
                let para = a:para_list[i][list_index]
                let line_content = "    .".para[0]
                while strwidth(line_content) < 36
                    let line_content = line_content." "
                endw
                let line_content = line_content."( ".para[1]
                while strwidth(line_content) < 68
                    let line_content = line_content." "
                endw
                if list_index == list_len-1     "the last item
                    let line_content = line_content."))\n"
                    let inst = inst.line_content
                    break
                else
                    let line_content = line_content."),\n"
                    let inst = inst.line_content
                    let list_index = list_index+1
                    continue
                endif
            endw
        endif
        "port process
        if has_para_flag == 1           "has parameter
            let inst = inst."U_".toupper(a:module_name[i])."_0(\n"
        endif
        if empty(a:port_list[i]) == 0   "has port
            let list_len = len(a:port_list[i])
            let list_index = 0
            while 1
                let port = a:port_list[i][list_index]
                if port =~ '^`\(\<ifdef\>\|\<else\>\|\<endif\>\).*'
                    let line_content = port."\n"
                    let inst = inst.line_content
                    if list_index == list_len-1
                        break
                    else
                        let list_index = list_index+1
                        continue
                    endif
                elseif port[len(port)-1] == "@"
                    let line_content = "    .".port[0:(len(port)-2)]
                    "insert spaces the first time
                    while strwidth(line_content) < 36
                        let line_content = line_content." "
                    endw
                    "insert spaces the second time
                    let line_content = line_content."( ".port[0:(len(port)-2)]
                    while strwidth(line_content) < 68
                        let line_content = line_content." "
                    endw
                    let line_content = line_content.")\n"
                    let inst = inst.line_content
                    let list_index = list_index+1
                    continue
                else
                    let line_content = "    .".port
                    "insert spaces the first time
                    while strwidth(line_content) < 36
                        let line_content = line_content." "
                    endw
                    "insert spaces the second time
                    let line_content = line_content."( ".port
                    while strwidth(line_content) < 68
                        let line_content = line_content." "
                    endw
                    if list_index == list_len-1     "the last item
                        let line_content = line_content.")\n"
                        let inst = inst.line_content
                        break
                    else
                        let line_content = line_content."),\n"
                        let inst = inst.line_content
                        let list_index = list_index+1
                        continue
                    endif
                endif
            endw
        endif
        "add );
        let inst = inst.");\n\n"
        "next module
        let i = i+1
    endw
    return inst
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   function        : Vlog_Inst_Gen
"   Input           : none
"   Output          : none
"   Return value    : 0     success     non_0   error
"   Description     : generate inst and work in given mode.
"   More            :
"       supported mode: 0, 1, 2, 3
"           mode 0(default): 
"               copy to clipboard and echo inst in commandline
"           mode 1:
"               only copy to clipboard
"           mode 2:
"               copy to clipboard and echo inst in split window
"           mode 3:
"               copy to clipboard and update inst_comment to file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! Vlog_Inst_Gen()
    "step 1:    search non-comment lines
    let non_comment_lines = []
    call <SID>Filter_Comment_Lines(1, line("$"), non_comment_lines)
    "step 2:    search module
    let module_info = []
    let module_num = <SID>Search_Module(non_comment_lines, module_info)
    if module_num == 0
        echohl ErrorMsg
        echo "None module found."
        echohl None
        return 1
    endif
    "step 3:    merge module head
    let merged_head_list = []
    let merge_result = <SID>Merge_Module_Head(non_comment_lines, module_num, module_info, merged_head_list)
    if merge_result != 0
        echohl ErrorMsg
        echo "Error ".merge_result.": when merging module head."
        echohl None
        return 2
    endif
    "step 4:    analysis module head
    let module_name_list = []
    let para_list = []
    let vlog_95_flag_list = []
    let port_list = []
    let port_i_list = []
    let port_o_list = []
    let port_io_list = []
    let analysis_head_result = <SID>Analysis_Module_Head(module_num, merged_head_list, module_name_list, 
                \   para_list, vlog_95_flag_list, port_list, port_i_list, port_o_list, port_io_list)
    if analysis_head_result != 0
        echohl ErrorMsg
        echo "Error ".analysis_head_result.": when analysis module head."
        echohl None
        return 3
    endif
    "step 5: check port declaration(optional by g:check_port_declaration)
    if g:check_port_declaration == 1
        let port_declare_list = []
        let analysis_body_result = <SID>Analysis_Module_Body(non_comment_lines, module_num, module_info, 
                    \   vlog_95_flag_list, port_declare_list, port_i_list, port_o_list, port_io_list)
        if analysis_body_result != 0
            echohl ErrorMsg
            echo "Error ".analysis_body_result.": when analysis module body."
            echohl None
            return 4
        endif
        "start compare between port_list, port_declare_list
        let module_index = 0
        while module_index < module_num
            if vlog_95_flag_list[module_index] == 1
                for mp in port_list[module_index]
                    if count(port_declare_list[module_index], mp) < 1
                        echohl ErrorMsg
                        echo "Port ".mp.": has no declaration."
                        echohl None
                        return 5
                    endif
                endfor
                for mpc in port_declare_list[module_index]
                    if count(port_list[module_index], mpc) < 1
                        echohl ErrorMsg
                        echo "Port ".mpc.": not appeared in port list."
                        echohl None
                        return 6
                    endif
                endfor
            endif
            let module_index = module_index+1
        endw
    endif
    "step 6: get inst part and copy to clipboard
    let inst_part = <SID>Inst_Part_Format(module_num, module_name_list, para_list, port_list)
    let @+ = inst_part
    if g:is_copy_inst_to_doublequotation
        let @" = inst_part
    endif
    "step 6: get inst insert location
    if g:vlog_inst_gen_mode == 0
        echohl Vlog_Inst_Gen_Msg_0
        echo "\n"
        echo module_num." insts as follows copyed:"
        echo "\n"
        echohl Vlog_Inst_Gen_Msg_1
        echo inst_part
        echohl Vlog_Inst_Gen_Msg_0
        echohl None
    elseif g:vlog_inst_gen_mode == 1
        echohl Vlog_Inst_Gen_Msg_0
        echo module_num." insts has been copyed."
        echohl None
    elseif g:vlog_inst_gen_mode == 2
        exe "split __Instance_File__"
        silent put! =inst_part
        exe "normal gg"
        "set buffer
        setlocal noswapfile
        setlocal buftype=nofile
        setlocal bufhidden=delete
        setlocal filetype=verilog
    elseif g:vlog_inst_gen_mode == 3
        "get inst update location
        let inst_start = []
        let inst_end = []
        let inst_locate_result = <SID>Locate_Inst_Position(module_info[0][0], inst_start, inst_end)
        if inst_locate_result != 0
            echohl ErrorMsg
            echo "Error ".inst_locate_result.": when locate inst postion."
            echohl None
        endif
        if empty(inst_start)==1 && empty(inst_end)==1   "no inst exists
            let inst_loc = module_info[0][0]
        else                                            "delete existing instance
            silent exe inst_start[0].",".inst_end[0]."d"
            let inst_loc = inst_start[0]
        endif
        call append(inst_loc-1, "/*****************************************************************************")
        call append(inst_loc+0, "**************     INST GENERATED BY VLOG_INST_GEN PLUGIN     ****************")
        call append(inst_loc+1, "******************************************************************************")
        call append(inst_loc+2, "*****************************************************************************/")
        "update instance
        exe inst_loc+3
        silent put! =inst_part
        exe inst_loc
        exe "ks"
        exe "'s"
        echohl Vlog_Inst_Gen_Msg_0
        echo module_num." insts has been copyed and updated."
        echohl None
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Subfunction     : Vlog_Inst_Gen_Mode_Change
"   Input           : none
"   Output          : none
"   Return value    : none
"   Description     : change vlog_inst_gen working mode.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! Vlog_Inst_Gen_Mode_Change()
    if g:vlog_inst_gen_mode == 0
        let g:vlog_inst_gen_mode = 1
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 1: only copy to clipboard."
        echohl None
    elseif g:vlog_inst_gen_mode == 1
        let g:vlog_inst_gen_mode = 2
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 2: copy to clipboard and display in split window."
        echohl None
    elseif g:vlog_inst_gen_mode == 2
        let g:vlog_inst_gen_mode = 3
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 3: copy to clipboard and update in file."
        echohl None
    elseif g:vlog_inst_gen_mode == 3
        let g:vlog_inst_gen_mode = 0
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 0: copy to clipboard and echo in commandline."
        echohl None
    else
        let g:vlog_inst_gen_mode = 0
        echohl Vlog_Inst_Gen_Msg_0
        echo "Vlog_Inst_Gen Use Mode 0: copy to clipboard and echo in commandline."
        echohl None
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       Say something to zhizhi..
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"golobal variables
let g:list_length_max = 40              "the length of the mapped list
let g:string_last_list_point = 80       "the point of the flag of last list of string. It's char 'P'
let g:ch_unmap_point = 111              "unmap point, char 'o'
let g:ch_unmap_add = 14                 "unmap sub value
let g:ch_unmap_sub = 80                 "unmap add value
let g:str_use_color_flag = 1
let g:gvim_win_width = 80
let g:last_output_str = []
let g:last_output_cmdheight = 1
"string related
let g:str_sum = 16                      "the sum of string
let g:str_list_dict = {0:0, 1:1, 2:2, 3:4, 4:6, 5:9, 6:11, 7:13, 8:15,
            \   9:17, 10:19, 11:20, 12:22, 13:24, 14:26, 15:28}
let g:mapped_voice_to_zz = [
            \   "I*\"\"(x+'G_\"$'$\" u%@[?w*:3FtJ;#y\\-->7\"vUYm&)*|i0D[#",
            \   "j/\"$$#.kujKagpSdWpSpbdWffkpY[d^ oa735J9je!BH[Xk)c3",
            \   ".Q\"'&+zpA$Kagdp^SgYZp^[]WpTd[^^[S`fpeg`eZ[`W|p;p^[",
            \   "%A\"#&G;.&d]Wp[fpeap_gUZ zT_=E=jr2kjfRW=DSpzUrt,h;j",
            \   "Ub\")$|(O'GKagdpZShWp^ahW^kpUS`[`WpfaafZ|pfZWkp^aa]",
            \   "_J\"%$kSutOep_adWpTWSgf[Xg^piZW`pkagp^SgYZ DC=AK@W(",
            \   "BW##'0rM[ZFZWpVSkpiZW`p_kpYS_WpTWYS`pXSVWV|p_kp^[X",
            \   "t\\\"&\"aj?vIWefk^WpUZS`YWVpSp^af|p;pS_pXg^^paXpefdW`",
            \   "q%\"%'6g*M[YfZ|p_SkTWp[fwepkagdpUa_[`Ypfap&#& _Iej3",
            \   "Cm\"()abcJd;Xp[fwepdWS^pfZSfpkagdpSdWp_S`|p_SkpTWp[",
            \   "mN\"$)G;&JMfwepi[eWpXadp_S`pTW[`YpYSk 9$tUN&F2du\"(-",
            \   "#f\"(&L#q.<Kagp]WWbpV[efS`UWpi[fZp_W|pTgfpkagpUS_Wp",
            \   "<O\"$&IZ=-n_adWpU^aeWdp[`p_kpZWSdf vBn[0[A9853&31(z",
            \   "bp\"'#+=[[0;piS`fpfapeWWpeg`d[eWpi[fZpkagp[`pfZWpab",
            \   "!,\"## ?0v|W`pUag`fdk WsUU&*{h4>|\\VOKRyd0VD5:&|Sf:7",
            \   "2u\"')7U1y|;fwepUalkpfapiS^]pi[fZpkagp[`pfZWpdSV[S`",
            \   "n%\"#)w)8#WUWpaXpfZWpeg`eWf il\"W9ubJcXm/UmjqKPCNvx!",
            \   ":Q\"'+ARV$QA`UWp_kpV[eST^[fkpfap_S]Wpkagp^SgYZ[`YpX",
            \   "HK\"#+NY6'FdgefdSfWVp_WpSp^af JQ.0='vbhld94pCr>Zk4a",
            \   "4C\"&\"JQ<8rKagdpZSbb[`Weep[ep_kpYdWSfWefpZSbb[`Wee ",
            \   "0T\"(%GI]6PKagdp`SfgdWpS`VpU^WhWdpiWdWpiZSfp;pS_pSX",
            \   "s-\"$%ROsb;fWd|pfZWkpSffdSUfWVp_W P=5=\"#iD*==d!O)La",
            \   "{a\"&)K._G4;pYgWeepkagpSdWpSpY[d^pi[fZpefda`Ypi[^^x",
            \   "&6\"\")mO9nvK[LZ[y *|y`pCA1+!['75W`Q:IMBz5aA+=Q1FLx=",
            \   "s]\"($QRx|1FZWpf[_WpkagpVWhafWVp[`piad]pZSepea_Wpba",
            \   "1?\"$$xO7{P[`fepfZWpeS_Wpi[fZp_W :og9[liU<wK\"x&(x*M",
            \   "{b\"()r.uIz;fwepX[`WpXadp_WpfapSUUWbfpkagdpUZa[UW|p",
            \   "\"N\"$)b#wfcVa`wfpiaddkpSTagfpS`kfZ[`Y tN#[5TQ=B^4r>",
            \   "L1\"%#WZdWlLZ[LZ[|pkagpSdWpSpbWdXWUfpY[d^ `9(TxqwaJ"]

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       Random number generation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:rnd = localtime() % 0x10000
let g:num_history = [0, 0, 0, 0, 0]
"random generate
fun! <SID>Usr_Random()
  let s:rnd = (s:rnd * 31421 + 6927) % 0x10000
  return s:rnd
endfun
"random with range generate
fun! <SID>Usr_Choose(n) " 0 n within
  return (<SID>Usr_Random() * a:n) / 0x10000
endfun
"choose random numbers that doesn't same with the previous 5 numbers
fun! <SID>Usr_Get_Choice(n)
    if          g:num_history[0] == 0   &&
            \   g:num_history[1] == 0   &&
            \   g:num_history[2] == 0   &&
            \   g:num_history[3] == 0   &&
            \   g:num_history[4] == 0
        let g:num_history = [0, a:n-2, a:n-3, a:n-4, a:n-5]
    endif
    let num_cur = <SID>Usr_Choose(a:n)
    while index(g:num_history, num_cur) >= 0
        let num_cur = <SID>Usr_Choose(a:n)
    endwhile
    let g:num_history = g:num_history[0:3]
    call insert(g:num_history, num_cur)
    return num_cur
endfun

"define my color groups
hi  Usr_Def_Color_0     gui=bold        guifg=#EC75A5       "
hi  Usr_Def_Color_1     gui=bold        guifg=#C85064       "
hi  Usr_Def_Color_2     gui=bold        guifg=#E97D07       "cheng
hi  Usr_Def_Color_3     gui=bold        guifg=#59B00B       "lv
hi  Usr_Def_Color_4     gui=bold        guifg=#B66B52       "zong
hi  Usr_Def_Color_5     gui=bold        guifg=#5F9A97       "lan
hi  Usr_Def_Color_6     gui=bold        guifg=#9D5E76       "more or less zi
hi  Usr_Def_Color_7     gui=bold        guifg=#E754BB       "fen
hi  Usr_Def_Color_8     gui=bold        guifg=#DF3FFC       "fen zi
hi  Usr_Def_Color_9     gui=bold        guifg=#8B7A4E       "hui
"set echo highlight style to random group
fun! <SID>Usr_Echohl_Set()
    "get random color number
    let color_rand = <SID>Usr_Get_Choice(10)
    "set echohl
    if color_rand == 0
        echohl Usr_Def_Color_0
    elseif color_rand == 1
        echohl Usr_Def_Color_1
    elseif color_rand == 2
        echohl Usr_Def_Color_2
    elseif color_rand == 3
        echohl Usr_Def_Color_3
    elseif color_rand == 4
        echohl Usr_Def_Color_4
    elseif color_rand == 5
        echohl Usr_Def_Color_5
    elseif color_rand == 6
        echohl Usr_Def_Color_6
    elseif color_rand == 7
        echohl Usr_Def_Color_7
    elseif color_rand == 8
        echohl Usr_Def_Color_8
    elseif color_rand == 9
        echohl Usr_Def_Color_9
    else
        echohl None
    endif
endfun

"Unmap string and output them
"judge wether it is the last list flag
fun! <SID>Str_LL_Judge(ch)
    let ll_flag = char2nr(a:ch)
    if ll_flag > g:string_last_list_point
        return 0
    else
        return 1
    endif
endfun
"unmap one charactor
fun! <SID>Unmap_Char(ch)
    let str_nr = char2nr(a:ch)   "trans to ascii value
    if str_nr > g:ch_unmap_point
        let str_nr = str_nr - g:ch_unmap_sub
    else
        let str_nr = str_nr + g:ch_unmap_add
    endif
    let str_nr = nr2char(str_nr)
    return str_nr
endfun
"Output to the command line
fun! <SID>Mapped_Output(str_sum)
    let g:last_output_str = []
    "get choice
    let usr_choice = <SID>Usr_Get_Choice(a:str_sum)
    "get string info
    let first_list_flag = 1
    let last_list_flag = 0
    let str_idx = g:str_list_dict[usr_choice]

    while last_list_flag == 0
        let str_list = g:mapped_voice_to_zz[str_idx]
        let last_list_flag = <SID>Str_LL_Judge(strpart(str_list, 1, 1))
        let str_len = <SID>Unmap_Char(strpart(str_list, 2, 1)).<SID>Unmap_Char(strpart(str_list, 3, 1)).<SID>Unmap_Char(strpart(str_list, 4, 1))
        let str_len = str2nr(str_len)
        "set cmdheight
        if first_list_flag == 1
            let first_list_flag = 0 "clear flag
            if g:gvim_win_width < 30    " too narrow
                let &cmdheight = 5
                let g:last_output_cmdheight = 5
            else                        " enough width
                if str_len > (g:gvim_win_width-30)*3
                    let &cmdheight = 4
                    let g:last_output_cmdheight = 4
                elseif str_len > (g:gvim_win_width-30)*2
                    let &cmdheight = 3
                    let g:last_output_cmdheight = 3
                elseif str_len > g:gvim_win_width-30
                    let &cmdheight = 2
                    let g:last_output_cmdheight = 2
                else
                    let &cmdheight = 1
                    let g:last_output_cmdheight = 1
                endif
            endif
        endif
        "output list
        if str_len > g:list_length_max
            let str_len = g:list_length_max
        endif
        let i = 0
        while i<str_len
            echon <SID>Unmap_Char(strpart(str_list, i+10, 1))
            let g:last_output_str = add(g:last_output_str, <SID>Unmap_Char(strpart(str_list, i+10, 1)))
            let i = i+1
        endw
        let str_idx = str_idx + 1
    endw
endfun
"colored output
fun! <SID>Ming_Say_To_ZZ(str_sum)
    if g:str_use_color_flag == 0
        echohl None
    else
        call <SID>Usr_Echohl_Set()
    endif
    call <SID>Mapped_Output(a:str_sum)
    echohl None
endfun
"output last str
fun! <SID>Usr_Last_Str_Output()
    let l = len(g:last_output_str)
    let index = 0
    while index < l
        echon g:last_output_str[index]
        let index = index + 1
    endw
endfun
"toggle color flag
fun! <SID>Toggle_String_Output_Color()
    if g:str_use_color_flag == 0
        echo ""
        call <SID>Usr_Echohl_Set()
        let &cmdheight = g:last_output_cmdheight
        call <SID>Usr_Last_Str_Output()
        echohl None
        let g:str_use_color_flag = 1
    else
        echo ""
        let &cmdheight = g:last_output_cmdheight
        call <SID>Usr_Last_Str_Output()
        let g:str_use_color_flag = 0
    endif
endfun
"auto adjust the width of gvim's window
autocmd GUIEnter,VimResized *.* let g:gvim_win_width = winwidth(0)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       key mapping
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"output hot-key
if maparg(",zz") != ""
    silent! unmap ,zz
endif
map ,zz :call <SID>Ming_Say_To_ZZ(g:str_sum)<CR>
"clear output and reset cmdheight
if maparg(",,,") != ""
    silent! unmap ,,,
endif
map ,,, :set cmdheight=1<CR>:echo ""<CR>
"toggle use color flag
if maparg(",tc") != ""
    silent! unmap ,tc
endif
map ,tc :call <SID>Toggle_String_Output_Color()<CR>

