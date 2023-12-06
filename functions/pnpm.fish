function pnpm
  set -l args $argv
  argparse -i 'g/global' -- $argv
  if set -q _flag_global
    # prepend PATH with global-dir so global binaries will be linked correctly
    PATH=(nvm-which 20)/bin:(command npm get global-dir)/bin:$PATH command pnpm $args
  else
    PATH=(nvm-which 20)/bin:$PATH command pnpm $args
  end
end
