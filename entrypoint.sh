#!/bin/bash
set -e
if [[ -d "${HOME}/.gitconfig" ]]; then
  echo something made ~/.gitconfig a directory, removing it.
  ls -alt ${HOME}
  rm -rf "${HOME}/.gitconfig"
fi

if [[ -n ${LOCAL_USER_ID} ]]; then
  usermod -u ${LOCAL_USER_ID} jenkins_oci
  exec gosu jenkins_oci "$@"
fi

exec "${@}"
