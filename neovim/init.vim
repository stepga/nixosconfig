" +----------------------------------------------------------------------------+
" |                            GENERAL SETTINGS                                |
" +----------------------------------------------------------------------------+
"
" ignorecase+smartcase: case sensitive only if uppercase letters given
set ignorecase
set smartcase

" <Leader> (for userdefined commands) is now ',' instead of '\'
let mapleader = ","

" show cursor-line & -column
set cursorcolumn
set cursorline
"
" show tabs, trailing spaces, wrapped lines
set listchars=tab:→\ ,trail:?
set list
set showbreak=↪\

" show row-numbers
set number

"" display tabs as 4 spaces
"set tabstop=4
"set shiftwidth=4
"
"autocmd BufEnter *.nix execute 'set tabstop=2'
"autocmd BufEnter *.nix execute 'set shiftwidth=2'
"autocmd BufEnter *.nix execute 'set expandtab'

" +----------------------------------------------------------------------------+
" |                            PLUGINS                                         |
" +----------------------------------------------------------------------------+

" disable barbar auto-setup
let g:barbar_auto_setup = v:false

lua << END
require('barbar').setup {
  icons = { filetype = { enabled = false } }
};
require('nvim-treesitter.configs').setup {
  highlight = { enable = true },
  indent = { enable = true }
}
require'lspconfig'.nil_ls.setup{}
END

" vim-signify: default updatetime (4000 ms) is too slow for async update
set updatetime=100

" +----------------------------------------------------------------------------+
" |                            OWN FUNCTIONS                                   |
" +----------------------------------------------------------------------------+

" make text copy- & pastable despite all plugin sidebars/columns
function! CopyPaste()
  if &paste ==# "nopaste"
    set nolist
    set nonumber
    set paste
    LspStop
  else
    set listchars=tab:→\ ,trail:?
    set list
    set number
    set nopaste
    LspStart
  endif
endfunction

" toggle the colorcolumn
function! ToggleColorColumn()
  if &colorcolumn ==# ""
    set colorcolumn=+1
  else
    set colorcolumn=
  endif
endfunction
highlight ColorColumn ctermbg=0 guibg=#333333
" set default textwidth if not set yet
autocmd BufEnter * execute 'setlocal textwidth=80'
" initially call enable the colorcolumn if possible
autocmd BufEnter * :call ToggleColorColumn()

" delete the trailing whitespaces
function! DeleteTrailingWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc

" +----------------------------------------------------------------------------+
" |                            MAPPINGS                                        |
" +----------------------------------------------------------------------------+

nnoremap <Leader>cp :call CopyPaste()<CR>
nnoremap <Leader>cc :call ToggleColorColumn()<CR>
nnoremap <Leader>dw :call DeleteTrailingWS()<CR>

" redraw the screen and remove any search highlights.
" <silent> -> don't show mapped command in status-line
nnoremap <silent> <Leader>ll :nohl <Esc>

" fzf.vim :Buffers
nnoremap <silent> <Leader>b :Buffers <Esc>

" move among buffers with CTRL
" OR use fzf's :Buffers
map <C-J> :bnext<CR>
map <C-K> :bprev<CR>

" close the current buffer
nnoremap <Leader>q :bd<CR>
