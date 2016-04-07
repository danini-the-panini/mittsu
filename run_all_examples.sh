#!/usr/bin/env bash
set -x
set -e

cd examples

ls *.rb | grep '^[0-9]' | xargs -n 1 ruby
