" vim syntax file for Eo

if exists("b:current_syntax")
    finish
endif

" keywords
" Eo doesn't really have keywords, but we can highlight important words.
syn keyword eoKeywords def defvar if when exec

" matches
syn match eoComment '--.*$'
syn match eoDefinition '\!\S\+'
syn match eoString '\".*\"'
syn match eoVariable '\$\S\+'

" regions
" syn region eoCodeBlock start="{" end="}" fold transparent
" syn region eoList start="[" end="]" fold transparent

let b:current_syntax = "eo"

hi def link eoComment Comment
hi def link eoKeywords Identifier
hi def link eoDefinition Type
hi def link eoString String
hi def link eoVariable PreProc

