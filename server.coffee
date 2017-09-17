express = require 'express'
bodyParser = require 'body-parser'
lib = require './lib'
database = require './database'

server = express()

json_parser = bodyParser.json()

server.post '/ygopro-:b', json_parser, (req, res) ->
  # version is thrown. Only return the latest.
  file_list = req.body
  b = req.params.b
  console.log "Get update request from #{b} with #{file_list.length} files."
  if !file_list or !b
    res.statusCode = 400
    res.end 'file list and b is required'
    return
  database.getData(b).then (release) ->
    # wanted_files = lib.compare file_list, release.file_list
    wanted_files = file_list
    wanted_files = [] if !Array.isArray file_list
    packages = lib.decision wanted_files, release.full_package, release.separate_packages, release.strategy_packages
    meta = lib.generate packages
    res.end meta
  , (err) ->
    console.log err
    res.statusCode = 403
    res.end ""

server.post '/clear', (req, res) ->
  database.clearData()

server.post '/*', (req, res) ->
  res.end "ygopro update server received your request from #{req.url}, but can't reply."

server.listen 10086