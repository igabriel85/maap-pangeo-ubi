#!/bin/bash

# add .condarc with alternate env path

# check if .condarc exists in $HOME
#if [ -f $HOME/.condarc ]; then
#  echo "File .condarc exists in $HOME"
#  echo "Contents of .condarc:"
#  cat $HOME/.condarc
#else
#  echo "File .condarc does not exist in $HOME creating it"
#  echo "envs_dirs:" > $HOME/.condarc
#fi

#check if $PROJECT_SOURCE/envs exists
if [ -d $PROJECT_SOURCE/envs ]; then
  echo "Directory $PROJECT_SOURCE/envs exists"
else
  echo "Directory $PROJECT_SOURCE/envs does not exist creating it"
  mkdir -p $PROJECT_SOURCE/envs
fi

# check if envvar set if not set it
if [ -z "$CONDA_ENVS_PATH" ]; then
  echo "CONDA_ENVS_PATH not set"
  export CONDA_ENVS_PATH=$PROJECT_SOURCE/envs
  echo "Setting CONDA_ENVS_PATH to $CONDA_ENVS_PATH"
else
  echo "CONDA_ENVS_PATH is set to $CONDA_ENVS_PATH"
fi

whoami
which python
echo $HOME
echo $PATH
echo $@
exec "$@"
