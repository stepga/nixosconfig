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

-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require('lspconfig')

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
end

local servers = { 'nil_ls' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  preselect = cmp.PreselectMode.None,
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}
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
