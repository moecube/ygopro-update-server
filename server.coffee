express = require 'express'
bodyParser = require 'body-parser'
lib = require './lib'
database = require './database'

server = express()

json_parser = bodyParser.json()
server.post '/update', json_parser, (req, res) ->
  file_list = req.body.fileList
  b = req.body.b
  if !file_list or !b
    res.statusCode = 400
    res.end 'fileList and b is required'
    return
  database.getData(b).then (release) ->
    wanted_files = lib.compare file_list, release.file_list
    packages = lib.decision wanted_files, release.full_package, release.separate_packages, release.strategy_packages
    meta = lib.generate packages
    console.log meta
    res.end meta


server.listen 10086