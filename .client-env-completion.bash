#!/bin/bash

# Log levels
__CLIENT_ENV_LOG_LEVEL_DEBUG=1
__CLIENT_ENV_LOG_LEVEL_INFO=2
__CLIENT_ENV_LOG_LEVEL_WARN=3
__CLIENT_ENV_LOG_LEVEL_ERROR=4

if [ "$CLIENT_ENV_LOG_LEVEL" = "" ] ; then
  CLIENT_ENV_LOG_LEVEL=$__CLIENT_ENV_LOG_LEVEL_WARN
fi

CLIENT_ENV_CONFIG_DIR=$HOME/.config/client-env
mkdir -p "$CLIENT_ENV_CONFIG_DIR"

export CLIENT_ENV_CURRENT_FILE=$CLIENT_ENV_CONFIG_DIR/current
export CLIENT_ENV_TOUCH_FILE=$CLIENT_ENV_CONFIG_DIR/touch

function __client-env-log-debug() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_DEBUG ] ; then
    echo "$1"
  fi
}

function __client-env-log-info() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_INFO ] ; then
    echo "$1"
  fi
}

function __client-env-log-warn() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_WARN ] ; then
    echo "$1"
  fi
}

function __client-env-log-error() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_ERROR ] ; then
    echo "$1"
  fi
}

if [ "$LOCAL_DEV_DIR" = "" ] ; then
  __client-env-log-error "Please set the LOCAL_DEV_DIR environment variable before using client-env"
  return 2
fi

function __client-init-dirs() {
  __client-env-log-warn "__client-init-dirs is deprecated; use __client-env-init-dirs instead"
  __client-env-init-dirs
}

function __client-env-init-dirs() {
  local client

  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    client=$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")
  else
    __client-env-log-error "Please make sure to have called client-env-set before using client-env functions"
    return
  fi

  export CLIENT_ENV_CLIENT_DIR=$LOCAL_DEV_DIR/$client
  export CLIENT_ENV_ENV_DIR=$CLIENT_ENV_CLIENT_DIR/$client-env
  export CLIENT_ENV_BIN_DIR=$CLIENT_ENV_ENV_DIR/bin
  export CLIENT_ENV_CONF_DIR=$CLIENT_ENV_ENV_DIR/conf
  export CLIENT_ENV_CONF_LOCAL_DIR=$CLIENT_ENV_CONF_DIR/local
  export CLIENT_ENV_LOGS_DIR=$CLIENT_ENV_ENV_DIR/logs
  export CLIENT_ENV_NOTES_DIR=$CLIENT_ENV_ENV_DIR/notes
}

function __client-env-source() {
  local source_file=$1

  if [ ! -f "$source_file" ] ; then
    __client-env-log-error "Please ensure that $source_file is present"
    return 1
  fi

  __client-env-log-debug "Sourcing $source_file"
  source "$source_file"

  shift 1

  for expected_env_var in "$@" ; do
    expected_env_var_value=${!expected_env_var}

    __client-env-log-debug "$expected_env_var in $source_file: $expected_env_var_value"

    if [ "$expected_env_var_value" = "" ] ; then
      __client-env-log-error "Please export $expected_env_var in $source_file"
      return 2
    fi
  done
}

function __client-env-cp() {
  __client-env-log-warn "__client-env-cp is deprecated"

  local client

  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    client=$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")
  else
    __client-env-log-error "Please make sure to have called client-env-set before using client-env functions"
    return
  fi

  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ -f "$dst_file_name" ] ; then
    __client-env-log-warn "Not copying $src_file_name to $dst_file_name as $dst_file_name is already present"
    return 1
  fi

  mkdir -p "$dst_dir"
  cp "$src_file_name" "$dst_file_name"
  __client-env-log-info "Copied $src_file_name to $dst_file_name"
}

function __client-env-rm() {
  __client-env-log-warn "__client-env-rm is deprecated"

  local client

  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    client=$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")
  else
    __client-env-log-error "Please make sure to have called client-env-set before using client-env functions"
    return
  fi

  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ ! -f "$dst_file_name" ] ; then
    __client-env-log-warn "Not removing $dst_file_name as it is not present"
    return 1
  fi

  rm "$dst_file_name"
  __client-env-log-info "Removed $dst_file_name"
}

function __client-env-symlink-add() {
  __client-env-log-warn "__client-env-symlink-add is deprecated"

  local client

  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    client=$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")
  else
    __client-env-log-error "Please make sure to have called client-env-set before using client-env functions"
    return
  fi

  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ -f "$dst_file_name" ] ; then
    __client-env-log-warn "Not linking $src_file_name to $dst_file_name as $dst_file_name is already present"
    return 1
  fi

  mkdir -p "$dst_dir"
  ln -s "$src_file_name" "$dst_file_name"
}

function __client-env-symlink-rm() {
  __client-env-log-warn "__client-env-symlink-rm is deprecated"

  local client

  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    client=$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")
  else
    __client-env-log-error "Please make sure to have called client-env-set before using client-env functions"
    return
  fi

  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name

  if [ ! -L "$dst_file_name" ] ; then
    __client-env-log-warn "Not removing $dst_file_name as it is not a symbolic link"
    return 1
  fi

  rm "$dst_file_name"
}

function __client-env-ssh-add() {
  local ssh_key_file_name
  local tmp_file
  ssh_key_file_name=$1
  tmp_file=$(mktemp)

  if [ "$(uname)" = 'Linux' ] ; then
    local file_name_match_count
    file_name_match_count=$(ssh-add -l "$ssh_key_file_name" | grep -c "$ssh_key_file_name")

    if [ "$file_name_match_count" -gt 0 ] ; then
      ssh-add "$ssh_key_file_name" 2>"$tmp_file"
    fi
  elif [ "$(uname)" = 'Darwin' ] ; then
    local fingerprint
    local fingerprint_count
    local file_name_match_count
    fingerprint=$(ssh-keygen -lf "$ssh_key_file_name")
    fingerprint_count=$(ssh-add -l | grep -c "$fingerprint")
    file_name_match_count=$(ssh-add -l | grep -c "$ssh_key_file_name")

    __client-env-log-debug "Fingerprint: $fingerprint"
    __client-env-log-debug "Fingerprint count: $fingerprint_count"
    __client-env-log-debug "File name match count: $file_name_match_count"

    if [ "$fingerprint_count" = 0 ] && [ "$file_name_match_count" = 0 ] ; then
      ssh-add -K "$ssh_key_file_name" 2>"$tmp_file"

      __client-env-log-info "Added SSH key $ssh_key_file_name to SSH agent"
    else
      __client-env-log-info "$ssh_key_file_name previously added to SSH agent, no need to add"
    fi
  fi

  if [ $? != 0 ] ; then
    cat "$tmp_file"
  fi

  rm -f "$tmp_file"
}

function __client-env-ssh-delete() {
  local ssh_key_file_name
  local tmp_file
  ssh_key_file_name=$1
  tmp_file=$(mktemp)

  if [ "$(uname)" = 'Linux' ] ; then
    local file_name_match_count
    file_name_match_count=$(ssh-add -l "$ssh_key_file_name" | grep -c "$ssh_key_file_name")

    if [ "$file_name_match_count" -gt 0 ] ; then
      ssh-add -d "$ssh_key_file_name" 2>"$tmp_file"
    fi
  elif [ "$(uname)" = 'Darwin' ] ; then
    local fingerprint
    local fingerprint_count
    local file_name_match_count
    fingerprint=$(ssh-keygen -lf "$ssh_key_file_name")
    fingerprint_count=$(ssh-add -l | grep -c "$fingerprint")
    file_name_match_count=$(ssh-add -l | grep -c "$ssh_key_file_name")

    __client-env-log-debug "Fingerprint: $fingerprint"
    __client-env-log-debug "Fingerprint count: $fingerprint_count"
    __client-env-log-debug "File name match count: $file_name_match_count"

    if [ "$fingerprint_count" -gt 0 ] || [ "$file_name_match_count" -gt 0 ] ; then
      ssh-add -d "$ssh_key_file_name" 2>"$tmp_file"

      __client-env-log-info "Deleted SSH key $ssh_key_file_name from SSH agent"
    else
      __client-env-log-info "$ssh_key_file_name not previously added to SSH agent, no need to delete"
    fi
  fi

  if [ $? != 0 ] ; then
    cat "$tmp_file"
  fi

  rm -f "$tmp_file"
}

function __client-env-write-aws-ini-file() {
  local file_name
  local section_name
  local parent_dir_name
  file_name="$1"
  section_name="$2"
  parent_dir_name=$(dirname "$file_name")

  __client-env-log-debug "mkdir-ing parent directory $parent_dir_name"
  mkdir -p "$parent_dir_name"

  cat << EOF > "$file_name"
[$section_name]
aws_access_key_id = $AWS_ACCESS_KEY
aws_secret_access_key = $AWS_SECRET_KEY
EOF
}

function client-env-set() {
  local client
  client=$1

  if [ "$client" = "" ] ; then
    echo "Please specify the client environment"
    return 1
  fi

  if [ ! -d "$LOCAL_DEV_DIR/$client" ] ; then
    __client-env-log-error "Could not find $client in $LOCAL_DEV_DIR"
    return
  fi

  local orig_pwd
  orig_pwd="$(pwd)"

  cd "$LOCAL_DEV_DIR/$client" || exit

  if [ -d "$client-env/bin" ] ; then
    cd "$client-env/bin" || exit
    PATH="$(pwd -P):$PATH"
    export PATH
    cd "$LOCAL_DEV_DIR/$client" || exit
  fi

  if [ ! -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    cd "$HOME" || exit
    ln -s "$LOCAL_DEV_DIR/$client" "$CLIENT_ENV_CURRENT_FILE"
    cd "$LOCAL_DEV_DIR/$client" || exit
  fi

  if [ -f "$client-env/conf/client-env-set.sh" ] ; then
    source "$client-env/conf/client-env-set.sh"
    cd "$LOCAL_DEV_DIR/$client" || exit
  fi

  cd "$orig_pwd" || exit
}

function client-env-clear() {
  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    local client
    local orig_pwd
    client="$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")"
    orig_pwd="$(pwd)"

    if [ -f "$LOCAL_DEV_DIR/$client/$client-env/conf/client-env-clear.sh" ] ; then
      source "$LOCAL_DEV_DIR/$client/$client-env/conf/client-env-clear.sh"
    fi

    rm -f "$CLIENT_ENV_CURRENT_FILE"
    cd "$orig_pwd" || exit
  fi
}

function client-env-touch-new-note() {
  if [ "$CLIENT_ENV_NOTES_DIR" = "" ] ; then
    __client-env-log-error "Please make sure to have called client-env-set before using client-env functions"
    return
  fi

  local new_note="$CLIENT_ENV_NOTES_DIR/$(date +%Y/%m/%Y-%m-%d).md"
  mkdir -p "$(dirname "$new_note")"
  touch "$new_note"
  echo "Created $new_note to edit."
}

function client-env-ls() {
  # Look at the list of directories in $LOCAL_DEV_DIR
  local orig_pwd
  orig_pwd="$(pwd)"

  cd "$LOCAL_DEV_DIR" || exit

  for client in * ; do
    if [ -d "$LOCAL_DEV_DIR/$client/${client}-env" ] ; then
      echo "$client"
    fi
  done

  cd "$orig_pwd" || exit
}

function client-env-print() {
  if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
    basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")"
  fi
}

complete -W "$(client-env-ls)" client-env-set

if [ -L "$CLIENT_ENV_CURRENT_FILE" ] ; then
  client-env-set "$(basename "$(readlink "$CLIENT_ENV_CURRENT_FILE")")"
fi
