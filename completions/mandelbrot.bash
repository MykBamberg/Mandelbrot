_mandelbrot() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-y --height -x --width -f --foreground -b --background -p --posterization -r --root -a --bounds -q --hash -h --help -t --ascii -i --iterations -o --output"

    case "${prev}" in
        -y|--height|-x|--width)
            COMPREPLY=( $(compgen -W "10 20 30 40 50 60 70 80" -- ${cur}) )
            return 0
            ;;
        -f|--foreground|-b|--background)
            COMPREPLY=( $(compgen -W "000000 ffffff ff0000 00ff00 0000ff" -- ${cur}) )
            return 0
            ;;
        -r|--root)
            COMPREPLY=( $(compgen -W "1.25 1.5 2 2.5 3" -- ${cur}) )
            return 0
            ;;
        -p|--posterization)
            COMPREPLY=( $(compgen -W "5 8 10 15 20" -- ${cur}) )
            return 0
            ;;
        -a|--bounds)
            COMPREPLY=( $(compgen -W "-1.5,-0.5,-0.75,0 -2,-2,2,2" -- ${cur}) )
            return 0
            ;;
        -i|--iterations)
            COMPREPLY=( $(compgen -W "32 64 128 256 512 1024" -- ${cur}) )
            return 0
            ;;
        -o|--output)
            _filedir
            if [ ${#COMPREPLY[@]} -eq 0 ]; then
                if [[ "$cur" != *\.* ]]; then
                    COMPREPLY=( $(compgen -W "output.bmp mandelbrot.bmp" -- ${cur}) )
                fi
            fi
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
    esac
}

complete -F _mandelbrot mandelbrot
