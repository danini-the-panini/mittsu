#!/usr/bin/env bash
set -x
set -e

cd examples

ls *_example.rb | xargs -n 1 ruby
