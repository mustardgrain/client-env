#!/bin/bash

# Log levels
__CLIENT_ENV_LOG_LEVEL_DEBUG=1
__CLIENT_ENV_LOG_LEVEL_INFO=2
__CLIENT_ENV_LOG_LEVEL_WARN=3
__CLIENT_ENV_LOG_LEVEL_ERROR=4
__CLIENT_ENV_LOG_LEVEL_NONE=5

if [ "$CLIENT_ENV_LOG_LEVEL" = "" ] ; then
  CLIENT_ENV_LOG_LEVEL=$__CLIENT_ENV_LOG_LEVEL_NONE
fi

function __client-env-log-debug() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_DEBUG ] ; then
    echo "$(date) - DEBUG: $1"
  fi
}

function __client-env-log-info() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_INFO ] ; then
    echo "$(date) - INFO:  $1"
  fi
}

function __client-env-log-warn() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_WARN ] ; then
    echo "$(date) - WARN:  $1"
  fi
}

function __client-env-log-error() {
  if [ $CLIENT_ENV_LOG_LEVEL -le $__CLIENT_ENV_LOG_LEVEL_ERROR ] ; then
    echo "$(date) - ERROR: $1"
  fi
}

if [ "$LOCAL_DEV_DIR" = "" ] ; then
  echo "Please set the LOCAL_DEV_DIR environment variable before using client-env"
  return 2
fi

function __client-init-dirs() {
  local client=`__client-env-get-client`
  export CLIENT_ENV_TOUCH_FILE=/tmp/.client-env-${client}
  export CLIENT_ENV_CLIENT_DIR=$LOCAL_DEV_DIR/$client
  export CLIENT_ENV_CONF_DIR=$CLIENT_ENV_CLIENT_DIR/$client-env/conf
  export CLIENT_ENV_CONF_LOCAL_DIR=$CLIENT_ENV_CONF_DIR/local
}

function __client-env-get-client() {
  if [ -L "$HOME/.current-client-env" ] ; then
    echo $(basename `readlink $HOME/.current-client-env`)
    return 0
  else
    echo "Please make sure to have called client-env-set before using client-env functions"
    return 3
  fi
}

function __client-env-source() {
  local source_file=$1

  if [ ! -f "$source_file" ] ; then
    echo "Please ensure that $source_file is present"
    return 1
  fi

  __client-env-log-debug "Sourcing $source_file"
  source $source_file

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
  local client=`__client-env-get-client`
  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ -f $dst_file_name ] ; then
    __client-env-log-warn "Not copying $src_file_name to $dst_file_name as $dst_file_name is already present"
    return 1
  fi

  mkdir -p $dst_dir
  cp $src_file_name $dst_file_name
  __client-env-log-info "Copied $src_file_name to $dst_file_name"
}

function __client-env-rm() {
  local client=`__client-env-get-client`
  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ ! -f $dst_file_name ] ; then
    __client-env-log-warn "Not removing $dst_file_name as it is not present"
    return 1
  fi

  rm $dst_file_name
  __client-env-log-info "Removed $dst_file_name"
}

function __client-env-symlink-add() {
  local client=`__client-env-get-client`
  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ -f $dst_file_name ] ; then
    echo "Not linking $src_file_name to $dst_file_name as $dst_file_name is already present"
    return 1
  fi

  mkdir -p $dst_dir
  ln -s $src_file_name $dst_file_name
}

function __client-env-symlink-rm() {
  local client=`__client-env-get-client`
  local dst_dir=$1
  local file_name=$2
  local dst_file_name=$dst_dir/$file_name

  if [ ! -L "$dst_file_name" ] ; then
    echo "Not removing $dst_file_name as it is not a symbolic link"
    return 1
  fi

  rm $dst_file_name
}

function __client-env-ssh-add() {
  local ssh_key_file_name=$1
  local tmp_file=`mktemp`

  if [ $(uname) = 'Linux' ] ; then
    local file_name_match_count=$(ssh-add -l "$ssh_key_file_name" | grep -c "$ssh_key_file_name")

    if [ $file_name_match_count -gt 0 ] ; then
      ssh-add "$ssh_key_file_name" 2>$tmp_file
    fi
  elif [ $(uname) = 'Darwin' ] ; then
    local fingerprint=$(ssh-keygen -lf "$ssh_key_file_name")
    local fingerprint_count=$(ssh-add -l | grep -c "$fingerprint")
    local file_name_match_count=$(ssh-add -l | grep -c "$ssh_key_file_name")

    __client-env-log-debug "Fingerprint: $fingerprint"
    __client-env-log-debug "Fingerprint count: $fingerprint_count"
    __client-env-log-debug "File name match count: $file_name_match_count"

    if [ $fingerprint_count = 0 -a $file_name_match_count = 0 ] ; then
      ssh-add -K "$ssh_key_file_name" 2>$tmp_file

      __client-env-log-info "Added SSH key $ssh_key_file_name to SSH agent"
    else
      __client-env-log-info "$ssh_key_file_name previously added to SSH agent, no need to add"
    fi
  fi

  if [ $? != 0 ] ; then
    cat $tmp_file
  fi

  rm -f $tmp_file
}

function __client-env-ssh-delete() {
  local ssh_key_file_name=$1
  local tmp_file=`mktemp`

  if [ $(uname) = 'Linux' ] ; then
    local file_name_match_count=$(ssh-add -l "$ssh_key_file_name" | grep -c "$ssh_key_file_name")

    if [ $file_name_match_count -gt 0 ] ; then
      ssh-add -d "$ssh_key_file_name" 2>$tmp_file
    fi
  elif [ $(uname) = 'Darwin' ] ; then
    local fingerprint=$(ssh-keygen -lf "$ssh_key_file_name")
    local fingerprint_count=$(ssh-add -l | grep -c "$fingerprint")
    local file_name_match_count=$(ssh-add -l | grep -c "$ssh_key_file_name")

    __client-env-log-debug "Fingerprint: $fingerprint"
    __client-env-log-debug "Fingerprint count: $fingerprint_count"
    __client-env-log-debug "File name match count: $file_name_match_count"

    if [ $fingerprint_count -gt 0 -o $file_name_match_count -gt 0 ] ; then
      ssh-add -d "$ssh_key_file_name" 2>$tmp_file

      __client-env-log-info "Deleted SSH key $ssh_key_file_name from SSH agent"
    else
      __client-env-log-info "$ssh_key_file_name not previously added to SSH agent, no need to delete"
    fi
  fi

  if [ $? != 0 ] ; then
    cat $tmp_file
  fi

  rm -f $tmp_file
}

function client-env-set() {
  local client=$1

  if [ "$client" = "" ] ; then
    echo "Please specify the client environment"
    return 1
  fi

  if [ ! -d "$LOCAL_DEV_DIR/$client" ] ; then
    __client-env-log-error "Could not find $client in $LOCAL_DEV_DIR"
    return
  fi

  local orig_pwd="`pwd`"

  cd $LOCAL_DEV_DIR/$client

  if [ -d "$client-env/bin" ] ; then
    cd $client-env/bin
    export PATH="`pwd -P`:$PATH"
    cd $LOCAL_DEV_DIR/$client
  fi

  PS1="($client) $PS1"

  if [ ! -L "$HOME/.current-client-env" ] ; then
    cd $HOME
    ln -s $LOCAL_DEV_DIR/$client .current-client-env
    cd $LOCAL_DEV_DIR/$client
  fi

  if [ -f "$client-env/conf/client-env-set.sh" ] ; then
    source $client-env/conf/client-env-set.sh
    cd $LOCAL_DEV_DIR/$client
  fi

  cd "$orig_pwd"
}

function client-env-clear() {
  if [ -L "$HOME/.current-client-env" ] ; then
    local client=$(basename `readlink $HOME/.current-client-env`)
    local orig_pwd="`pwd`"

    if [ -f "$LOCAL_DEV_DIR/$client/$client-env/conf/client-env-clear.sh" ] ; then
      source $LOCAL_DEV_DIR/$client/$client-env/conf/client-env-clear.sh
    fi

    rm -f $HOME/.current-client-env
    cd "$orig_pwd"
  fi

  PS1=`echo "$PS1" | sed "s@[(]$client[)] @@"`
}

function client-env-ls() {
  # Look at the list of directories in $LOCAL_DEV_DIR
  local orig_pwd="`pwd`"

  cd "$LOCAL_DEV_DIR"

  for client in `ls -1 | grep -v "go"` ; do
    if [ -d "$LOCAL_DEV_DIR/$client/${client}-env" ] ; then
      echo $client
    fi
  done

  cd "$orig_pwd"
}

function client-env-print() {
  if [ -L "$HOME/.current-client-env" ] ; then
    basename `readlink $HOME/.current-client-env`
  fi
}

complete -W "$(client-env-ls)" client-env-set

if [ -L "$HOME/.current-client-env" ] ; then
  client-env-set $(basename `readlink $HOME/.current-client-env`)
fi
