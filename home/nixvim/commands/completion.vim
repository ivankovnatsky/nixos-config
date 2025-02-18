function! PrComplete(ArgLead, CmdLine, CursorPos)
  let l:options = ['create', 'merge', 'view']
  return join(filter(l:options, 'v:val =~ "^" . a:ArgLead'), "\n")
endfunction

function! CopyPathComplete(ArgLead, CmdLine, CursorPos)
  let l:options = ['abs', 'file', 'git']
  return join(filter(l:options, 'v:val =~ "^" . a:ArgLead'), "\n")
endfunction
