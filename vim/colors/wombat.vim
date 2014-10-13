set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = "wombat"


" Vim >= 7.0 specific colors
if version >= 700
  hi CursorLine guibg=#2d2d2d
  hi CursorColumn guibg=#2d2d2d
  hi MatchParen guifg=#f6f3e8 guibg=#857b6f gui=bold
  hi Pmenu      guifg=#f6f3e8 guibg=#444444
  hi PmenuSel   guifg=#000000 guibg=#cae682
endif

" General colors
"hi Cursor      guifg=NONE    guibg=#656565 gui=none
hi Cursor       guifg=#333333 guibg=#ffff00 gui=none
hi Normal       guifg=#f6f3e8 guibg=#242424 gui=none
hi NonText      guifg=#808080 guibg=#303030 gui=none
hi LineNr       guifg=#857b6f guibg=#000000 gui=none
hi StatusLine   guifg=#f6f3e8 guibg=#444444 gui=none
hi StatusLineNC guifg=#857b6f guibg=#444444 gui=none
hi VertSplit    guifg=#444444 guibg=#444444 gui=none
hi Folded       guibg=#384048 guifg=#a0a8b0 gui=none
hi FoldColumn   guifg=#808080 guibg=#303030 gui=none
hi Title        guifg=#f6f3e8 guibg=NONE    gui=bold
hi Visual       guifg=#f6f3e8 guibg=#444444 gui=none
hi SpecialKey   guifg=#808080 guibg=#343434 gui=none

" Syntax highlighting
" cyan
hi Operator     guifg=#A3D6DC
" grey
hi Comment      guifg=#99968b gui=none      
" grey on yellow
hi Todo         guifg=#8f8f8f guibg=#FADD39 gui=none      
" red
hi Constant     guifg=#e5786d gui=none      
hi PreProc      guifg=#e5786d gui=none
hi Number       guifg=#e5786d gui=none
" green
hi String       guifg=#95e454               
"hi Identifier   guifg=#cae682 gui=none
" pink
hi Identifier   guifg=#FA8ED1 gui=none      
"hi Function     guifg=#cae682 gui=none
" yellow
hi Function     guifg=#F5DE82 gui=none
"hi Type         guifg=#cae682 gui=none
" orangeish
hi Type         guifg=#E8BE6F gui=none
" blue
hi Statement    guifg=#8ac6f2 gui=none
" more blue
hi Keyword      guifg=#45A2E6 gui=none
" pale pink
hi Special      guifg=#F2C4EE gui=none

hi diffAdded    guifg=#95e454               
hi diffRemoved  guifg=#e5786d
hi diffLine     guifg=#99968b

