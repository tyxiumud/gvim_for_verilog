nnoremap <leader>tt :call Sum(x,y)<cr>
nnoremap <leader>ss :source %<cr>
function! IcecreamInitialize()
python << EOF
class StrawberryIcecream:
        def __call__(self):
                print 'TEST ME'
EOF
endfunction

function! Sum(x, y)
    return a:x + a:y
endfunction

let x = 2
let y = 3
let ret = Sum(x,y)



