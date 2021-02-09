function _pnpm_install --on-event pnpm_install
  echo (set_color magenta)Installing pnpm(set_color normal)

  set --local global_dir (command npm get global-dir)
  set --local store_dir (command npm get store-dir)

  contains $global_dir '' undefined && set global_dir '~/.local/share/pnpm-global'
  contains $store_dir '' undefined && set store_dir '~/.local/share/pnpm-store'

  read --shell --command="$global_dir" --prompt="set_color green; echo -n PNPM global-dir; set_color normal; echo -n ': ';" global_dir && eval "set global_dir (realpath $global_dir)" && command npm set global-dir "$global_dir"
  read --shell --command="$store_dir" --prompt="set_color green; echo -n PNPM store-dir; set_color normal; echo -n ': ';" store_dir && eval "set store_dir (realpath $store_dir)" && command npm set store-dir "$store_dir"

  # prepend global-dir to PATH to expose global binaries
  contains $global_dir/bin $fish_user_paths || set --prepend --universal fish_user_paths $global_dir/bin

  # install pnpm to temporary dir, link pnpm/pnpx to global bin dir
  set --local tmpdir (mktemp -d)
  curl --location --progress-bar https://raw.githubusercontent.com/pnpm/self-installer/master/install.js | PNPM_DEST=$tmpdir PNPM_BIN_DEST=$global_dir/bin node

  # reinstall pnpm with pnpm, at this time it will install to the correct dir
  PATH=$global_dir/bin:$PATH command pnpm install --global pnpm

  # clean up
  rm -rf $tmpdir
  rm $global_dir/bin/*.cmd
end

function _pnpm_uninstall --on-event pnpm_uninstall
  echo (set_color magenta)Uninstalling pnpm(set_color normal)

  set --local global_dir (command npm get global-dir)
  set --local store_dir (command npm get store-dir)

  test -d "$global_dir" && _pnpm_confirm (set_color red)Delete (set_color --underline)$global_dir(set_color normal)(set_color red)\?(set_color normal) && rm -rf $global_dir
  test -d "$store_dir" && _pnpm_confirm (set_color red)Delete (set_color --underline)$store_dir(set_color normal)(set_color red)\?(set_color normal) && rm -rf "$store_dir"

  # clean up PATH
  switch $global_dir
  case '' undefined
  case \*
    set --local i (contains --index $global_dir/bin $fish_user_paths) && set --erase fish_user_paths[$i]
  end

  # clean up config
  command npm config delete global-dir
  command npm config delete store-dir
end

function _pnpm_confirm
  while true
    read --prompt-str="$argv [y/N] " --local answer
    switch $answer
    case Y y
      return 0
    case '' N n
      return 1
    end
  end
end
