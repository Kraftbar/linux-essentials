
# ------------------------------------





fuzzy_command_search() {
    # ---------- Configuration ----------
    HISTORY_FILE="$HOME/.bash_history"
    current_cmd_index=0
    cmd_matches=''
    declare -a current_cursor_position

    # ---------- Cursor Management Functions ----------

    extract_current_cursor_position() {
        # Capture the cursor position after printing the prompt
        IFS=';' read -sdR -p $'\E[6n' row col
        current_cursor_position[0]=$(( ${row#*[} - 1 ))
        current_cursor_position[1]=$(( col - 1 ))
    }

    reposition_cursor() {
        # Move the cursor back to the input line
        tput cup "${current_cursor_position[0]}" "$(( current_cursor_position[1] + ${#search_string} ))"
    }

    # ---------- User Interface Functions ----------

    flush_screen() {
        # Clear from cursor to end of screen
        tput ed
    }

    capture_user_input() {
        # Clear any pending input
        read -t 0 -n 1000 discard

        while IFS= read -rsn1 char; do
            if [ "$char" = $'\x7f' ]; then  # Backspace
                if [ -n "$search_string" ]; then
                    tput cub1
                    echo -n ' '
                    tput cub1
                    search_string="${search_string%?}"
                fi
            elif [ "$char" = $'\n' ]; then  # Enter
                selected_line=$(echo "$cmd_matches" | sed -n "$(( current_cmd_index + 1 ))p")
                # Move cursor below the suggestions before executing
                tput cup $(( current_cursor_position[0] + 5 )) 0
                echo
                eval "$selected_line"
                return
            elif [ "$char" = $'\x1b' ]; then  # Escape character
                read -rsn2 next_chars
                escape_sequence="$char$next_chars"
                if [ "$escape_sequence" = $'\x1b[A' ]; then  # Up arrow
                    if [ $current_cmd_index -gt 0 ]; then
                        current_cmd_index=$(( current_cmd_index - 1 ))
                    fi
                elif [ "$escape_sequence" = $'\x1b[B' ]; then  # Down arrow
                    max_index=$(( $(echo "$cmd_matches" | wc -l) - 1 ))
                    if [ $current_cmd_index -lt $max_index ]; then
                        current_cmd_index=$(( current_cmd_index + 1 ))
                    fi
                fi
            else
                search_string="$search_string$char"
                echo -n "$char"
            fi

            display_search_results
            reposition_cursor
        done
    }

    # ---------- Search Logic ----------

    print_matches() {
        local count=0
        while IFS= read -r line; do
            # Move cursor to the correct line
            tput cup $(( current_cursor_position[0] + 1 + count )) 0
            # Clear the line
            tput el
            # Display the line
            if [ "$current_cmd_index" -eq "$count" ]; then
                echo -e "> $line"
            else
                echo "  $line"
            fi
            count=$(( count + 1 ))
            [ "$count" -ge 5 ] && break
        done <<< "$cmd_matches"
    }

    fuzzy_search() {
        if [ -z "$search_string" ]; then
            cmd_matches=$(tac "$HISTORY_FILE" | awk '!seen[$0]++' | head -5)
        else
            cmd_matches=$(grep -i "$search_string" "$HISTORY_FILE" | tac | awk '!seen[$0]++' | head -5)
        fi
    }

    display_search_results() {
        fuzzy_search
        flush_screen
        print_matches
    }

    # ---------- Main Function Execution ----------

    history -a "$HISTORY_FILE"
    search_string=""

    # Ensure PS1 is available
    [ -z "$PS1" ] && export PS1='\u@\h:\w\$ '

    # Expand and print the prompt correctly
    if [ "${BASH_VERSINFO:-0}" -ge 5 ] || { [ "${BASH_VERSINFO:-0}" -eq 4 ] && [ "${BASH_VERSINFO[1]:-0}" -ge 4 ]; }; then
        printf "%s" "${PS1@P}"
    else
        CLEAN_PS1=$(sed 's/\\\[\(.*\)\\\]//g' <<< "$PS1")
        eval "printf '%b' \"$CLEAN_PS1\""
    fi

    # Capture the initial cursor position after printing the prompt
    extract_current_cursor_position

    # Start capturing user input
    capture_user_input
}


bind -x '"\C-r":fuzzy_command_search'
# ------------------------------------


