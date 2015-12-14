#!/bin/bash

LOCAL_BIN_ROOT_DIR=$HOME/.mustardgrain/bin
LOCAL_ENV_ROOT_DIR=$HOME/.mustardgrain/env

DEFAULT_PS1=$PS1

function client-env-set() {
  client=$1

  if [ "$client" = "" ] ; then
    echo "Please specify the client environment"
    return 1
  fi

  orig_pwd=`pwd`
  has_flag=0

  cd $LOCAL_BIN_ROOT_DIR
  LOCAL_BIN_ROOT_DIR=`pwd -P`

  if [ -d "$LOCAL_BIN_ROOT_DIR/$client/bin" ] ; then
    cd $LOCAL_BIN_ROOT_DIR/$client/bin
    export PATH="`pwd -P`:$PATH"
    has_flag=1
  fi

  cd $LOCAL_ENV_ROOT_DIR
  LOCAL_ENV_ROOT_DIR=`pwd -P`

  if [ -f "$LOCAL_ENV_ROOT_DIR/$client/client-env.sh" ] ; then
    source $LOCAL_ENV_ROOT_DIR/$client/client-env.sh
    has_flag=1
  fi

  if [ $has_flag -eq 1 ] ; then
    PS1="($client) $DEFAULT_PS1"
  else
    echo "Could not find $client in $LOCAL_BIN_ROOT_DIR or $LOCAL_ENV_ROOT_DIR"
  fi

  if [ ! -L "$LOCAL_ENV_ROOT_DIR/current" ] ; then
    # Make our current client setting sticky. Remember to go back
    # to the LOCAL_ENV_ROOT_DIR directory because the above source
    # could leave us in an arbitrary directory :\
    cd $LOCAL_ENV_ROOT_DIR
    ln -s $client current
  fi

  cd "$orig_pwd"
}

function client-env-clear() {
  rm -f $LOCAL_ENV_ROOT_DIR/current
}

function _client_env_set_completion() {
  # Look at the list of directories in $HOME/.mustardgrain/bin and
  # $HOME/.mustardgrain/env
  orig_pwd=`pwd`

  cd "$LOCAL_BIN_ROOT_DIR"
  ls -1 | grep -v "current"

  cd "$LOCAL_ENV_ROOT_DIR"
  ls -1 | grep -v "current"

  cd "$orig_pwd"
}

complete -W "$(_client_env_set_completion)" client-env-set

if [ -L "$LOCAL_ENV_ROOT_DIR/current" ] ; then
  client-env-set `readlink $LOCAL_ENV_ROOT_DIR/current`
fi
