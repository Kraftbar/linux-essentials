# NOT TESTED
# 1. Log both input and output
if [ -z "$SCRIPT_LOGGING_STARTED" ] && [ -n "$PS1" ]; then
    export SCRIPT_LOGGING_STARTED=1
    script -q -a ~/terminal_session_$(date +%F_%T).log
    exit
fi

# 2. Prevent multiline commands in history
shopt -u cmdhist

# 3. Write history to disk after each command
export PROMPT_COMMAND='history -a; history -n'
