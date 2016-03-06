#!/usr/bin/env bash
set -x
set -e

cd examples

ls *.rb | grep '^\d' | xargs -n 1 ruby
