if empty('<args>')
  echo "Error: Command required. Use :Pr [create|merge|view]"
  echo "Commands:"
  echo "  create     Create a new pull request"
  echo "  merge      Merge a pull request"
  echo "  view       View pull request files in browser"
elseif '<args>' =~ '^create'
  execute 'terminal ' . g:pr_script . ' create'
elseif '<args>' =~ '^merge'
  let merge_args = substitute('<args>', '^merge\s*', '', '')
  execute 'terminal ' . g:pr_script . ' merge ' . merge_args
elseif '<args>' =~ '^view'
  execute '!' . g:pr_script . ' view'
else
  echoerr "Invalid command. Use :Pr [create|merge|view]"
endif
