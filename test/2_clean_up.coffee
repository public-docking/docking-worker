{execSync} = require "child_process"

execSync "rm -rf ./job/*"
execSync "touch  ./job/.keep"

execSync "rm -rf ./download/*"
execSync "touch  ./download/.keep"
