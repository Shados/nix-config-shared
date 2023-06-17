#!/usr/bin/env fish

# Files will be created with permissions rw--- and directories with rwx--
umask 022

path_prepend $HOME/technotheca/artifacts/packages/bin $HOME/technotheca/packages/bin
