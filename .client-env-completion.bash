#!/bin/bash

function __client-env-cp() {
  local client=$1
  local dst_dir=$2
  local file_name=$3
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ -f $dst_file_name ] ; then
    echo "Not copying $src_file_name to $dst_file_name as $dst_file_name is already present"
    return 1
  fi

  mkdir -p $dst_dir
  cp $src_file_name $dst_file_name
}

function __client-env-rm() {
  local client=$1
  local dst_dir=$2
  local file_name=$3
  local dst_file_name=$dst_dir/$file_name
  local src_file_name=$LOCAL_DEV_DIR/$client/${client}-env/conf/$file_name

  if [ ! -f $dst_file_name ] ; then
    echo "Not removing $dst_file_name as it is not present"
    return 1
  fi

  rm $dst_file_name
}

function __client-env-symlink-add() {
  local client=$1
  local dst_dir=$2
  local file_name=$3
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
  local client=$1
  local dst_dir=$2
  local file_name=$3
  local dst_file_name=$dst_dir/$file_name

  if [ ! -L "$dst_file_name" ] ; then
    echo "Not removing $dst_file_name as it is not a symbolic link"
    return 1
  fi

  rm $dst_file_name
}

function client-env-set() {
  local client=$1

  if [ "$client" = "" ] ; then
    echo "Please specify the client environment"
    return 1
  fi

  local orig_pwd="`pwd`"

  if [ -d "$LOCAL_DEV_DIR/$client" ] ; then
    cd $LOCAL_DEV_DIR/$client

    if [ -d "$client-env/bin" ] ; then
      cd $client-env/bin
      export PATH="`pwd -P`:$PATH"
      cd ../..
    fi

    if [ -f "$client-env/conf/client-env-set.sh" ] ; then
      source $client-env/conf/client-env-set.sh
    fi

    PS1="($client) $PS1"

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

function _client_env_set_completion() {
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

complete -W "$(_client_env_set_completion)" client-env-set

if [ -L "$HOME/.current-client-env" ] ; then
  client-env-set $(basename `readlink $HOME/.current-client-env`)
fi
