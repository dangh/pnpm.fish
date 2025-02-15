set -gx PNPM_HOME ~/.pnpm
set -g PNPM_GLOBAL_DIR ~/.local/share/pnpm-global

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
                _pnpm_install_latest
                set PATH $PNPM_HOME:$PATH # source pnpm after install
                return
            case up update upgrade
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

    $PNPM_HOME/pnpm $argv
end

function _pnpm_install_latest
    echo (set_color magenta)Installing pnpm@latest(set_color normal)

    # prepend global-dir to PATH to expose global binaries
    mkdir -p $PNPM_GLOBAL_DIR/bin
    fish_add_path $PNPM_GLOBAL_DIR/bin

    # install pnpm
    curl --location --progress-bar https://get.pnpm.io/install.sh | sh -

    # install nodejs
    $PNPM_HOME/pnpm env use -g latest
end

function _pnpm_uninstall
    echo (set_color magenta)Uninstalling pnpm(set_color normal)

    begin
        rm -r $PNPM_HOME
        sed -I '' '/^# pnpm$/,/^# pnpm end$/d' ~/.config/fish/config.fish
        _pnpm_remove_path $PNPM_HOME
    end 2>/dev/null

    _pnpm_remove_path $PNPM_GLOBAL_DIR/bin

    test -d "$PNPM_GLOBAL_DIR" && _pnpm_confirm -n (set_color red)"Delete "(set_color -u)"$PNPM_GLOBAL_DIR"(set_color normal)(set_color red)"?"(set_color normal) && rm -rf "$PNPM_GLOBAL_DIR"
    test -d "$PNPM_HOME" && _pnpm_confirm -n (set_color red)'Delete '(set_color -u)"$PNPM_HOME"(set_color normal)(set_color red)'?'(set_color normal) && rm -rf "$PNPM_HOME"
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
