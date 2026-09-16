map <buffer> ac <Plug>(PythonsenseOuterClassTextObject)
map <buffer> ic <Plug>(PythonsenseInnerClassTextObject)
map <buffer> af <Plug>(PythonsenseOuterFunctionTextObject)
map <buffer> if <Plug>(PythonsenseInnerFunctionTextObject)
map <buffer> ad <Plug>(PythonsenseOuterDocStringTextObject)
map <buffer> id <Plug>(PythonsenseInnerDocStringTextObject)

map <buffer> ]] <Plug>(PythonsenseStartOfNextPythonClass)
map <buffer> ][ <Plug>(PythonsenseEndOfPythonClass)
map <buffer> [[ <Plug>(PythonsenseStartOfPythonClass)
map <buffer> [] <Plug>(PythonsenseEndOfPreviousPythonClass)
map <buffer> m <Plug>(PythonsenseStartOfNextPythonFunction)
map <buffer> ]M <Plug>(PythonsenseEndOfPythonFunction)
map <buffer> [m <Plug>(PythonsenseStartOfPythonFunction)
map <buffer> M <Plug>(PythonsenseEndOfPreviousPythonFunction)

map <buffer> g: <Plug>(PythonsensePyWhere)[

nmap <buffer> <silent> <leader>_ <Plug>(pydocstring)

let b:undo_ftplugin = get(b:, "undo_ftplugin", "")
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> ac\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> ic\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> af\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> if\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> ad\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> id\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> ]]\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> ][\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> [[\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> []\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> m\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> ]M\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> [m\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> M\'"
let b:undo_ftplugin .= " | silent! execute \'unmap <buffer> g:\'"
let b:undo_ftplugin .= " | silent! execute \'nunmap <buffer> <leader>_\'"
