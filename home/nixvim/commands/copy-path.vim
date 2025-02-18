if empty('<args>')
  let @+ = getcwd()
  echo "Copied absolute working directory path to clipboard"
elseif '<args>' == 'abs'
  let @+ = getcwd()
  echo "Copied absolute working directory path to clipboard"
elseif '<args>' == 'file'
  let @+ = expand('%:p')
  echo "Copied absolute file path to clipboard"
elseif '<args>' == 'git'
  let git_root = system('git rev-parse --show-toplevel 2>/dev/null')
  if v:shell_error
    echoerr "Not in a git repository"
  else
    let current_path = expand('%:p')
    let git_root = substitute(git_root, '\n\+$', '', '')
    let relative_path = substitute(current_path, '^' . escape(git_root, '/') . '/', '', '')
    let @+ = relative_path
    echo "Copied git-relative file path to clipboard"
  endif
else
  echoerr "Invalid argument. Use :CopyPath [abs|file|git]"
endif
