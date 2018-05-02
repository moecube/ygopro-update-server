koa = require 'koa'
router = require 'koa-router'
bodyParser = require 'koa-bodyparser'
lib = require './lib'
database = require './database'
moment = require 'moment'

server = new koa()
router = new router()
server.use bodyParser()

router.post '/ygopro-:b', (ctx, next) ->
  file_list = ctx.request.body
  file_list = [] if !Array.isArray file_list
  b = ctx.params.b
  console.log moment().format("YY-MM-DD hh:mm:ss") + " | Get update request from #{b} with #{file_list.length} files."
  ctx.throw 400, 'file list and b is required' if !file_list or !b
  release = await database.getData b
  ctx.throw 403, "can\' t find b named #{b}" unless release
  packages = lib.decision file_list, release.full_package, release.separate_packages, release.strategy_packages
  ctx.body = lib.generate packages

router.post '/clear', (ctx, next) ->
  database.clearData()
  ctx.body = 'ok'

router.post '/*', (ctx, next) ->
  ctx.body = "ygopro update server received your request from #{ctx.url}, but can't reply."


server.use(router.routes()).use(router.allowedMethods())
server.listen 10086