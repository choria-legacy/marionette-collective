_mco() {
  local agents options

  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}

  # Where are the plugins?
  local libdir=$(sed -n 's@libdir = @@p' /etc/mcollective/client.cfg)

  # All arguments by options
  noopt=($(tr ' ' '\n' <<<${COMP_WORDS[@]} | \
    grep -v "^$cur$" | grep -v -- '^-'))

  local count_noopt=${#noopt[@]}
  local cmd=${noopt[0]}
  local agent=${noopt[1]}

  # A bug in the output of --help prevents
  # from parsing all options, so we list the common ones here
  local common_options="-T --target -c --config --dt --discovery-timeout \
    -t --timeout -q --quiet -v --verbose -h --help -W --with -F \
    --wf --with-fact -C --wc --with-class -A --wa --with-agent -I \
    --wi --with-identity"

  if [ $COMP_CWORD -eq 1 ]; then
    agents=$($cmd | sed -n 's@Known commands: @@p')
    COMPREPLY=($(compgen -W "$agents" -- "$cur"))
  elif [ $COMP_CWORD -gt 1 ]; then
    options="${common_options} $($cmd $agent --help | grep -o -- '-[^, ]\+')"

    if [ "x${agent}" = "xrpc" ]; then
      if [[ $count_noopt -eq 2 || "x${prev}" = "x--agent" ]]; then
        # Complete with agents
        agents=$(ls $libdir/mcollective/agent | sed -n 's@\.ddl@@p')
        options="$options $agents"
      elif [[ $count_noopt -eq 3 || "x${prev}" = "x--action" ]]; then
        # Complete with agent actions
        rpcagent=${noopt[2]}
        actions=$(sed -n "s@^action [\"']\([^\"']\+\).*@\1@p" \
          "$libdir/mcollective/agent/$rpcagent.ddl" 2>/dev/null)
        options="$options $actions"
      elif [ $count_noopt -gt 3 ]; then
        # Complete with key=value
        rpcagent=${noopt[2]}
        rpcaction=${noopt[3]}
        inputs=$(sed -n "/^action [\"']${rpcaction}.*/,/^end$/p" \
          "$libdir/mcollective/agent/$rpcagent.ddl" 2>/dev/null | \
          sed -n 's@[\t ]*input[\t ]\+:\([^,]\+\),.*@\1=@p')
        options="$options $inputs"
      fi
    fi

    COMPREPLY=($(compgen -W "$options" -S ' ' -- "$cur"))
  fi
}
[ -n "${have:-}" ] && complete -o nospace -F _mco mco

