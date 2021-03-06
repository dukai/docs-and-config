# bash/zsh completion support for core Git.
#
# Copyright (C) 2006,2007 Shawn O. Pearce <spearce@spearce.org>
# Conceptually based on gitcompletion (http://gitweb.hawaga.org.uk/).
# Distributed under the GNU General Public License, version 2.0.
#
# The contained completion routines provide support for completing:
#
#    *) local and remote branch names
#    *) local and remote tag names
#    *) .git/remotes file names
#    *) git 'subcommands'
#    *) git email aliases for git-send-email
#    *) tree paths within 'ref:path/to/file' expressions
#    *) file paths within current working directory and index
#    *) common --long-options
#
# To use these routines:
#
#    1) Copy this file to somewhere (e.g. ~/.git-completion.bash).
#    2) Add the following line to your .bashrc/.zshrc:
#        source ~/.git-completion.bash
#    3) Consider changing your PS1 to also show the current branch,
#       see git-prompt.sh for details.
#
# If you use complex aliases of form '!f() { ... }; f', you can use the null
# command ':' as the first command in the function body to declare the desired
# completion style.  For example '!f() { : git commit ; ... }; f' will
# tell the completion to use commit completion.  This also works with aliases
# of form "!sh -c '...'".  For example, "!sh -c ': git commit ; ... '".

case "$COMP_WORDBREAKS" in
*:*) : great ;;
*)   COMP_WORDBREAKS="$COMP_WORDBREAKS:"
esac

# __gitdir accepts 0 or 1 arguments (i.e., location)
# returns location of .git repo
__gitdir ()
{
    if [ -z "${1-}" ]; then
        if [ -n "${__git_dir-}" ]; then
            echo "$__git_dir"
        elif [ -n "${GIT_DIR-}" ]; then
            test -d "${GIT_DIR-}" || return 1
            echo "$GIT_DIR"
        elif [ -d .git ]; then
            echo .git
        else
            git rev-parse --git-dir 2>/dev/null
        fi
    elif [ -d "$1/.git" ]; then
        echo "$1/.git"
    else
        echo "$1"
    fi
}

# The following function is based on code from:
#
#   bash_completion - programmable completion functions for bash 3.2+
#
#   Copyright © 2006-2008, Ian Macdonald <ian@caliban.org>
#             © 2009-2010, Bash Completion Maintainers
#                     <bash-completion-devel@lists.alioth.debian.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#   The latest version of this software can be obtained here:
#
#   http://bash-completion.alioth.debian.org/
#
#   RELEASE: 2.x

# This function can be used to access a tokenized list of words
# on the command line:
#
#   __git_reassemble_comp_words_by_ref '=:'
#   if test "${words_[cword_-1]}" = -w
#   then
#       ...
#   fi
#
# The argument should be a collection of characters from the list of
# word completion separators (COMP_WORDBREAKS) to treat as ordinary
# characters.
#
# This is roughly equivalent to going back in time and setting
# COMP_WORDBREAKS to exclude those characters.  The intent is to
# make option types like --date=<type> and <rev>:<path> easy to
# recognize by treating each shell word as a single token.
#
# It is best not to set COMP_WORDBREAKS directly because the value is
# shared with other completion scripts.  By the time the completion
# function gets called, COMP_WORDS has already been populated so local
# changes to COMP_WORDBREAKS have no effect.
#
# Output: words_, cword_, cur_.

__git_reassemble_comp_words_by_ref()
{
    local exclude i j first
    # Which word separators to exclude?
    exclude="${1//[^$COMP_WORDBREAKS]}"
    cword_=$COMP_CWORD
    if [ -z "$exclude" ]; then
        words_=("${COMP_WORDS[@]}")
        return
    fi
    # List of word completion separators has shrunk;
    # re-assemble words to complete.
    for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++)); do
        # Append each nonempty word consisting of just
        # word separator characters to the current word.
        first=t
        while
            [ $i -gt 0 ] &&
            [ -n "${COMP_WORDS[$i]}" ] &&
            # word consists of excluded word separators
            [ "${COMP_WORDS[$i]//[^$exclude]}" = "${COMP_WORDS[$i]}" ]
        do
            # Attach to the previous token,
            # unless the previous token is the command name.
            if [ $j -ge 2 ] && [ -n "$first" ]; then
                ((j--))
            fi
            first=
            words_[$j]=${words_[j]}${COMP_WORDS[i]}
            if [ $i = $COMP_CWORD ]; then
                cword_=$j
            fi
            if (($i < ${#COMP_WORDS[@]} - 1)); then
                ((i++))
            else
                # Done.
                return
            fi
        done
        words_[$j]=${words_[j]}${COMP_WORDS[i]}
        if [ $i = $COMP_CWORD ]; then
            cword_=$j
        fi
    done
}

if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
_get_comp_words_by_ref ()
{
    local exclude cur_ words_ cword_
    if [ "$1" = "-n" ]; then
        exclude=$2
        shift 2
    fi
    __git_reassemble_comp_words_by_ref "$exclude"
    cur_=${words_[cword_]}
    while [ $# -gt 0 ]; do
        case "$1" in
        cur)
            cur=$cur_
            ;;
        prev)
            prev=${words_[$cword_-1]}
            ;;
        words)
            words=("${words_[@]}")
            ;;
        cword)
            cword=$cword_
            ;;
        esac
        shift
    done
}
fi

__gitcompappend ()
{
    local x i=${#COMPREPLY[@]}
    for x in $1; do
        if [[ "$x" == "$3"* ]]; then
            COMPREPLY[i++]="$2$x$4"
        fi
    done
}

__gitcompadd ()
{
    COMPREPLY=()
    __gitcompappend "$@"
}

# Generates completion reply, appending a space to possible completion words,
# if necessary.
# It accepts 1 to 4 arguments:
# 1: List of possible completion words.
# 2: A prefix to be added to each possible completion word (optional).
# 3: Generate possible completion matches for this word (optional).
# 4: A suffix to be appended to each possible completion word (optional).
__gitcomp ()
{
    local cur_="${3-$cur}"

    case "$cur_" in
    --*=)
        ;;
    *)
        local c i=0 IFS=$' \t\n'
        for c in $1; do
            c="$c${4-}"
            if [[ $c == "$cur_"* ]]; then
                case $c in
                --*=*|*.) ;;
                *) c="$c " ;;
                esac
                COMPREPLY[i++]="${2-}$c"
            fi
        done
        ;;
    esac
}

# Variation of __gitcomp_nl () that appends to the existing list of
# completion candidates, COMPREPLY.
__gitcomp_nl_append ()
{
    local IFS=$'\n'
    __gitcompappend "$1" "${2-}" "${3-$cur}" "${4- }"
}

# Generates completion reply from newline-separated possible completion words
# by appending a space to all of them.
# It accepts 1 to 4 arguments:
# 1: List of possible completion words, separated by a single newline.
# 2: A prefix to be added to each possible completion word (optional).
# 3: Generate possible completion matches for this word (optional).
# 4: A suffix to be appended to each possible completion word instead of
#    the default space (optional).  If specified but empty, nothing is
#    appended.
__gitcomp_nl ()
{
    COMPREPLY=()
    __gitcomp_nl_append "$@"
}

# Generates completion reply with compgen from newline-separated possible
# completion filenames.
# It accepts 1 to 3 arguments:
# 1: List of possible completion filenames, separated by a single newline.
# 2: A directory prefix to be added to each possible completion filename
#    (optional).
# 3: Generate possible completion matches for this word (optional).
__gitcomp_file ()
{
    local IFS=$'\n'

    # XXX does not work when the directory prefix contains a tilde,
    # since tilde expansion is not applied.
    # This means that COMPREPLY will be empty and Bash default
    # completion will be used.
    __gitcompadd "$1" "${2-}" "${3-$cur}" ""

    # use a hack to enable file mode in bash < 4
    compopt -o filenames +o nospace 2>/dev/null ||
    compgen -f /non-existing-dir/ > /dev/null
}

# Execute 'git ls-files', unless the --committable option is specified, in
# which case it runs 'git diff-index' to find out the files that can be
# committed.  It return paths relative to the directory specified in the first
# argument, and using the options specified in the second argument.
__git_ls_files_helper ()
{
    if [ "$2" == "--committable" ]; then
        git -C "$1" diff-index --name-only --relative HEAD
    else
        # NOTE: $2 is not quoted in order to support multiple options
        git -C "$1" ls-files --exclude-standard $2
    fi 2>/dev/null
}


# __git_index_files accepts 1 or 2 arguments:
# 1: Options to pass to ls-files (required).
# 2: A directory path (optional).
#    If provided, only files within the specified directory are listed.
#    Sub directories are never recursed.  Path must have a trailing
#    slash.
__git_index_files ()
{
    local dir="$(__gitdir)" root="${2-.}" file

    if [ -d "$dir" ]; then
        __git_ls_files_helper "$root" "$1" |
        while read -r file; do
            case "$file" in
            ?*/*) echo "${file%%/*}" ;;
            *) echo "$file" ;;
            esac
        done | sort | uniq
    fi
}

__git_heads ()
{
    local dir="$(__gitdir)"
    if [ -d "$dir" ]; then
        git --git-dir="$dir" for-each-ref --format='%(refname:short)' \
            refs/heads
        return
    fi
}

__git_tags ()
{
    local dir="$(__gitdir)"
    if [ -d "$dir" ]; then
        git --git-dir="$dir" for-each-ref --format='%(refname:short)' \
            refs/tags
        return
    fi
}

# __git_refs accepts 0, 1 (to pass to __gitdir), or 2 arguments
# presence of 2nd argument means use the guess heuristic employed
# by checkout for tracking branches
__git_refs ()
{
    local i hash dir="$(__gitdir "${1-}")" track="${2-}"
    local format refs pfx
    if [ -d "$dir" ]; then
        case "$cur" in
        refs|refs/*)
            format="refname"
            refs="${cur%/*}"
            track=""
            ;;
        *)
            [[ "$cur" == ^* ]] && pfx="^"
            for i in HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD; do
                if [ -e "$dir/$i" ]; then echo $pfx$i; fi
            done
            format="refname:short"
            refs="refs/tags refs/heads refs/remotes"
            ;;
        esac
        git --git-dir="$dir" for-each-ref --format="$pfx%($format)" \
            $refs
        if [ -n "$track" ]; then
            # employ the heuristic used by git checkout
            # Try to find a remote branch that matches the completion word
            # but only output if the branch name is unique
            local ref entry
            git --git-dir="$dir" for-each-ref --shell --format="ref=%(refname:short)" \
                "refs/remotes/" | \
            while read -r entry; do
                eval "$entry"
                ref="${ref#*/}"
                if [[ "$ref" == "$cur"* ]]; then
                    echo "$ref"
                fi
            done | sort | uniq -u
        fi
        return
    fi
    case "$cur" in
    refs|refs/*)
        git ls-remote "$dir" "$cur*" 2>/dev/null | \
        while read -r hash i; do
            case "$i" in
            *^{}) ;;
            *) echo "$i" ;;
            esac
        done
        ;;
    *)
        echo "HEAD"
        git for-each-ref --format="%(refname:short)" -- \
            "refs/remotes/$dir/" 2>/dev/null | sed -e "s#^$dir/##"
        ;;
    esac
}

# __git_refs2 requires 1 argument (to pass to __git_refs)
__git_refs2 ()
{
    local i
    for i in $(__git_refs "$1"); do
        echo "$i:$i"
    done
}

# __git_refs_remotes requires 1 argument (to pass to ls-remote)
__git_refs_remotes ()
{
    local i hash
    git ls-remote "$1" 'refs/heads/*' 2>/dev/null | \
    while read -r hash i; do
        echo "$i:refs/remotes/$1/${i#refs/heads/}"
    done
}

__git_remotes ()
{
    local d="$(__gitdir)"
    test -d "$d/remotes" && ls -1 "$d/remotes"
    git --git-dir="$d" remote
}

__git_list_merge_strategies ()
{
    git merge -s help 2>&1 |
    sed -n -e '/[Aa]vailable strategies are: /,/^$/{
        s/\.$//
        s/.*://
        s/^[    ]*//
        s/[     ]*$//
        p
    }'
}

__git_merge_strategies=
# 'git merge -s help' (and thus detection of the merge strategy
# list) fails, unfortunately, if run outside of any git working
# tree.  __git_merge_strategies is set to the empty string in
# that case, and the detection will be repeated the next time it
# is needed.
__git_compute_merge_strategies ()
{
    test -n "$__git_merge_strategies" ||
    __git_merge_strategies=$(__git_list_merge_strategies)
}

__git_complete_revlist_file ()
{
    local pfx ls ref cur_="$cur"
    case "$cur_" in
    *..?*:*)
        return
        ;;
    ?*:*)
        ref="${cur_%%:*}"
        cur_="${cur_#*:}"
        case "$cur_" in
        ?*/*)
            pfx="${cur_%/*}"
            cur_="${cur_##*/}"
            ls="$ref:$pfx"
            pfx="$pfx/"
            ;;
        *)
            ls="$ref"
            ;;
        esac

        case "$COMP_WORDBREAKS" in
        *:*) : great ;;
        *)   pfx="$ref:$pfx" ;;
        esac

        __gitcomp_nl "$(git --git-dir="$(__gitdir)" ls-tree "$ls" 2>/dev/null \
                | sed '/^100... blob /{
                           s,^.*    ,,
                           s,$, ,
                       }
                       /^120000 blob /{
                           s,^.*    ,,
                           s,$, ,
                       }
                       /^040000 tree /{
                           s,^.*    ,,
                           s,$,/,
                       }
                       s/^.*    //')" \
            "$pfx" "$cur_" ""
        ;;
    *...*)
        pfx="${cur_%...*}..."
        cur_="${cur_#*...}"
        __gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
        ;;
    *..*)
        pfx="${cur_%..*}.."
        cur_="${cur_#*..}"
        __gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
        ;;
    *)
        __gitcomp_nl "$(__git_refs)"
        ;;
    esac
}


# __git_complete_index_file requires 1 argument:
# 1: the options to pass to ls-file
#
# The exception is --committable, which finds the files appropriate commit.
__git_complete_index_file ()
{
    local pfx="" cur_="$cur"

    case "$cur_" in
    ?*/*)
        pfx="${cur_%/*}"
        cur_="${cur_##*/}"
        pfx="${pfx}/"
        ;;
    esac

    __gitcomp_file "$(__git_index_files "$1" ${pfx:+"$pfx"})" "$pfx" "$cur_"
}

__git_complete_file ()
{
    __git_complete_revlist_file
}

__git_complete_revlist ()
{
    __git_complete_revlist_file
}

__git_complete_remote_or_refspec ()
{
    local cur_="$cur" cmd="${words[1]}"
    local i c=2 remote="" pfx="" lhs=1 no_complete_refspec=0
    if [ "$cmd" = "remote" ]; then
        ((c++))
    fi
    while [ $c -lt $cword ]; do
        i="${words[c]}"
        case "$i" in
        --mirror) [ "$cmd" = "push" ] && no_complete_refspec=1 ;;
        --all)
            case "$cmd" in
            push) no_complete_refspec=1 ;;
            fetch)
                return
                ;;
            *) ;;
            esac
            ;;
        -*) ;;
        *) remote="$i"; break ;;
        esac
        ((c++))
    done
    if [ -z "$remote" ]; then
        __gitcomp_nl "$(__git_remotes)"
        return
    fi
    if [ $no_complete_refspec = 1 ]; then
        return
    fi
    [ "$remote" = "." ] && remote=
    case "$cur_" in
    *:*)
        case "$COMP_WORDBREAKS" in
        *:*) : great ;;
        *)   pfx="${cur_%%:*}:" ;;
        esac
        cur_="${cur_#*:}"
        lhs=0
        ;;
    +*)
        pfx="+"
        cur_="${cur_#+}"
        ;;
    esac
    case "$cmd" in
    fetch)
        if [ $lhs = 1 ]; then
            __gitcomp_nl "$(__git_refs2 "$remote")" "$pfx" "$cur_"
        else
            __gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
        fi
        ;;
    pull|remote)
        if [ $lhs = 1 ]; then
            __gitcomp_nl "$(__git_refs "$remote")" "$pfx" "$cur_"
        else
            __gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
        fi
        ;;
    push)
        if [ $lhs = 1 ]; then
            __gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
        else
            __gitcomp_nl "$(__git_refs "$remote")" "$pfx" "$cur_"
        fi
        ;;
    esac
}

__git_complete_strategy ()
{
    __git_compute_merge_strategies
    case "$prev" in
    -s|--strategy)
        __gitcomp "$__git_merge_strategies"
        return 0
    esac
    case "$cur" in
    --strategy=*)
        __gitcomp "$__git_merge_strategies" "" "${cur##--strategy=}"
        return 0
        ;;
    esac
    return 1
}

__git_commands () {
    if test -n "${GIT_TESTING_COMMAND_COMPLETION:-}"
    then
        printf "%s" "${GIT_TESTING_COMMAND_COMPLETION}"
    else
        git help -a|egrep '^  [a-zA-Z0-9]'
    fi
}

__git_list_all_commands ()
{
    local i IFS=" "$'\n'
    for i in $(__git_commands)
    do
        case $i in
        *--*)             : helper pattern;;
        *) echo $i;;
        esac
    done
}

__git_all_commands=
__git_compute_all_commands ()
{
    test -n "$__git_all_commands" ||
    __git_all_commands=$(__git_list_all_commands)
}

__git_list_porcelain_commands ()
{
    local i IFS=" "$'\n'
    __git_compute_all_commands
    for i in $__git_all_commands
    do
        case $i in
        *--*)             : helper pattern;;
        applymbox)        : ask gittus;;
        applypatch)       : ask gittus;;
        archimport)       : import;;
        cat-file)         : plumbing;;
        check-attr)       : plumbing;;
        check-ignore)     : plumbing;;
        check-mailmap)    : plumbing;;
        check-ref-format) : plumbing;;
        checkout-index)   : plumbing;;
        column)           : internal helper;;
        commit-tree)      : plumbing;;
        count-objects)    : infrequent;;
        credential)       : credentials;;
        credential-*)     : credentials helper;;
        cvsexportcommit)  : export;;
        cvsimport)        : import;;
        cvsserver)        : daemon;;
        daemon)           : daemon;;
        diff-files)       : plumbing;;
        diff-index)       : plumbing;;
        diff-tree)        : plumbing;;
        fast-import)      : import;;
        fast-export)      : export;;
        fsck-objects)     : plumbing;;
        fetch-pack)       : plumbing;;
        fmt-merge-msg)    : plumbing;;
        for-each-ref)     : plumbing;;
        hash-object)      : plumbing;;
        http-*)           : transport;;
        index-pack)       : plumbing;;
        init-db)          : deprecated;;
        local-fetch)      : plumbing;;
        ls-files)         : plumbing;;
        ls-remote)        : plumbing;;
        ls-tree)          : plumbing;;
        mailinfo)         : plumbing;;
        mailsplit)        : plumbing;;
        merge-*)          : plumbing;;
        mktree)           : plumbing;;
        mktag)            : plumbing;;
        pack-objects)     : plumbing;;
        pack-redundant)   : plumbing;;
        pack-refs)        : plumbing;;
        parse-remote)     : plumbing;;
        patch-id)         : plumbing;;
        prune)            : plumbing;;
        prune-packed)     : plumbing;;
        quiltimport)      : import;;
        read-tree)        : plumbing;;
        receive-pack)     : plumbing;;
        remote-*)         : transport;;
        rerere)           : plumbing;;
        rev-list)         : plumbing;;
        rev-parse)        : plumbing;;
        runstatus)        : plumbing;;
        sh-setup)         : internal;;
        shell)            : daemon;;
        show-ref)         : plumbing;;
        send-pack)        : plumbing;;
        show-index)       : plumbing;;
        ssh-*)            : transport;;
        stripspace)       : plumbing;;
        symbolic-ref)     : plumbing;;
        unpack-file)      : plumbing;;
        unpack-objects)   : plumbing;;
        update-index)     : plumbing;;
        update-ref)       : plumbing;;
        update-server-info) : daemon;;
        upload-archive)   : plumbing;;
        upload-pack)      : plumbing;;
        write-tree)       : plumbing;;
        var)              : infrequent;;
        verify-pack)      : infrequent;;
        verify-tag)       : plumbing;;
        *) echo $i;;
        esac
    done
}

__git_porcelain_commands=
__git_compute_porcelain_commands ()
{
    test -n "$__git_porcelain_commands" ||
    __git_porcelain_commands=$(__git_list_porcelain_commands)
}

# Lists all set config variables starting with the given section prefix,
# with the prefix removed.
__git_get_config_variables ()
{
    local section="$1" i IFS=$'\n'
    for i in $(git --git-dir="$(__gitdir)" config --name-only --get-regexp "^$section\..*" 2>/dev/null); do
        echo "${i#$section.}"
    done
}

__git_pretty_aliases ()
{
    __git_get_config_variables "pretty"
}

__git_aliases ()
{
    __git_get_config_variables "alias"
}

# __git_aliased_command requires 1 argument
__git_aliased_command ()
{
    local word cmdline=$(git --git-dir="$(__gitdir)" \
        config --get "alias.$1")
    for word in $cmdline; do
        case "$word" in
        \!gitk|gitk)
            echo "gitk"
            return
            ;;
        \!*)    : shell command alias ;;
        -*) : option ;;
        *=*)    : setting env ;;
        git)    : git itself ;;
        \(\))   : skip parens of shell function definition ;;
        {)  : skip start of shell helper function ;;
        :)  : skip null command ;;
        \'*)    : skip opening quote after sh -c ;;
        *)
            echo "$word"
            return
        esac
    done
}

# __git_find_on_cmdline requires 1 argument
__git_find_on_cmdline ()
{
    local word subcommand c=1
    while [ $c -lt $cword ]; do
        word="${words[c]}"
        for subcommand in $1; do
            if [ "$subcommand" = "$word" ]; then
                echo "$subcommand"
                return
            fi
        done
        ((c++))
    done
}

# Echo the value of an option set on the command line or config
#
# $1: short option name
# $2: long option name including =
# $3: list of possible values
# $4: config string (optional)
#
# example:
# result="$(__git_get_option_value "-d" "--do-something=" \
#     "yes no" "core.doSomething")"
#
# result is then either empty (no option set) or "yes" or "no"
#
# __git_get_option_value requires 3 arguments
__git_get_option_value ()
{
    local c short_opt long_opt val
    local result= values config_key word

    short_opt="$1"
    long_opt="$2"
    values="$3"
    config_key="$4"

    ((c = $cword - 1))
    while [ $c -ge 0 ]; do
        word="${words[c]}"
        for val in $values; do
            if [ "$short_opt$val" = "$word" ] ||
               [ "$long_opt$val"  = "$word" ]; then
                result="$val"
                break 2
            fi
        done
        ((c--))
    done

    if [ -n "$config_key" ] && [ -z "$result" ]; then
        result="$(git --git-dir="$(__gitdir)" config "$config_key")"
    fi

    echo "$result"
}

__git_has_doubledash ()
{
    local c=1
    while [ $c -lt $cword ]; do
        if [ "--" = "${words[c]}" ]; then
            return 0
        fi
        ((c++))
    done
    return 1
}

# Try to count non option arguments passed on the command line for the
# specified git command.
# When options are used, it is necessary to use the special -- option to
# tell the implementation were non option arguments begin.
# XXX this can not be improved, since options can appear everywhere, as
# an example:
#   git mv x -n y
#
# __git_count_arguments requires 1 argument: the git command executed.
__git_count_arguments ()
{
    local word i c=0

    # Skip "git" (first argument)
    for ((i=1; i < ${#words[@]}; i++)); do
        word="${words[i]}"

        case "$word" in
            --)
                # Good; we can assume that the following are only non
                # option arguments.
                ((c = 0))
                ;;
            "$1")
                # Skip the specified git command and discard git
                # main options
                ((c = 0))
                ;;
            ?*)
                ((c++))
                ;;
        esac
    done

    printf "%d" $c
}

__git_whitespacelist="nowarn warn error error-all fix"

_git_am ()
{
    local dir="$(__gitdir)"
    if [ -d "$dir"/rebase-apply ]; then
        __gitcomp "--skip --continue --resolved --abort"
        return
    fi
    case "$cur" in
    --whitespace=*)
        __gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
        return
        ;;
    --*)
        __gitcomp "
            --3way --committer-date-is-author-date --ignore-date
            --ignore-whitespace --ignore-space-change
            --interactive --keep --no-utf8 --signoff --utf8
            --whitespace= --scissors
            "
        return
    esac
}

_git_apply ()
{
    case "$cur" in
    --whitespace=*)
        __gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
        return
        ;;
    --*)
        __gitcomp "
            --stat --numstat --summary --check --index
            --cached --index-info --reverse --reject --unidiff-zero
            --apply --no-add --exclude=
            --ignore-whitespace --ignore-space-change
            --whitespace= --inaccurate-eof --verbose
            "
        return
    esac
}

_git_add ()
{
    case "$cur" in
    --*)
        __gitcomp "
            --interactive --refresh --patch --update --dry-run
            --ignore-errors --intent-to-add
            "
        return
    esac

    # XXX should we check for --update and --all options ?
    __git_complete_index_file "--others --modified --directory --no-empty-directory"
}

_git_archive ()
{
    case "$cur" in
    --format=*)
        __gitcomp "$(git archive --list)" "" "${cur##--format=}"
        return
        ;;
    --remote=*)
        __gitcomp_nl "$(__git_remotes)" "" "${cur##--remote=}"
        return
        ;;
    --*)
        __gitcomp "
            --format= --list --verbose
            --prefix= --remote= --exec=
            "
        return
        ;;
    esac
    __git_complete_file
}

_git_bisect ()
{
    __git_has_doubledash && return

    local subcommands="start bad good skip reset visualize replay log run"
    local subcommand="$(__git_find_on_cmdline "$subcommands")"
    if [ -z "$subcommand" ]; then
        if [ -f "$(__gitdir)"/BISECT_START ]; then
            __gitcomp "$subcommands"
        else
            __gitcomp "replay start"
        fi
        return
    fi

    case "$subcommand" in
    bad|good|reset|skip|start)
        __gitcomp_nl "$(__git_refs)"
        ;;
    *)
        ;;
    esac
}

_git_branch ()
{
    local i c=1 only_local_ref="n" has_r="n"

    while [ $c -lt $cword ]; do
        i="${words[c]}"
        case "$i" in
        -d|--delete|-m|--move)  only_local_ref="y" ;;
        -r|--remotes)       has_r="y" ;;
        esac
        ((c++))
    done

    case "$cur" in
    --set-upstream-to=*)
        __gitcomp_nl "$(__git_refs)" "" "${cur##--set-upstream-to=}"
        ;;
    --*)
        __gitcomp "
            --color --no-color --verbose --abbrev= --no-abbrev
            --track --no-track --contains --merged --no-merged
            --set-upstream-to= --edit-description --list
            --unset-upstream --delete --move --remotes
            "
        ;;
    *)
        if [ $only_local_ref = "y" -a $has_r = "n" ]; then
            __gitcomp_nl "$(__git_heads)"
        else
            __gitcomp_nl "$(__git_refs)"
        fi
        ;;
    esac
}

_git_bundle ()
{
    local cmd="${words[2]}"
    case "$cword" in
    2)
        __gitcomp "create list-heads verify unbundle"
        ;;
    3)
        # looking for a file
        ;;
    *)
        case "$cmd" in
            create)
                __git_complete_revlist
            ;;
        esac
        ;;
    esac
}

_git_checkout ()
{
    __git_has_doubledash && return

    case "$cur" in
    --conflict=*)
        __gitcomp "diff3 merge" "" "${cur##--conflict=}"
        ;;
    --*)
        __gitcomp "
            --quiet --ours --theirs --track --no-track --merge
            --conflict= --orphan --patch
            "
        ;;
    *)
        # check if --track, --no-track, or --no-guess was specified
        # if so, disable DWIM mode
        local flags="--track --no-track --no-guess" track=1
        if [ -n "$(__git_find_on_cmdline "$flags")" ]; then
            track=''
        fi
        __gitcomp_nl "$(__git_refs '' $track)"
        ;;
    esac
}

_git_cherry ()
{
    __gitcomp_nl "$(__git_refs)"
}

_git_cherry_pick ()
{
    local dir="$(__gitdir)"
    if [ -f "$dir"/CHERRY_PICK_HEAD ]; then
        __gitcomp "--continue --quit --abort"
        return
    fi
    case "$cur" in
    --*)
        __gitcomp "--edit --no-commit --signoff --strategy= --mainline"
        ;;
    *)
        __gitcomp_nl "$(__git_refs)"
        ;;
    esac
}

_git_clean ()
{
    case "$cur" in
    --*)
        __gitcomp "--dry-run --quiet"
        return
        ;;
    esac

    # XXX should we check for -x option ?
    __git_complete_index_file "--others --directory"
}

_git_clone ()
{
    case "$cur" in
    --*)
        __gitcomp "
            --local
            --no-hardlinks
            --shared
            --reference
            --quiet
            --no-checkout
            --bare
            --mirror
            --origin
            --upload-pack
            --template=
            --depth
            --single-branch
            --branch
            --recurse-submodules
            "
        return
        ;;
    esac
}

__git_untracked_file_modes="all no normal"

_git_commit ()
{
    case "$prev" in
    -c|-C)
        __gitcomp_nl "$(__git_refs)" "" "${cur}"
        return
        ;;
    esac

    case "$cur" in
    --cleanup=*)
        __gitcomp "default scissors strip verbatim whitespace
            " "" "${cur##--cleanup=}"
        return
        ;;
    --reuse-message=*|--reedit-message=*|\
    --fixup=*|--squash=*)
        __gitcomp_nl "$(__git_refs)" "" "${cur#*=}"
        return
        ;;
    --untracked-files=*)
        __gitcomp "$__git_untracked_file_modes" "" "${cur##--untracked-files=}"
        return
        ;;
    --*)
        __gitcomp "
            --all --author= --signoff --verify --no-verify
            --edit --no-edit
            --amend --include --only --interactive
            --dry-run --reuse-message= --reedit-message=
            --reset-author --file= --message= --template=
            --cleanup= --untracked-files --untracked-files=
            --verbose --quiet --fixup= --squash=
            "
        return
    esac

    if git rev-parse --verify --quiet HEAD >/dev/null; then
        __git_complete_index_file "--committable"
    else
        # This is the first commit
        __git_complete_index_file "--cached"
    fi
}

_git_describe ()
{
    case "$cur" in
    --*)
        __gitcomp "
            --all --tags --contains --abbrev= --candidates=
            --exact-match --debug --long --match --always
            "
        return
    esac
    __gitcomp_nl "$(__git_refs)"
}

__git_diff_algorithms="myers minimal patience histogram"

__git_diff_submodule_formats="log short"

__git_diff_common_options="--stat --numstat --shortstat --summary
            --patch-with-stat --name-only --name-status --color
            --no-color --color-words --no-renames --check
            --full-index --binary --abbrev --diff-filter=
            --find-copies-harder
            --text --ignore-space-at-eol --ignore-space-change
            --ignore-all-space --ignore-blank-lines --exit-code
            --quiet --ext-diff --no-ext-diff
            --no-prefix --src-prefix= --dst-prefix=
            --inter-hunk-context=
            --patience --histogram --minimal
            --raw --word-diff --word-diff-regex=
            --dirstat --dirstat= --dirstat-by-file
            --dirstat-by-file= --cumulative
            --diff-algorithm=
            --submodule --submodule=
"

_git_diff ()
{
    __git_has_doubledash && return

    case "$cur" in
    --diff-algorithm=*)
        __gitcomp "$__git_diff_algorithms" "" "${cur##--diff-algorithm=}"
        return
        ;;
    --submodule=*)
        __gitcomp "$__git_diff_submodule_formats" "" "${cur##--submodule=}"
        return
        ;;
    --*)
        __gitcomp "--cached --staged --pickaxe-all --pickaxe-regex
            --base --ours --theirs --no-index
            $__git_diff_common_options
            "
        return
        ;;
    esac
    __git_complete_revlist_file
}

__git_mergetools_common="diffuse diffmerge ecmerge emerge kdiff3 meld opendiff
            tkdiff vimdiff gvimdiff xxdiff araxis p4merge bc codecompare
"

_git_difftool ()
{
    __git_has_doubledash && return

    case "$cur" in
    --tool=*)
        __gitcomp "$__git_mergetools_common kompare" "" "${cur##--tool=}"
        return
        ;;
    --*)
        __gitcomp "--cached --staged --pickaxe-all --pickaxe-regex
            --base --ours --theirs
            --no-renames --diff-filter= --find-copies-harder
            --relative --ignore-submodules
            --tool="
        return
        ;;
    esac
    __git_complete_revlist_file
}

__git_fetch_recurse_submodules="yes on-demand no"

__git_fetch_options="
    --quiet --verbose --append --upload-pack --force --keep --depth=
    --tags --no-tags --all --prune --dry-run --recurse-submodules=
"

_git_fetch ()
{
    case "$cur" in
    --recurse-submodules=*)
        __gitcomp "$__git_fetch_recurse_submodules" "" "${cur##--recurse-submodules=}"
        return
        ;;
    --*)
        __gitcomp "$__git_fetch_options"
        return
        ;;
    esac
    __git_complete_remote_or_refspec
}

__git_format_patch_options="
    --stdout --attach --no-attach --thread --thread= --no-thread
    --numbered --start-number --numbered-files --keep-subject --signoff
    --signature --no-signature --in-reply-to= --cc= --full-index --binary
    --not --all --cover-letter --no-prefix --src-prefix= --dst-prefix=
    --inline --suffix= --ignore-if-in-upstream --subject-prefix=
    --output-directory --reroll-count --to= --quiet --notes
"

_git_format_patch ()
{
    case "$cur" in
    --thread=*)
        __gitcomp "
            deep shallow
            " "" "${cur##--thread=}"
        return
        ;;
    --*)
        __gitcomp "$__git_format_patch_options"
        return
        ;;
    esac
    __git_complete_revlist
}

_git_fsck ()
{
    case "$cur" in
    --*)
        __gitcomp "
            --tags --root --unreachable --cache --no-reflogs --full
            --strict --verbose --lost-found
            "
        return
        ;;
    esac
}

_git_gc ()
{
    case "$cur" in
    --*)
        __gitcomp "--prune --aggressive"
        return
        ;;
    esac
}

_git_gitk ()
{
    _gitk
}

__git_match_ctag() {
    awk "/^${1//\//\\/}/ { print \$1 }" "$2"
}

_git_grep ()
{
    __git_has_doubledash && return

    case "$cur" in
    --*)
        __gitcomp "
            --cached
            --text --ignore-case --word-regexp --invert-match
            --full-name --line-number
            --extended-regexp --basic-regexp --fixed-strings
            --perl-regexp
            --threads
            --files-with-matches --name-only
            --files-without-match
            --max-depth
            --count
            --and --or --not --all-match
            "
        return
        ;;
    esac

    case "$cword,$prev" in
    2,*|*,-*)
        if test -r tags; then
            __gitcomp_nl "$(__git_match_ctag "$cur" tags)"
            return
        fi
        ;;
    esac

    __gitcomp_nl "$(__git_refs)"
}

_git_help ()
{
    case "$cur" in
    --*)
        __gitcomp "--all --guides --info --man --web"
        return
        ;;
    esac
    __git_compute_all_commands
    __gitcomp "$__git_all_commands $(__git_aliases)
        attributes cli core-tutorial cvs-migration
        diffcore everyday gitk glossary hooks ignore modules
        namespaces repository-layout revisions tutorial tutorial-2
        workflows
        "
}

_git_init ()
{
    case "$cur" in
    --shared=*)
        __gitcomp "
            false true umask group all world everybody
            " "" "${cur##--shared=}"
        return
        ;;
    --*)
        __gitcomp "--quiet --bare --template= --shared --shared="
        return
        ;;
    esac
}

_git_ls_files ()
{
    case "$cur" in
    --*)
        __gitcomp "--cached --deleted --modified --others --ignored
            --stage --directory --no-empty-directory --unmerged
            --killed --exclude= --exclude-from=
            --exclude-per-directory= --exclude-standard
            --error-unmatch --with-tree= --full-name
            --abbrev --ignored --exclude-per-directory
            "
        return
        ;;
    esac

    # XXX ignore options like --modified and always suggest all cached
    # files.
    __git_complete_index_file "--cached"
}

_git_ls_remote ()
{
    __gitcomp_nl "$(__git_remotes)"
}

_git_ls_tree ()
{
    __git_complete_file
}

# Options that go well for log, shortlog and gitk
__git_log_common_options="
    --not --all
    --branches --tags --remotes
    --first-parent --merges --no-merges
    --max-count=
    --max-age= --since= --after=
    --min-age= --until= --before=
    --min-parents= --max-parents=
    --no-min-parents --no-max-parents
"
# Options that go well for log and gitk (not shortlog)
__git_log_gitk_options="
    --dense --sparse --full-history
    --simplify-merges --simplify-by-decoration
    --left-right --notes --no-notes
"
# Options that go well for log and shortlog (not gitk)
__git_log_shortlog_options="
    --author= --committer= --grep=
    --all-match --invert-grep
"

__git_log_pretty_formats="oneline short medium full fuller email raw format:"
__git_log_date_formats="relative iso8601 rfc2822 short local default raw"

_git_log ()
{
    __git_has_doubledash && return

    local g="$(git rev-parse --git-dir 2>/dev/null)"
    local merge=""
    if [ -f "$g/MERGE_HEAD" ]; then
        merge="--merge"
    fi
    case "$cur" in
    --pretty=*|--format=*)
        __gitcomp "$__git_log_pretty_formats $(__git_pretty_aliases)
            " "" "${cur#*=}"
        return
        ;;
    --date=*)
        __gitcomp "$__git_log_date_formats" "" "${cur##--date=}"
        return
        ;;
    --decorate=*)
        __gitcomp "full short no" "" "${cur##--decorate=}"
        return
        ;;
    --diff-algorithm=*)
        __gitcomp "$__git_diff_algorithms" "" "${cur##--diff-algorithm=}"
        return
        ;;
    --submodule=*)
        __gitcomp "$__git_diff_submodule_formats" "" "${cur##--submodule=}"
        return
        ;;
    --*)
        __gitcomp "
            $__git_log_common_options
            $__git_log_shortlog_options
            $__git_log_gitk_options
            --root --topo-order --date-order --reverse
            --follow --full-diff
            --abbrev-commit --abbrev=
            --relative-date --date=
            --pretty= --format= --oneline
            --show-signature
            --cherry-mark
            --cherry-pick
            --graph
            --decorate --decorate=
            --walk-reflogs
            --parents --children
            $merge
            $__git_diff_common_options
            --pickaxe-all --pickaxe-regex
            "
        return
        ;;
    esac
    __git_complete_revlist
}

# Common merge options shared by git-merge(1) and git-pull(1).
__git_merge_options="
    --no-commit --no-stat --log --no-log --squash --strategy
    --commit --stat --no-squash --ff --no-ff --ff-only --edit --no-edit
    --verify-signatures --no-verify-signatures --gpg-sign
    --quiet --verbose --progress --no-progress
"

_git_merge ()
{
    __git_complete_strategy && return

    case "$cur" in
    --*)
        __gitcomp "$__git_merge_options
            --rerere-autoupdate --no-rerere-autoupdate --abort"
        return
    esac
    __gitcomp_nl "$(__git_refs)"
}

_git_mergetool ()
{
    case "$cur" in
    --tool=*)
        __gitcomp "$__git_mergetools_common tortoisemerge" "" "${cur##--tool=}"
        return
        ;;
    --*)
        __gitcomp "--tool="
        return
        ;;
    esac
}

_git_merge_base ()
{
    case "$cur" in
    --*)
        __gitcomp "--octopus --independent --is-ancestor --fork-point"
        return
        ;;
    esac
    __gitcomp_nl "$(__git_refs)"
}

_git_mv ()
{
    case "$cur" in
    --*)
        __gitcomp "--dry-run"
        return
        ;;
    esac

    if [ $(__git_count_arguments "mv") -gt 0 ]; then
        # We need to show both cached and untracked files (including
        # empty directories) since this may not be the last argument.
        __git_complete_index_file "--cached --others --directory"
    else
        __git_complete_index_file "--cached"
    fi
}

_git_name_rev ()
{
    __gitcomp "--tags --all --stdin"
}

_git_notes ()
{
    local subcommands='add append copy edit list prune remove show'
    local subcommand="$(__git_find_on_cmdline "$subcommands")"

    case "$subcommand,$cur" in
    ,--*)
        __gitcomp '--ref'
        ;;
    ,*)
        case "$prev" in
        --ref)
            __gitcomp_nl "$(__git_refs)"
            ;;
        *)
            __gitcomp "$subcommands --ref"
            ;;
        esac
        ;;
    add,--reuse-message=*|append,--reuse-message=*|\
    add,--reedit-message=*|append,--reedit-message=*)
        __gitcomp_nl "$(__git_refs)" "" "${cur#*=}"
        ;;
    add,--*|append,--*)
        __gitcomp '--file= --message= --reedit-message=
                --reuse-message='
        ;;
    copy,--*)
        __gitcomp '--stdin'
        ;;
    prune,--*)
        __gitcomp '--dry-run --verbose'
        ;;
    prune,*)
        ;;
    *)
        case "$prev" in
        -m|-F)
            ;;
        *)
            __gitcomp_nl "$(__git_refs)"
            ;;
        esac
        ;;
    esac
}

_git_pull ()
{
    __git_complete_strategy && return

    case "$cur" in
    --recurse-submodules=*)
        __gitcomp "$__git_fetch_recurse_submodules" "" "${cur##--recurse-submodules=}"
        return
        ;;
    --*)
        __gitcomp "
            --rebase --no-rebase
            $__git_merge_options
            $__git_fetch_options
        "
        return
        ;;
    esac
    __git_complete_remote_or_refspec
}

__git_push_recurse_submodules="check on-demand"

__git_complete_force_with_lease ()
{
    local cur_=$1

    case "$cur_" in
    --*=)
        ;;
    *:*)
        __gitcomp_nl "$(__git_refs)" "" "${cur_#*:}"
        ;;
    *)
        __gitcomp_nl "$(__git_refs)" "" "$cur_"
        ;;
    esac
}

_git_push ()
{
    case "$prev" in
    --repo)
        __gitcomp_nl "$(__git_remotes)"
        return
        ;;
    --recurse-submodules)
        __gitcomp "$__git_push_recurse_submodules"
        return
        ;;
    esac
    case "$cur" in
    --repo=*)
        __gitcomp_nl "$(__git_remotes)" "" "${cur##--repo=}"
        return
        ;;
    --recurse-submodules=*)
        __gitcomp "$__git_push_recurse_submodules" "" "${cur##--recurse-submodules=}"
        return
        ;;
    --force-with-lease=*)
        __git_complete_force_with_lease "${cur##--force-with-lease=}"
        return
        ;;
    --*)
        __gitcomp "
            --all --mirror --tags --dry-run --force --verbose
            --quiet --prune --delete --follow-tags
            --receive-pack= --repo= --set-upstream
            --force-with-lease --force-with-lease= --recurse-submodules=
        "
        return
        ;;
    esac
    __git_complete_remote_or_refspec
}

_git_rebase ()
{
    local dir="$(__gitdir)"
    if [ -f "$dir"/rebase-merge/interactive ]; then
        __gitcomp "--continue --skip --abort --quit --edit-todo"
        return
    elif [ -d "$dir"/rebase-apply ] || [ -d "$dir"/rebase-merge ]; then
        __gitcomp "--continue --skip --abort --quit"
        return
    fi
    __git_complete_strategy && return
    case "$cur" in
    --whitespace=*)
        __gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
        return
        ;;
    --*)
        __gitcomp "
            --onto --merge --strategy --interactive
            --preserve-merges --stat --no-stat
            --committer-date-is-author-date --ignore-date
            --ignore-whitespace --whitespace=
            --autosquash --no-autosquash
            --fork-point --no-fork-point
            --autostash --no-autostash
            --verify --no-verify
            --keep-empty --root --force-rebase --no-ff
            --exec
            "

        return
    esac
    __gitcomp_nl "$(__git_refs)"
}

_git_reflog ()
{
    local subcommands="show delete expire"
    local subcommand="$(__git_find_on_cmdline "$subcommands")"

    if [ -z "$subcommand" ]; then
        __gitcomp "$subcommands"
    else
        __gitcomp_nl "$(__git_refs)"
    fi
}

__git_send_email_confirm_options="always never auto cc compose"
__git_send_email_suppresscc_options="author self cc bodycc sob cccmd body all"

_git_send_email ()
{
    case "$prev" in
    --to|--cc|--bcc|--from)
        __gitcomp "
        $(git --git-dir="$(__gitdir)" send-email --dump-aliases 2>/dev/null)
        "
        return
        ;;
    esac

    case "$cur" in
    --confirm=*)
        __gitcomp "
            $__git_send_email_confirm_options
            " "" "${cur##--confirm=}"
        return
        ;;
    --suppress-cc=*)
        __gitcomp "
            $__git_send_email_suppresscc_options
            " "" "${cur##--suppress-cc=}"

        return
        ;;
    --smtp-encryption=*)
        __gitcomp "ssl tls" "" "${cur##--smtp-encryption=}"
        return
        ;;
    --thread=*)
        __gitcomp "
            deep shallow
            " "" "${cur##--thread=}"
        return
        ;;
    --to=*|--cc=*|--bcc=*|--from=*)
        __gitcomp "
        $(git --git-dir="$(__gitdir)" send-email --dump-aliases 2>/dev/null)
        " "" "${cur#--*=}"
        return
        ;;
    --*)
        __gitcomp "--annotate --bcc --cc --cc-cmd --chain-reply-to
            --compose --confirm= --dry-run --envelope-sender
            --from --identity
            --in-reply-to --no-chain-reply-to --no-signed-off-by-cc
            --no-suppress-from --no-thread --quiet
            --signed-off-by-cc --smtp-pass --smtp-server
            --smtp-server-port --smtp-encryption= --smtp-user
            --subject --suppress-cc= --suppress-from --thread --to
            --validate --no-validate
            $__git_format_patch_options"
        return
        ;;
    esac
    __git_complete_revlist
}

_git_stage ()
{
    _git_add
}

_git_status ()
{
    local complete_opt
    local untracked_state

    case "$cur" in
    --ignore-submodules=*)
        __gitcomp "none untracked dirty all" "" "${cur##--ignore-submodules=}"
        return
        ;;
    --untracked-files=*)
        __gitcomp "$__git_untracked_file_modes" "" "${cur##--untracked-files=}"
        return
        ;;
    --column=*)
        __gitcomp "
            always never auto column row plain dense nodense
            " "" "${cur##--column=}"
        return
        ;;
    --*)
        __gitcomp "
            --short --branch --porcelain --long --verbose
            --untracked-files= --ignore-submodules= --ignored
            --column= --no-column
            "
        return
        ;;
    esac

    untracked_state="$(__git_get_option_value "-u" "--untracked-files=" \
        "$__git_untracked_file_modes" "status.showUntrackedFiles")"

    case "$untracked_state" in
    no)
        # --ignored option does not matter
        complete_opt=
        ;;
    all|normal|*)
        complete_opt="--cached --directory --no-empty-directory --others"

        if [ -n "$(__git_find_on_cmdline "--ignored")" ]; then
            complete_opt="$complete_opt --ignored --exclude=*"
        fi
        ;;
    esac

    __git_complete_index_file "$complete_opt"
}

__git_config_get_set_variables ()
{
    local prevword word config_file= c=$cword
    while [ $c -gt 1 ]; do
        word="${words[c]}"
        case "$word" in
        --system|--global|--local|--file=*)
            config_file="$word"
            break
            ;;
        -f|--file)
            config_file="$word $prevword"
            break
            ;;
        esac
        prevword=$word
        c=$((--c))
    done

    git --git-dir="$(__gitdir)" config $config_file --name-only --list 2>/dev/null
}

_git_config ()
{
    case "$prev" in
    branch.*.remote|branch.*.pushremote)
        __gitcomp_nl "$(__git_remotes)"
        return
        ;;
    branch.*.merge)
        __gitcomp_nl "$(__git_refs)"
        return
        ;;
    branch.*.rebase)
        __gitcomp "false true preserve interactive"
        return
        ;;
    remote.pushdefault)
        __gitcomp_nl "$(__git_remotes)"
        return
        ;;
    remote.*.fetch)
        local remote="${prev#remote.}"
        remote="${remote%.fetch}"
        if [ -z "$cur" ]; then
            __gitcomp_nl "refs/heads/" "" "" ""
            return
        fi
        __gitcomp_nl "$(__git_refs_remotes "$remote")"
        return
        ;;
    remote.*.push)
        local remote="${prev#remote.}"
        remote="${remote%.push}"
        __gitcomp_nl "$(git --git-dir="$(__gitdir)" \
            for-each-ref --format='%(refname):%(refname)' \
            refs/heads)"
        return
        ;;
    pull.twohead|pull.octopus)
        __git_compute_merge_strategies
        __gitcomp "$__git_merge_strategies"
        return
        ;;
    color.branch|color.diff|color.interactive|\
    color.showbranch|color.status|color.ui)
        __gitcomp "always never auto"
        return
        ;;
    color.pager)
        __gitcomp "false true"
        return
        ;;
    color.*.*)
        __gitcomp "
            normal black red green yellow blue magenta cyan white
            bold dim ul blink reverse
            "
        return
        ;;
    diff.submodule)
        __gitcomp "log short"
        return
        ;;
    help.format)
        __gitcomp "man info web html"
        return
        ;;
    log.date)
        __gitcomp "$__git_log_date_formats"
        return
        ;;
    sendemail.aliasesfiletype)
        __gitcomp "mutt mailrc pine elm gnus"
        return
        ;;
    sendemail.confirm)
        __gitcomp "$__git_send_email_confirm_options"
        return
        ;;
    sendemail.suppresscc)
        __gitcomp "$__git_send_email_suppresscc_options"
        return
        ;;
    sendemail.transferencoding)
        __gitcomp "7bit 8bit quoted-printable base64"
        return
        ;;
    --get|--get-all|--unset|--unset-all)
        __gitcomp_nl "$(__git_config_get_set_variables)"
        return
        ;;
    *.*)
        return
        ;;
    esac
    case "$cur" in
    --*)
        __gitcomp "
            --system --global --local --file=
            --list --replace-all
            --get --get-all --get-regexp
            --add --unset --unset-all
            --remove-section --rename-section
            --name-only
            "
        return
        ;;
    branch.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "remote pushremote merge mergeoptions rebase" "$pfx" "$cur_"
        return
        ;;
    branch.*)
        local pfx="${cur%.*}." cur_="${cur#*.}"
        __gitcomp_nl "$(__git_heads)" "$pfx" "$cur_" "."
        __gitcomp_nl_append $'autosetupmerge\nautosetuprebase\n' "$pfx" "$cur_"
        return
        ;;
    guitool.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "
            argprompt cmd confirm needsfile noconsole norescan
            prompt revprompt revunmerged title
            " "$pfx" "$cur_"
        return
        ;;
    difftool.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "cmd path" "$pfx" "$cur_"
        return
        ;;
    man.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "cmd path" "$pfx" "$cur_"
        return
        ;;
    mergetool.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "cmd path trustExitCode" "$pfx" "$cur_"
        return
        ;;
    pager.*)
        local pfx="${cur%.*}." cur_="${cur#*.}"
        __git_compute_all_commands
        __gitcomp_nl "$__git_all_commands" "$pfx" "$cur_"
        return
        ;;
    remote.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "
            url proxy fetch push mirror skipDefaultUpdate
            receivepack uploadpack tagopt pushurl
            " "$pfx" "$cur_"
        return
        ;;
    remote.*)
        local pfx="${cur%.*}." cur_="${cur#*.}"
        __gitcomp_nl "$(__git_remotes)" "$pfx" "$cur_" "."
        __gitcomp_nl_append "pushdefault" "$pfx" "$cur_"
        return
        ;;
    url.*.*)
        local pfx="${cur%.*}." cur_="${cur##*.}"
        __gitcomp "insteadOf pushInsteadOf" "$pfx" "$cur_"
        return
        ;;
    esac
    __gitcomp "
        add.ignoreErrors
        advice.commitBeforeMerge
        advice.detachedHead
        advice.implicitIdentity
        advice.pushNonFastForward
        advice.resolveConflict
        advice.statusHints
        alias.
        am.keepcr
        apply.ignorewhitespace
        apply.whitespace
        branch.autosetupmerge
        branch.autosetuprebase
        browser.
        clean.requireForce
        color.branch
        color.branch.current
        color.branch.local
        color.branch.plain
        color.branch.remote
        color.decorate.HEAD
        color.decorate.branch
        color.decorate.remoteBranch
        color.decorate.stash
        color.decorate.tag
        color.diff
        color.diff.commit
        color.diff.frag
        color.diff.func
        color.diff.meta
        color.diff.new
        color.diff.old
        color.diff.plain
        color.diff.whitespace
        color.grep
        color.grep.context
        color.grep.filename
        color.grep.function
        color.grep.linenumber
        color.grep.match
        color.grep.selected
        color.grep.separator
        color.interactive
        color.interactive.error
        color.interactive.header
        color.interactive.help
        color.interactive.prompt
        color.pager
        color.showbranch
        color.status
        color.status.added
        color.status.changed
        color.status.header
        color.status.nobranch
        color.status.unmerged
        color.status.untracked
        color.status.updated
        color.ui
        commit.status
        commit.template
        core.abbrev
        core.askpass
        core.attributesfile
        core.autocrlf
        core.bare
        core.bigFileThreshold
        core.compression
        core.createObject
        core.deltaBaseCacheLimit
        core.editor
        core.eol
        core.excludesfile
        core.fileMode
        core.fsyncobjectfiles
        core.gitProxy
        core.ignoreStat
        core.ignorecase
        core.logAllRefUpdates
        core.loosecompression
        core.notesRef
        core.packedGitLimit
        core.packedGitWindowSize
        core.pager
        core.preferSymlinkRefs
        core.preloadindex
        core.quotepath
        core.repositoryFormatVersion
        core.safecrlf
        core.sharedRepository
        core.sparseCheckout
        core.symlinks
        core.trustctime
        core.untrackedCache
        core.warnAmbiguousRefs
        core.whitespace
        core.worktree
        diff.autorefreshindex
        diff.external
        diff.ignoreSubmodules
        diff.mnemonicprefix
        diff.noprefix
        diff.renameLimit
        diff.renames
        diff.statGraphWidth
        diff.submodule
        diff.suppressBlankEmpty
        diff.tool
        diff.wordRegex
        diff.algorithm
        difftool.
        difftool.prompt
        fetch.recurseSubmodules
        fetch.unpackLimit
        format.attach
        format.cc
        format.coverLetter
        format.from
        format.headers
        format.numbered
        format.pretty
        format.signature
        format.signoff
        format.subjectprefix
        format.suffix
        format.thread
        format.to
        gc.
        gc.aggressiveWindow
        gc.auto
        gc.autopacklimit
        gc.packrefs
        gc.pruneexpire
        gc.reflogexpire
        gc.reflogexpireunreachable
        gc.rerereresolved
        gc.rerereunresolved
        gitcvs.allbinary
        gitcvs.commitmsgannotation
        gitcvs.dbTableNamePrefix
        gitcvs.dbdriver
        gitcvs.dbname
        gitcvs.dbpass
        gitcvs.dbuser
        gitcvs.enabled
        gitcvs.logfile
        gitcvs.usecrlfattr
        guitool.
        gui.blamehistoryctx
        gui.commitmsgwidth
        gui.copyblamethreshold
        gui.diffcontext
        gui.encoding
        gui.fastcopyblame
        gui.matchtrackingbranch
        gui.newbranchtemplate
        gui.pruneduringfetch
        gui.spellingdictionary
        gui.trustmtime
        help.autocorrect
        help.browser
        help.format
        http.lowSpeedLimit
        http.lowSpeedTime
        http.maxRequests
        http.minSessions
        http.noEPSV
        http.postBuffer
        http.proxy
        http.sslCipherList
        http.sslVersion
        http.sslCAInfo
        http.sslCAPath
        http.sslCert
        http.sslCertPasswordProtected
        http.sslKey
        http.sslVerify
        http.useragent
        i18n.commitEncoding
        i18n.logOutputEncoding
        imap.authMethod
        imap.folder
        imap.host
        imap.pass
        imap.port
        imap.preformattedHTML
        imap.sslverify
        imap.tunnel
        imap.user
        init.templatedir
        instaweb.browser
        instaweb.httpd
        instaweb.local
        instaweb.modulepath
        instaweb.port
        interactive.singlekey
        log.date
        log.decorate
        log.showroot
        mailmap.file
        man.
        man.viewer
        merge.
        merge.conflictstyle
        merge.log
        merge.renameLimit
        merge.renormalize
        merge.stat
        merge.tool
        merge.verbosity
        mergetool.
        mergetool.keepBackup
        mergetool.keepTemporaries
        mergetool.prompt
        notes.displayRef
        notes.rewrite.
        notes.rewrite.amend
        notes.rewrite.rebase
        notes.rewriteMode
        notes.rewriteRef
        pack.compression
        pack.deltaCacheLimit
        pack.deltaCacheSize
        pack.depth
        pack.indexVersion
        pack.packSizeLimit
        pack.threads
        pack.window
        pack.windowMemory
        pager.
        pretty.
        pull.octopus
        pull.twohead
        push.default
        push.followTags
        rebase.autosquash
        rebase.stat
        receive.autogc
        receive.denyCurrentBranch
        receive.denyDeleteCurrent
        receive.denyDeletes
        receive.denyNonFastForwards
        receive.fsckObjects
        receive.unpackLimit
        receive.updateserverinfo
        remote.pushdefault
        remotes.
        repack.usedeltabaseoffset
        rerere.autoupdate
        rerere.enabled
        sendemail.
        sendemail.aliasesfile
        sendemail.aliasfiletype
        sendemail.bcc
        sendemail.cc
        sendemail.cccmd
        sendemail.chainreplyto
        sendemail.confirm
        sendemail.envelopesender
        sendemail.from
        sendemail.identity
        sendemail.multiedit
        sendemail.signedoffbycc
        sendemail.smtpdomain
        sendemail.smtpencryption
        sendemail.smtppass
        sendemail.smtpserver
        sendemail.smtpserveroption
        sendemail.smtpserverport
        sendemail.smtpuser
        sendemail.suppresscc
        sendemail.suppressfrom
        sendemail.thread
        sendemail.to
        sendemail.validate
        showbranch.default
        status.relativePaths
        status.showUntrackedFiles
        status.submodulesummary
        submodule.
        tar.umask
        transfer.unpackLimit
        url.
        user.email
        user.name
        user.signingkey
        web.browser
        branch. remote.
    "
}

_git_remote ()
{
    local subcommands="add rename remove set-head set-branches set-url show prune update"
    local subcommand="$(__git_find_on_cmdline "$subcommands")"
    if [ -z "$subcommand" ]; then
        __gitcomp "$subcommands"
        return
    fi

    case "$subcommand" in
    rename|remove|set-url|show|prune)
        __gitcomp_nl "$(__git_remotes)"
        ;;
    set-head|set-branches)
        __git_complete_remote_or_refspec
        ;;
    update)
        __gitcomp "$(__git_get_config_variables "remotes")"
        ;;
    *)
        ;;
    esac
}

_git_replace ()
{
    __gitcomp_nl "$(__git_refs)"
}

_git_reset ()
{
    __git_has_doubledash && return

    case "$cur" in
    --*)
        __gitcomp "--merge --mixed --hard --soft --patch"
        return
        ;;
    esac
    __gitcomp_nl "$(__git_refs)"
}

_git_revert ()
{
    local dir="$(__gitdir)"
    if [ -f "$dir"/REVERT_HEAD ]; then
        __gitcomp "--continue --quit --abort"
        return
    fi
    case "$cur" in
    --*)
        __gitcomp "--edit --mainline --no-edit --no-commit --signoff"
        return
        ;;
    esac
    __gitcomp_nl "$(__git_refs)"
}

_git_rm ()
{
    case "$cur" in
    --*)
        __gitcomp "--cached --dry-run --ignore-unmatch --quiet"
        return
        ;;
    esac

    __git_complete_index_file "--cached"
}

_git_shortlog ()
{
    __git_has_doubledash && return

    case "$cur" in
    --*)
        __gitcomp "
            $__git_log_common_options
            $__git_log_shortlog_options
            --numbered --summary
            "
        return
        ;;
    esac
    __git_complete_revlist
}

_git_show ()
{
    __git_has_doubledash && return

    case "$cur" in
    --pretty=*|--format=*)
        __gitcomp "$__git_log_pretty_formats $(__git_pretty_aliases)
            " "" "${cur#*=}"
        return
        ;;
    --diff-algorithm=*)
        __gitcomp "$__git_diff_algorithms" "" "${cur##--diff-algorithm=}"
        return
        ;;
    --submodule=*)
        __gitcomp "$__git_diff_submodule_formats" "" "${cur##--submodule=}"
        return
        ;;
    --*)
        __gitcomp "--pretty= --format= --abbrev-commit --oneline
            --show-signature
            $__git_diff_common_options
            "
        return
        ;;
    esac
    __git_complete_revlist_file
}

_git_show_branch ()
{
    case "$cur" in
    --*)
        __gitcomp "
            --all --remotes --topo-order --date-order --current --more=
            --list --independent --merge-base --no-name
            --color --no-color
            --sha1-name --sparse --topics --reflog
            "
        return
        ;;
    esac
    __git_complete_revlist
}

_git_stash ()
{
    local save_opts='--all --keep-index --no-keep-index --quiet --patch --include-untracked'
    local subcommands='save list show apply clear drop pop create branch'
    local subcommand="$(__git_find_on_cmdline "$subcommands")"
    if [ -z "$subcommand" ]; then
        case "$cur" in
        --*)
            __gitcomp "$save_opts"
            ;;
        *)
            if [ -z "$(__git_find_on_cmdline "$save_opts")" ]; then
                __gitcomp "$subcommands"
            fi
            ;;
        esac
    else
        case "$subcommand,$cur" in
        save,--*)
            __gitcomp "$save_opts"
            ;;
        apply,--*|pop,--*)
            __gitcomp "--index --quiet"
            ;;
        drop,--*)
            __gitcomp "--quiet"
            ;;
        show,--*|branch,--*)
            ;;
        branch,*)
            if [ $cword -eq 3 ]; then
                __gitcomp_nl "$(__git_refs)";
            else
                __gitcomp_nl "$(git --git-dir="$(__gitdir)" stash list \
                        | sed -n -e 's/:.*//p')"
            fi
            ;;
        show,*|apply,*|drop,*|pop,*)
            __gitcomp_nl "$(git --git-dir="$(__gitdir)" stash list \
                    | sed -n -e 's/:.*//p')"
            ;;
        *)
            ;;
        esac
    fi
}

_git_submodule ()
{
    __git_has_doubledash && return

    local subcommands="add status init deinit update summary foreach sync"
    if [ -z "$(__git_find_on_cmdline "$subcommands")" ]; then
        case "$cur" in
        --*)
            __gitcomp "--quiet --cached"
            ;;
        *)
            __gitcomp "$subcommands"
            ;;
        esac
        return
    fi
}

_git_svn ()
{
    local subcommands="
        init fetch clone rebase dcommit log find-rev
        set-tree commit-diff info create-ignore propget
        proplist show-ignore show-externals branch tag blame
        migrate mkdirs reset gc
        "
    local subcommand="$(__git_find_on_cmdline "$subcommands")"
    if [ -z "$subcommand" ]; then
        __gitcomp "$subcommands"
    else
        local remote_opts="--username= --config-dir= --no-auth-cache"
        local fc_opts="
            --follow-parent --authors-file= --repack=
            --no-metadata --use-svm-props --use-svnsync-props
            --log-window-size= --no-checkout --quiet
            --repack-flags --use-log-author --localtime
            --ignore-paths= --include-paths= $remote_opts
            "
        local init_opts="
            --template= --shared= --trunk= --tags=
            --branches= --stdlayout --minimize-url
            --no-metadata --use-svm-props --use-svnsync-props
            --rewrite-root= --prefix= --use-log-author
            --add-author-from $remote_opts
            "
        local cmt_opts="
            --edit --rmdir --find-copies-harder --copy-similarity=
            "

        case "$subcommand,$cur" in
        fetch,--*)
            __gitcomp "--revision= --fetch-all $fc_opts"
            ;;
        clone,--*)
            __gitcomp "--revision= $fc_opts $init_opts"
            ;;
        init,--*)
            __gitcomp "$init_opts"
            ;;
        dcommit,--*)
            __gitcomp "
                --merge --strategy= --verbose --dry-run
                --fetch-all --no-rebase --commit-url
                --revision --interactive $cmt_opts $fc_opts
                "
            ;;
        set-tree,--*)
            __gitcomp "--stdin $cmt_opts $fc_opts"
            ;;
        create-ignore,--*|propget,--*|proplist,--*|show-ignore,--*|\
        show-externals,--*|mkdirs,--*)
            __gitcomp "--revision="
            ;;
        log,--*)
            __gitcomp "
                --limit= --revision= --verbose --incremental
                --oneline --show-commit --non-recursive
                --authors-file= --color
                "
            ;;
        rebase,--*)
            __gitcomp "
                --merge --verbose --strategy= --local
                --fetch-all --dry-run $fc_opts
                "
            ;;
        commit-diff,--*)
            __gitcomp "--message= --file= --revision= $cmt_opts"
            ;;
        info,--*)
            __gitcomp "--url"
            ;;
        branch,--*)
            __gitcomp "--dry-run --message --tag"
            ;;
        tag,--*)
            __gitcomp "--dry-run --message"
            ;;
        blame,--*)
            __gitcomp "--git-format"
            ;;
        migrate,--*)
            __gitcomp "
                --config-dir= --ignore-paths= --minimize
                --no-auth-cache --username=
                "
            ;;
        reset,--*)
            __gitcomp "--revision= --parent"
            ;;
        *)
            ;;
        esac
    fi
}

_git_tag ()
{
    local i c=1 f=0
    while [ $c -lt $cword ]; do
        i="${words[c]}"
        case "$i" in
        -d|-v)
            __gitcomp_nl "$(__git_tags)"
            return
            ;;
        -f)
            f=1
            ;;
        esac
        ((c++))
    done

    case "$prev" in
    -m|-F)
        ;;
    -*|tag)
        if [ $f = 1 ]; then
            __gitcomp_nl "$(__git_tags)"
        fi
        ;;
    *)
        __gitcomp_nl "$(__git_refs)"
        ;;
    esac

    case "$cur" in
    --*)
        __gitcomp "
            --list --delete --verify --annotate --message --file
            --sign --cleanup --local-user --force --column --sort
            --contains --points-at
            "
        ;;
    esac
}

_git_whatchanged ()
{
    _git_log
}

_git_worktree ()
{
    local subcommands="add list lock prune unlock"
    local subcommand="$(__git_find_on_cmdline "$subcommands")"
    if [ -z "$subcommand" ]; then
        __gitcomp "$subcommands"
    else
        case "$subcommand,$cur" in
        add,--*)
            __gitcomp "--detach"
            ;;
        list,--*)
            __gitcomp "--porcelain"
            ;;
        lock,--*)
            __gitcomp "--reason"
            ;;
        prune,--*)
            __gitcomp "--dry-run --expire --verbose"
            ;;
        *)
            ;;
        esac
    fi
}

__git_main ()
{
    local i c=1 command __git_dir

    while [ $c -lt $cword ]; do
        i="${words[c]}"
        case "$i" in
        --git-dir=*) __git_dir="${i#--git-dir=}" ;;
        --git-dir)   ((c++)) ; __git_dir="${words[c]}" ;;
        --bare)      __git_dir="." ;;
        --help) command="help"; break ;;
        -c|--work-tree|--namespace) ((c++)) ;;
        -*) ;;
        *) command="$i"; break ;;
        esac
        ((c++))
    done

    if [ -z "$command" ]; then
        case "$cur" in
        --*)   __gitcomp "
            --paginate
            --no-pager
            --git-dir=
            --bare
            --version
            --exec-path
            --exec-path=
            --html-path
            --man-path
            --info-path
            --work-tree=
            --namespace=
            --no-replace-objects
            --help
            "
            ;;
        *)     __git_compute_porcelain_commands
               __gitcomp "$__git_porcelain_commands $(__git_aliases)" ;;
        esac
        return
    fi

    local completion_func="_git_${command//-/_}"
    declare -f $completion_func >/dev/null && $completion_func && return

    local expansion=$(__git_aliased_command "$command")
    if [ -n "$expansion" ]; then
        words[1]=$expansion
        completion_func="_git_${expansion//-/_}"
        declare -f $completion_func >/dev/null && $completion_func
    fi
}

__gitk_main ()
{
    __git_has_doubledash && return

    local g="$(__gitdir)"
    local merge=""
    if [ -f "$g/MERGE_HEAD" ]; then
        merge="--merge"
    fi
    case "$cur" in
    --*)
        __gitcomp "
            $__git_log_common_options
            $__git_log_gitk_options
            $merge
            "
        return
        ;;
    esac
    __git_complete_revlist
}

if [[ -n ${ZSH_VERSION-} ]]; then
    echo "WARNING: this script is deprecated, please see git-completion.zsh" 1>&2

    autoload -U +X compinit && compinit

    __gitcomp ()
    {
        emulate -L zsh

        local cur_="${3-$cur}"

        case "$cur_" in
        --*=)
            ;;
        *)
            local c IFS=$' \t\n'
            local -a array
            for c in ${=1}; do
                c="$c${4-}"
                case $c in
                --*=*|*.) ;;
                *) c="$c " ;;
                esac
                array[${#array[@]}+1]="$c"
            done
            compset -P '*[=:]'
            compadd -Q -S '' -p "${2-}" -a -- array && _ret=0
            ;;
        esac
    }

    __gitcomp_nl ()
    {
        emulate -L zsh

        local IFS=$'\n'
        compset -P '*[=:]'
        compadd -Q -S "${4- }" -p "${2-}" -- ${=1} && _ret=0
    }

    __gitcomp_file ()
    {
        emulate -L zsh

        local IFS=$'\n'
        compset -P '*[=:]'
        compadd -Q -p "${2-}" -f -- ${=1} && _ret=0
    }

    _git ()
    {
        local _ret=1 cur cword prev
        cur=${words[CURRENT]}
        prev=${words[CURRENT-1]}
        let cword=CURRENT-1
        emulate ksh -c __${service}_main
        let _ret && _default && _ret=0
        return _ret
    }

    compdef _git git gitk
    return
fi

__git_func_wrap ()
{
    local cur words cword prev
    _get_comp_words_by_ref -n =: cur words cword prev
    $1
}

# Setup completion for certain functions defined above by setting common
# variables and workarounds.
# This is NOT a public function; use at your own risk.
__git_complete ()
{
    local wrapper="__git_wrap${2}"
    eval "$wrapper () { __git_func_wrap $2 ; }"
    complete -o bashdefault -o default -o nospace -F $wrapper $1 2>/dev/null \
        || complete -o default -o nospace -F $wrapper $1
}

# wrapper for backwards compatibility
_git ()
{
    __git_wrap__git_main
}

# wrapper for backwards compatibility
_gitk ()
{
    __git_wrap__gitk_main
}

__git_complete git __git_main
__git_complete gitk __gitk_main

# The following are necessary only for Cygwin, and only are needed
# when the user has tab-completed the executable name and consequently
# included the '.exe' suffix.
#
if [ Cygwin = "$(uname -o 2>/dev/null)" ]; then
__git_complete git.exe __git_main
fi


# bash/zsh git prompt support
#
# Copyright (C) 2006,2007 Shawn O. Pearce <spearce@spearce.org>
# Distributed under the GNU General Public License, version 2.0.
#
# This script allows you to see repository status in your prompt.
#
# To enable:
#
#    1) Copy this file to somewhere (e.g. ~/.git-prompt.sh).
#    2) Add the following line to your .bashrc/.zshrc:
#        source ~/.git-prompt.sh
#    3a) Change your PS1 to call __git_ps1 as
#        command-substitution:
#        Bash: PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
#        ZSH:  setopt PROMPT_SUBST ; PS1='[%n@%m %c$(__git_ps1 " (%s)")]\$ '
#        the optional argument will be used as format string.
#    3b) Alternatively, for a slightly faster prompt, __git_ps1 can
#        be used for PROMPT_COMMAND in Bash or for precmd() in Zsh
#        with two parameters, <pre> and <post>, which are strings
#        you would put in $PS1 before and after the status string
#        generated by the git-prompt machinery.  e.g.
#        Bash: PROMPT_COMMAND='__git_ps1 "\u@\h:\w" "\\\$ "'
#          will show username, at-sign, host, colon, cwd, then
#          various status string, followed by dollar and SP, as
#          your prompt.
#        ZSH:  precmd () { __git_ps1 "%n" ":%~$ " "|%s" }
#          will show username, pipe, then various status string,
#          followed by colon, cwd, dollar and SP, as your prompt.
#        Optionally, you can supply a third argument with a printf
#        format string to finetune the output of the branch status
#
# The repository status will be displayed only if you are currently in a
# git repository. The %s token is the placeholder for the shown status.
#
# The prompt status always includes the current branch name.
#
# In addition, if you set GIT_PS1_SHOWDIRTYSTATE to a nonempty value,
# unstaged (*) and staged (+) changes will be shown next to the branch
# name.  You can configure this per-repository with the
# bash.showDirtyState variable, which defaults to true once
# GIT_PS1_SHOWDIRTYSTATE is enabled.
#
# You can also see if currently something is stashed, by setting
# GIT_PS1_SHOWSTASHSTATE to a nonempty value. If something is stashed,
# then a '$' will be shown next to the branch name.
#
# If you would like to see if there're untracked files, then you can set
# GIT_PS1_SHOWUNTRACKEDFILES to a nonempty value. If there're untracked
# files, then a '%' will be shown next to the branch name.  You can
# configure this per-repository with the bash.showUntrackedFiles
# variable, which defaults to true once GIT_PS1_SHOWUNTRACKEDFILES is
# enabled.
#
# If you would like to see the difference between HEAD and its upstream,
# set GIT_PS1_SHOWUPSTREAM="auto".  A "<" indicates you are behind, ">"
# indicates you are ahead, "<>" indicates you have diverged and "="
# indicates that there is no difference. You can further control
# behaviour by setting GIT_PS1_SHOWUPSTREAM to a space-separated list
# of values:
#
#     verbose       show number of commits ahead/behind (+/-) upstream
#     name          if verbose, then also show the upstream abbrev name
#     legacy        don't use the '--count' option available in recent
#                   versions of git-rev-list
#     git           always compare HEAD to @{upstream}
#     svn           always compare HEAD to your SVN upstream
#
# You can change the separator between the branch name and the above
# state symbols by setting GIT_PS1_STATESEPARATOR. The default separator
# is SP.
#
# By default, __git_ps1 will compare HEAD to your SVN upstream if it can
# find one, or @{upstream} otherwise.  Once you have set
# GIT_PS1_SHOWUPSTREAM, you can override it on a per-repository basis by
# setting the bash.showUpstream config variable.
#
# If you would like to see more information about the identity of
# commits checked out as a detached HEAD, set GIT_PS1_DESCRIBE_STYLE
# to one of these values:
#
#     contains      relative to newer annotated tag (v1.6.3.2~35)
#     branch        relative to newer tag or branch (master~4)
#     describe      relative to older annotated tag (v1.6.3.1-13-gdd42c2f)
#     default       exactly matching tag
#
# If you would like a colored hint about the current dirty state, set
# GIT_PS1_SHOWCOLORHINTS to a nonempty value. The colors are based on
# the colored output of "git status -sb" and are available only when
# using __git_ps1 for PROMPT_COMMAND or precmd.
#
# If you would like __git_ps1 to do nothing in the case when the current
# directory is set up to be ignored by git, then set
# GIT_PS1_HIDE_IF_PWD_IGNORED to a nonempty value. Override this on the
# repository level by setting bash.hideIfPwdIgnored to "false".

# check whether printf supports -v
__git_printf_supports_v=
printf -v __git_printf_supports_v -- '%s' yes >/dev/null 2>&1

# stores the divergence from upstream in $p
# used by GIT_PS1_SHOWUPSTREAM
__git_ps1_show_upstream ()
{
    local key value
    local svn_remote svn_url_pattern count n
    local upstream=git legacy="" verbose="" name=""

    svn_remote=()
    # get some config options from git-config
    local output="$(git config -z --get-regexp '^(svn-remote\..*\.url|bash\.showupstream)$' 2>/dev/null | tr '\0\n' '\n ')"
    while read -r key value; do
        case "$key" in
        bash.showupstream)
            GIT_PS1_SHOWUPSTREAM="$value"
            if [[ -z "${GIT_PS1_SHOWUPSTREAM}" ]]; then
                p=""
                return
            fi
            ;;
        svn-remote.*.url)
            svn_remote[$((${#svn_remote[@]} + 1))]="$value"
            svn_url_pattern="$svn_url_pattern\\|$value"
            upstream=svn+git # default upstream is SVN if available, else git
            ;;
        esac
    done <<< "$output"

    # parse configuration values
    for option in ${GIT_PS1_SHOWUPSTREAM}; do
        case "$option" in
        git|svn) upstream="$option" ;;
        verbose) verbose=1 ;;
        legacy)  legacy=1  ;;
        name)    name=1 ;;
        esac
    done

    # Find our upstream
    case "$upstream" in
    git)    upstream="@{upstream}" ;;
    svn*)
        # get the upstream from the "git-svn-id: ..." in a commit message
        # (git-svn uses essentially the same procedure internally)
        local -a svn_upstream
        svn_upstream=($(git log --first-parent -1 \
                    --grep="^git-svn-id: \(${svn_url_pattern#??}\)" 2>/dev/null))
        if [[ 0 -ne ${#svn_upstream[@]} ]]; then
            svn_upstream=${svn_upstream[${#svn_upstream[@]} - 2]}
            svn_upstream=${svn_upstream%@*}
            local n_stop="${#svn_remote[@]}"
            for ((n=1; n <= n_stop; n++)); do
                svn_upstream=${svn_upstream#${svn_remote[$n]}}
            done

            if [[ -z "$svn_upstream" ]]; then
                # default branch name for checkouts with no layout:
                upstream=${GIT_SVN_ID:-git-svn}
            else
                upstream=${svn_upstream#/}
            fi
        elif [[ "svn+git" = "$upstream" ]]; then
            upstream="@{upstream}"
        fi
        ;;
    esac

    # Find how many commits we are ahead/behind our upstream
    if [[ -z "$legacy" ]]; then
        count="$(git rev-list --count --left-right \
                "$upstream"...HEAD 2>/dev/null)"
    else
        # produce equivalent output to --count for older versions of git
        local commits
        if commits="$(git rev-list --left-right "$upstream"...HEAD 2>/dev/null)"
        then
            local commit behind=0 ahead=0
            for commit in $commits
            do
                case "$commit" in
                "<"*) ((behind++)) ;;
                *)    ((ahead++))  ;;
                esac
            done
            count="$behind  $ahead"
        else
            count=""
        fi
    fi

    # calculate the result
    if [[ -z "$verbose" ]]; then
        case "$count" in
        "") # no upstream
            p="" ;;
        "0  0") # equal to upstream
            p="=" ;;
        "0  "*) # ahead of upstream
            p=">" ;;
        *"  0") # behind upstream
            p="<" ;;
        *)      # diverged from upstream
            p="<>" ;;
        esac
    else
        case "$count" in
        "") # no upstream
            p="" ;;
        "0  0") # equal to upstream
            p=" u=" ;;
        "0  "*) # ahead of upstream
            p=" u+${count#0 }" ;;
        *"  0") # behind upstream
            p=" u-${count%  0}" ;;
        *)      # diverged from upstream
            p=" u+${count#* }-${count%  *}" ;;
        esac
        if [[ -n "$count" && -n "$name" ]]; then
            __git_ps1_upstream_name=$(git rev-parse \
                --abbrev-ref "$upstream" 2>/dev/null)
            if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
                p="$p \${__git_ps1_upstream_name}"
            else
                p="$p ${__git_ps1_upstream_name}"
                # not needed anymore; keep user's
                # environment clean
                unset __git_ps1_upstream_name
            fi
        fi
    fi

}

# Helper function that is meant to be called from __git_ps1.  It
# injects color codes into the appropriate gitstring variables used
# to build a gitstring.
__git_ps1_colorize_gitstring ()
{
    if [[ -n ${ZSH_VERSION-} ]]; then
        local c_red='%F{red}'
        local c_green='%F{green}'
        local c_lblue='%F{blue}'
        local c_clear='%f'
    else
        # Using \[ and \] around colors is necessary to prevent
        # issues with command line editing/browsing/completion!
        local c_red='\[\e[31m\]'
        local c_green='\[\e[32m\]'
        local c_lblue='\[\e[1;34m\]'
        local c_clear='\[\e[0m\]'
    fi
    local bad_color=$c_red
    local ok_color=$c_green
    local flags_color="$c_lblue"

    local branch_color=""
    if [ $detached = no ]; then
        branch_color="$ok_color"
    else
        branch_color="$bad_color"
    fi
    c="$branch_color$c"

    z="$c_clear$z"
    if [ "$w" = "*" ]; then
        w="$bad_color$w"
    fi
    if [ -n "$i" ]; then
        i="$ok_color$i"
    fi
    if [ -n "$s" ]; then
        s="$flags_color$s"
    fi
    if [ -n "$u" ]; then
        u="$bad_color$u"
    fi
    r="$c_clear$r"
}

__git_eread ()
{
    local f="$1"
    shift
    test -r "$f" && read "$@" <"$f"
}

# __git_ps1 accepts 0 or 1 arguments (i.e., format string)
# when called from PS1 using command substitution
# in this mode it prints text to add to bash PS1 prompt (includes branch name)
#
# __git_ps1 requires 2 or 3 arguments when called from PROMPT_COMMAND (pc)
# in that case it _sets_ PS1. The arguments are parts of a PS1 string.
# when two arguments are given, the first is prepended and the second appended
# to the state string when assigned to PS1.
# The optional third parameter will be used as printf format string to further
# customize the output of the git-status string.
# In this mode you can request colored hints using GIT_PS1_SHOWCOLORHINTS=true
__git_ps1 ()
{
    # preserve exit status
    local exit=$?
    local pcmode=no
    local detached=no
    local ps1pc_start='\u@\h:\w '
    local ps1pc_end='\$ '
    local printf_format=' (%s)'

    case "$#" in
        2|3)    pcmode=yes
            ps1pc_start="$1"
            ps1pc_end="$2"
            printf_format="${3:-$printf_format}"
            # set PS1 to a plain prompt so that we can
            # simply return early if the prompt should not
            # be decorated
            PS1="$ps1pc_start$ps1pc_end"
        ;;
        0|1)    printf_format="${1:-$printf_format}"
        ;;
        *)  return $exit
        ;;
    esac

    # ps1_expanded:  This variable is set to 'yes' if the shell
    # subjects the value of PS1 to parameter expansion:
    #
    #   * bash does unless the promptvars option is disabled
    #   * zsh does not unless the PROMPT_SUBST option is set
    #   * POSIX shells always do
    #
    # If the shell would expand the contents of PS1 when drawing
    # the prompt, a raw ref name must not be included in PS1.
    # This protects the user from arbitrary code execution via
    # specially crafted ref names.  For example, a ref named
    # 'refs/heads/$(IFS=_;cmd=sudo_rm_-rf_/;$cmd)' might cause the
    # shell to execute 'sudo rm -rf /' when the prompt is drawn.
    #
    # Instead, the ref name should be placed in a separate global
    # variable (in the __git_ps1_* namespace to avoid colliding
    # with the user's environment) and that variable should be
    # referenced from PS1.  For example:
    #
    #     __git_ps1_foo=$(do_something_to_get_ref_name)
    #     PS1="...stuff...\${__git_ps1_foo}...stuff..."
    #
    # If the shell does not expand the contents of PS1, the raw
    # ref name must be included in PS1.
    #
    # The value of this variable is only relevant when in pcmode.
    #
    # Assume that the shell follows the POSIX specification and
    # expands PS1 unless determined otherwise.  (This is more
    # likely to be correct if the user has a non-bash, non-zsh
    # shell and safer than the alternative if the assumption is
    # incorrect.)
    #
    local ps1_expanded=yes
    [ -z "${ZSH_VERSION-}" ] || [[ -o PROMPT_SUBST ]] || ps1_expanded=no
    [ -z "${BASH_VERSION-}" ] || shopt -q promptvars || ps1_expanded=no

    local repo_info rev_parse_exit_code
    repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
        --is-bare-repository --is-inside-work-tree \
        --short HEAD 2>/dev/null)"
    rev_parse_exit_code="$?"

    if [ -z "$repo_info" ]; then
        return $exit
    fi

    local short_sha=""
    if [ "$rev_parse_exit_code" = "0" ]; then
        short_sha="${repo_info##*$'\n'}"
        repo_info="${repo_info%$'\n'*}"
    fi
    local inside_worktree="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
    local bare_repo="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
    local inside_gitdir="${repo_info##*$'\n'}"
    local g="${repo_info%$'\n'*}"

    if [ "true" = "$inside_worktree" ] &&
       [ -n "${GIT_PS1_HIDE_IF_PWD_IGNORED-}" ] &&
       [ "$(git config --bool bash.hideIfPwdIgnored)" != "false" ] &&
       git check-ignore -q .
    then
        return $exit
    fi

    local r=""
    local b=""
    local step=""
    local total=""
    if [ -d "$g/rebase-merge" ]; then
        __git_eread "$g/rebase-merge/head-name" b
        __git_eread "$g/rebase-merge/msgnum" step
        __git_eread "$g/rebase-merge/end" total
        if [ -f "$g/rebase-merge/interactive" ]; then
            r="|REBASE-i"
        else
            r="|REBASE-m"
        fi
    else
        if [ -d "$g/rebase-apply" ]; then
            __git_eread "$g/rebase-apply/next" step
            __git_eread "$g/rebase-apply/last" total
            if [ -f "$g/rebase-apply/rebasing" ]; then
                __git_eread "$g/rebase-apply/head-name" b
                r="|REBASE"
            elif [ -f "$g/rebase-apply/applying" ]; then
                r="|AM"
            else
                r="|AM/REBASE"
            fi
        elif [ -f "$g/MERGE_HEAD" ]; then
            r="|MERGING"
        elif [ -f "$g/CHERRY_PICK_HEAD" ]; then
            r="|CHERRY-PICKING"
        elif [ -f "$g/REVERT_HEAD" ]; then
            r="|REVERTING"
        elif [ -f "$g/BISECT_LOG" ]; then
            r="|BISECTING"
        fi

        if [ -n "$b" ]; then
            :
        elif [ -h "$g/HEAD" ]; then
            # symlink symbolic ref
            b="$(git symbolic-ref HEAD 2>/dev/null)"
        else
            local head=""
            if ! __git_eread "$g/HEAD" head; then
                return $exit
            fi
            # is it a symbolic ref?
            b="${head#ref: }"
            if [ "$head" = "$b" ]; then
                detached=yes
                b="$(
                case "${GIT_PS1_DESCRIBE_STYLE-}" in
                (contains)
                    git describe --contains HEAD ;;
                (branch)
                    git describe --contains --all HEAD ;;
                (describe)
                    git describe HEAD ;;
                (* | default)
                    git describe --tags --exact-match HEAD ;;
                esac 2>/dev/null)" ||

                b="$short_sha..."
                b="($b)"
            fi
        fi
    fi

    if [ -n "$step" ] && [ -n "$total" ]; then
        r="$r $step/$total"
    fi

    local w=""
    local i=""
    local s=""
    local u=""
    local c=""
    local p=""

    if [ "true" = "$inside_gitdir" ]; then
        if [ "true" = "$bare_repo" ]; then
            c="BARE:"
        else
            b="GIT_DIR!"
        fi
    elif [ "true" = "$inside_worktree" ]; then
        if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] &&
           [ "$(git config --bool bash.showDirtyState)" != "false" ]
        then
            git diff --no-ext-diff --quiet || w="*"
            git diff --no-ext-diff --cached --quiet || i="+"
            if [ -z "$short_sha" ] && [ -z "$i" ]; then
                i="#"
            fi
        fi
        if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] &&
           git rev-parse --verify --quiet refs/stash >/dev/null
        then
            s="$"
        fi

        if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] &&
           [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] &&
           git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>/dev/null
        then
            u="%${ZSH_VERSION+%}"
        fi

        if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
            __git_ps1_show_upstream
        fi
    fi

    local z="${GIT_PS1_STATESEPARATOR-" "}"

    # NO color option unless in PROMPT_COMMAND mode
    if [ $pcmode = yes ] && [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
        __git_ps1_colorize_gitstring
    fi

    b=${b##refs/heads/}
    if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
        __git_ps1_branch_name=$b
        b="\${__git_ps1_branch_name}"
    fi

    local f="$w$i$s$u"
    local gitstring="$c$b${f:+$z$f}$r$p"

    if [ $pcmode = yes ]; then
        if [ "${__git_printf_supports_v-}" != yes ]; then
            gitstring=$(printf -- "$printf_format" "$gitstring")
        else
            printf -v gitstring -- "$printf_format" "$gitstring"
        fi
        PS1="$ps1pc_start$gitstring$ps1pc_end"
    else
        printf -- "$printf_format" "$gitstring"
    fi

    return $exit
}



# colors!
green="\[\033[0;32m\]"
blue="\[\033[0;34m\]"
purple="\[\033[0;35m\]"
reset="\[\033[0m\]"

# Change command prompt
export GIT_PS1_SHOWDIRTYSTATE=1
# '\u' adds the name of the current user to the prompt
# '\$(__git_ps1)' adds git-related stuff
# '\W' adds the name of the current directory
#export PS1="$purple\u$green\$(__git_ps1)$blue \W $ $reset"

PS1="tty:[\e[1;36m\l\e[0m] jobs:[\e[1;36m\j\e[0m] cwd:[\e[1;36m\w\e[0m]$green\$(__git_ps1)$reset\n$blue`date +%H:%M`$reset [\u@$purple`hostname`$reset] $ "