# Minimal, host-neutral Powerlevel10k configuration.
'typeset' -g POWERLEVEL9K_MODE=nerdfont-complete
'typeset' -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
'typeset' -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)
'typeset' -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
'typeset' -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='╭─'
'typeset' -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='╰─%F{cyan}❯%f '
'typeset' -g POWERLEVEL9K_DIR_FOREGROUND=33
'typeset' -g POWERLEVEL9K_DISABLE_GITSTATUS=true
# Keep VCS information on zsh's built-in backend; no helper binary is fetched.
'typeset' -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
'typeset' -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178
'typeset' -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
'typeset' -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
'typeset' -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
'typeset' -g POWERLEVEL9K_INSTANT_PROMPT=quiet
'typeset' -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
