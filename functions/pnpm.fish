function pnpm
  set --local args $argv
  argparse --ignore-unknown 'g/global' -- $argv
  if set --query _flag_global; and contains argv[1] i install add
    # prepend PATH with global-dir so global binaries will be linked correctly
    PATH=(command npm get global-dir)/bin:$PATH command pnpm $args
  else
    command pnpm $args
  end
end
