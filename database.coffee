{ Pool } = require 'pg'
config = require './config.json'

LOAD_RELEASE = 'select * from releases values where b = $1::text order by created_at desc limit 1'
LOAD_ARCHIVES = 'select * from archives inner join archive_files on archive_files.archive = archives.checksum where archives.release = $1::text'
LOAD_FILES = 'select * from files where release = $1::text'

pool = new Pool config.database

data_cache = {}

getData = (b_name) ->
  release = null
  if data_cache.b_name
    return new Promise (resolve, reject) -> resolve data_cache.b_name
  Promise.resolve loadRelease(b_name).then (releases) ->
    release = releases[0]
    Promise.all([
      loadFiles(release.name).then (files) ->
        release.file_list = files
        release
      loadArchives(release.name).then (archives) ->
        release.full_package = archives.full_package
        release.separate_packages = archives.separate_packages
        release.strategy_packages = archives.strategy_packages
        release
    ]).then ->
      data_cache.b_name = release
      return release

loadRelease = (b_name) ->
  console.log "Loading #{b_name} message from database."
  new Promise (resolve, reject) ->
    pool.query LOAD_RELEASE, [b_name], (err, result) -> returning_promise_handle err, result, resolve, reject

loadArchives = (release_name) ->
  new Promise (resolve, reject) ->
    pool.query LOAD_ARCHIVES, [release_name], (err, result) ->
      if err
        console.log err
        reject err
      else
        archives = new Map
        for row in result.rows
          if archives.has row.archive
            archives.get(row.archive).file.push row.file
          else
            archives.set row.archive,
              release: release_name
              size: row.size
              type: row.type
              checksum: row.checksum
              file: [row.file]
        archive_category = { full_package: [], separate_packages: [], strategy_packages: [] }
        archive_category.full = archive_category.full_package
        archive_category.sand = archive_category.separate_packages
        archive_category.strategy = archive_category.strategy_packages
        archives.forEach (archive) -> archive_category[archive.type].push archive
        archive_category.full_package = archive_category.full_package[0]
        resolve archive_category

loadFiles = (release_name)  ->
  new Promise (resolve, reject) ->
    pool.query LOAD_FILES, [release_name], (err, result) -> returning_promise_handle err, result, resolve, reject

returning_promise_handle = (err, result, resolve, reject) ->
  if err
    console.log err
    reject err
  else
    resolve result.rows

module.exports.getData = getData
module.exports.clearData = () -> data_cache = {}