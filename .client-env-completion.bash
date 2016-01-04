#!/bin/bash

DEFAULT_PS1=$PS1

function __client-env-symlinker() {
  client=$1
  dir=$2
  file=$3

  if [ -f $dir/$file ] ; then
    result=`file -hb $dir/$file | grep "^symbolic link"`

    if [ $? -ne 0 ] ; then
      echo "Not removing $dir/$file as it is not a symbolic link"
      return 1
    fi
  fi

  mkdir -p $dir
  cd $dir
  rm -f $file
  ln -s $LOCAL_DEV_DIR/$client/${client}-env/conf/$file
}

function client-env-set() {
  client=$1

  if [ "$client" = "" ] ; then
    echo "Please specify the client environment"
    return 1
  fi

  orig_pwd=`pwd`

  cd $LOCAL_DEV_DIR

  if [ -d "$LOCAL_DEV_DIR/$client" ] ; then
    cd $LOCAL_DEV_DIR/$client

    if [ -d "$client-env/bin" ] ; then
      cd $client-env/bin
      export PATH="`pwd -P`:$PATH"
      cd ../..
    fi

    if [ -f "$client-env/conf/client-env.sh" ] ; then
      source $client-env/conf/client-env.sh
    fi

    PS1="($client) $DEFAULT_PS1"

    if [ ! -L "$HOME/.current-client-env" ] ; then
      # Make our current client setting sticky. Remember to go back
      # to the LOCAL_DEV_DIR directory because the above source
      # could leave us in an arbitrary directory :\
      cd $HOME
      ln -s $LOCAL_DEV_DIR/$client .current-client-env
    fi
  else
    echo "Could not find $client in $LOCAL_DEV_DIR"
  fi

  cd "$orig_pwd"
}

function client-env-clear() {
  rm -f $HOME/.current-client-env
}

function _client_env_set_completion() {
  # Look at the list of directories in $LOCAL_DEV_DIR
  orig_pwd=`pwd`

  cd "$LOCAL_DEV_DIR"
  ls -1 | grep -v "go"

  cd "$orig_pwd"
}

complete -W "$(_client_env_set_completion)" client-env-set

if [ -L "$HOME/.current-client-env" ] ; then
  client-env-set $(basename `readlink $HOME/.current-client-env`)
fi
