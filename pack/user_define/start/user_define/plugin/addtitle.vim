"addtitle Function{{{
function AddTitle()
    call append(0,"//=============================================================================")
    call append(1,"//")
    call append(2,"// Author: Jelly Email: 823300630@qq.com")
    call append(3,"//")
    call append(4,"// Personal Website: https://tyxiumud.github.io/")
    call append(5,"//")
    call append(6,"// Last modified: ".strftime("%Y-%m-%d %H:%M"))
    call append(7,"//")
    call append(8,"// Filename: ".expand("%:t"))
    call append(9,"//")
    call append(10,"// Description: ")
    call append(11,"//")
    call append(12,"//=============================================================================")
    call append(13,"module ".toupper(expand("%:t:r"))."(")
    call append(14,"")
    call append(15,");")
    call append(16,"//*********************define parameter and internal signals*********************")
    call append(17,"")
    call append(18,"//*****************************main code****************************************")
    call append(19,"")
    call append(20,"endmodule")
    echohl WarningMsg | echo "Successful in adding the copyright." | echohl None
endf

"更新最近修改时间和文件名
function UpdateTitle()
    " 保存当前光标位置
    let save_cursor = getpos('.')

    " 更新 Last modified 行（匹配 // 开头的行）
    execute '/\/\/\s*Last modified:/s@:.*$@\=strftime(":\t%Y-%m-%d %H:%M")@'
    " 更新 Filename 行（匹配 // 开头的行）
    execute '/\/\/\s*Filename:/s@:.*$@\=":\t\t".expand("%:t")@'
    execute "noh"

    " 恢复光标位置
    call setpos('.', save_cursor)
    echohl WarningMsg | echo "Successful in updating the copy right." | echohl None
endfunction

"判断前10行代码里面，是否有Last modified这个单词，
"如果没有的话，代表没有添加过作者信息，需要新添加；
"如果有的话，那么只需要更新即可
function TitleDet()
    let n = 1
    " 检查前10行（含第10行）
    while n <= 10
        let line = getline(n)
        " 匹配 // 或 # 开头的 Last modified 行（兼容新旧格式）
        if line =~ '^\(\/\/\|#\)\s*\S*Last\smodified:\S*.*$'
            call UpdateTitle()
            return
        endif
        let n = n + 1
    endwhile
    call AddTitle()
endfunction
"}}}
