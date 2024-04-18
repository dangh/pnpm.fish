set -gx PNPM_HOME ~/.pnpm
set -g PNPM_DEFAULT_GLOBAL_DIR ~/.local/share/pnpm-global
set -g PNPM_DEFAULT_STORE_DIR ~/.local/share/pnpm-store

function pnpm
    set -l non_opts
    for arg in $argv
        if string match -q -e -v -- '-*' $arg
            set -a non_opts $arg
        end
    end
    if test "$non_opts[2]" = pnpm
        switch "$non_opts[1]"
            case i install
                _pnpm_ensure_deps install
                _pnpm_install_latest
                set PATH $PNPM_HOME:$PATH
                return
            case up update upgrade
                _pnpm_ensure_deps update
                _pnpm_install_latest
                return
            case rm uninstall un
                _pnpm_uninstall
                return
        end
    end

    test -x $PNPM_HOME/pnpm || begin
        if _pnpm_confirm -y 'pnpm not found. Install now?'
            pnpm i -g pnpm
        else
            return 1
        end
    end

    set -l args $argv
    argparse -i g/global -- $argv

    if set -q _flag_global
        PATH=(nvm-which 20)/bin:$PATH $PNPM_HOME/pnpm $args
    else if type -q node && test (node -v | string match -r '\d+') -lt 16
        PATH=(nvm-which 20)/bin:$PATH $PNPM_HOME/pnpm -s dlx pnpm@7 $args
    else
        PATH=(nvm-which 20)/bin:$PATH $PNPM_HOME/pnpm $args
    end
end

function _pnpm_ensure_deps -a action
    set -l deps jorgebucaran/nvm.fish dangh/nvm-which.fish
    switch "$action"
        case install
            set -l missing_deps
            for dep in $deps
                fisher ls | grep -q $dep || set -a missing_deps $dep
            end
            test -n "$missing_deps" && fisher install $missing_deps
        case update
            fisher update $deps
    end
end

function _pnpm_install_latest
    echo (set_color magenta)Installing pnpm@latest(set_color normal)

    set -l global_dir (command npm config get global-dir)
    set -l store_dir (command npm config get store-dir)

    contains "$global_dir" '' undefined && begin
        set global_dir $PNPM_DEFAULT_GLOBAL_DIR
        command npm config set global-dir $global_dir
    end
    contains "$store_dir" '' undefined && begin
        set store_dir $PNPM_DEFAULT_STORE_DIR
        command npm config set store-dir $store_dir
    end

    # prepend global-dir to PATH to expose global binaries
    fish_add_path $global_dir/bin

    # install pnpm
    curl --location --progress-bar https://get.pnpm.io/install.sh | sh -
end

function _pnpm_uninstall
    echo (set_color magenta)Uninstalling pnpm(set_color normal)

    begin
        rm -r $PNPM_HOME
        sed -I '' '/^# pnpm$/,/^# pnpm end$/d' ~/.config/fish/config.fish
        _pnpm_remove_path $PNPM_HOME
    end 2>/dev/null

    set -l global_dir (command npm config get global-dir)
    if not contains "$global_dir" '' undefined
        command npm config delete global-dir
    else
        set global_dir $PNPM_DEFAULT_GLOBAL_DIR
    end
    test -d "$global_dir" && _pnpm_confirm -n (set_color red)"Delete "(set_color -u)"$global_dir"(set_color normal)(set_color red)"?"(set_color normal) && rm -rf "$global_dir"
    switch $global_dir
        case '' undefined
        case \*
            _pnpm_remove_path $global_dir/bin
    end

    set -l global_bin_dir (command npm config get global-bin-dir)
    if not contains "$global_bin_dir" '' undefined
        command npm config delete global-bin-dir
        test -d "$global_bin_dir" && rm -rf "$global_bin_dir"
    end

    set -l store_dir (command npm config get store-dir)
    if not contains "$store_dir" '' undefined
        command npm config delete store-dir
    else
        set store_dir $PNPM_DEFAULT_STORE_DIR
    end
    test -d "$store_dir" && _pnpm_confirm -n (set_color red)'Delete '(set_color -u)"$store_dir"(set_color normal)(set_color red)'?'(set_color normal) && rm -rf "$store_dir"
end

function _pnpm_confirm
    argparse -i y/yes n/no -- $argv

    set -l default_answer y
    if set -q _flag_yes
        set default_answer y
    else if set -q _flag_no
        set default_answer n
    end

    switch "$default_answer"
        case y
            while true
                read -P "$argv [Y/n] " -l answer
                switch $answer
                    case Y y ''
                        return 0
                    case N n
                        return 1
                end
            end
        case n
            while true
                read -P "$argv [y/N] " -l answer
                switch $answer
                    case Y y
                        return 0
                    case N n ''
                        return 1
                end
            end
    end
end

function _pnpm_remove_path -a path
    test -n "$path" || return 1
    while contains $path $fish_user_paths
        set i (contains -i $path $fish_user_paths)
        set -e fish_user_paths[$i]
    end
end
