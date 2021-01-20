function pnpm
  ! command type pnpm >/dev/null 2>&1 && begin
    set pnpm_global_dir (npm get global-dir)
    test -n "$pnpm_global_dir" || begin
      npm set global-dir ~/.local/share/pnpm-global
      set pnpm_global_dir ~/.local/share/pnpm-global
    end
    set pnpm_store_dir (npm get store-dir)
    test -n "$pnpm_store_dir" || begin
      npm set store-dir ~/.local/share/pnpm-store
    end
    ! contains $pnpm_global_dir/bin $fish_user_paths && set --prepend fish_user_paths $pnpm_global_dir/bin
    set --local tmpdir (mktemp -d)
    curl -L https://raw.githubusercontent.com/pnpm/self-installer/master/install.js | PNPM_DEST=$tmpdir PNPM_BIN_DEST=$pnpm_global_dir/bin node
    PATH=$pnpm_global_dir/bin:$PATH command pnpm i -g pnpm
    rm -rf $tmpdir
  end
  if contains -- -g $argv
    PATH=(npm get global-dir)/bin:$PATH command pnpm $argv
  else
    command pnpm $argv
  end
end
