#!/bin/bash

LOCAL_DEV_DIR=$HOME/.mustardgrain/dev

function switch-client-env() {
  if [ ! -d "$LOCAL_DEV_DIR" ] ; then
    echo "Please symlink $LOCAL_DEV_DIR to your local development directory root"
    exit 1
  fi

  env=$1
  orig_pwd=`pwd`
  cd $LOCAL_DEV_DIR
  LOCAL_DEV_DIR=`pwd -P`
  cd $LOCAL_DEV_DIR
  root_pwd=$LOCAL_DEV_DIR/$env/${env}-env

  if [ "$env" = "" ] ; then
    echo "Please specify the client environment"
    return
  fi

  if [ ! -d "$root_pwd" ] ; then
    echo "Can't switch to the $env client environment - directory $root_pwd doesn't exist"
    return
  fi

  if [ ! -f "$root_pwd/client-env.sh" ] ; then
    echo "Can't switch to the $env client environment - directory $root_pwd doesn't contain a client-env.sh file"
    return
  fi

  source $root_pwd/client-env.sh

  PS1="($env) $DEFAULT_PS1"

  cd "$orig_pwd"
}

function _switch_client_env_completion() {
  if [ ! -d "$LOCAL_DEV_DIR" ] ; then
    echo "Please symlink $LOCAL_DEV_DIR to your local development directory root"
    exit 1
  fi

  # Look at the list of directories in $HOME/dev
  orig_pwd=`pwd`
  cd "$LOCAL_DEV_DIR"
  cd `pwd -P`
  find . -type d -name "*-env" | awk -F/ '{print $2}'
  cd "$orig_pwd"
}

complete -W "$(_switch_client_env_completion)" switch-client-env
