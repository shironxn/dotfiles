function piw --description 'Run pi from inside a project instead of ~/workspace'
    # ~/workspace holds no project manifest, so pi-lens falls back to inferred
    # settings there: systematic "Cannot find name Buffer" false positives, and
    # the Syncthing-mirrored vault gets scanned on every change. Starting inside
    # a real project removes both.

    set -l base ~/workspace
    set -l cands

    for d in $base/projects/*/ $base/c $base/vault
        test -d "$d"; and set -a cands (basename $d)
    end

    set -l target $argv[1]
    set -l rest

    if test (count $argv) -ge 2
        set rest $argv[2..-1]
    end

    if test -z "$target"
        if not command -q fzf
            echo "piw: fzf is not in PATH. Usage: piw <project>" >&2
            printf '  %s\n' $cands >&2
            return 1
        end
        set target (printf '%s\n' $cands | fzf --prompt='project> ' --height=40% --reverse)
        if test -z "$target"
            return 1
        end
        set rest $argv
    end

    set -l dir
    if test -d "$target"
        set dir (realpath "$target")
    else
        for c in $base/projects/$target $base/$target
            if test -d "$c"
                set dir (realpath "$c")
                break
            end
        end
    end

    if test -z "$dir"
        echo "piw: '$target' not found in $base/projects/ or $base/" >&2
        printf '  %s\n' $cands >&2
        return 1
    end

    echo "piw -> $dir" >&2
    cd "$dir"; and pi $rest
end
