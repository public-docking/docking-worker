#!/usr/bin/env iced
require "fy"
config = require "./src/config"
argv = require("minimist")(process.argv.slice(2))

if argv.ws_master
  config.ws_master = argv.ws_master

require "./src/go"
