price = require './price.json'
fs = require 'fs'
path = require 'path'
mustache = require 'mustache'

calculatePrice = (archives) ->
  total_amount = 0
  for archive in archives
    total_amount += archive.size / 1000 * price.sizePrice if archive
  total_amount += archives.length * price.requestPrice

decision = (wanted_files, full_package, separate_packages, strategy_packages) ->
  # console.log separate_packages
  # Calculate Full Package Solution Price.
  full_solution =
    archives: [full_package]
    price: calculatePrice [full_package]

  # Calculate Separate Package Solution Price
  separate_package_hash = new Map
  for separate_package in separate_packages
    separate_package_hash.set separate_package.file[0], separate_package
  wanted_separate_packages = wanted_files.map (file) -> separate_package_hash.get file
  separate_solution =
    archives: wanted_separate_packages
    price: calculatePrice wanted_separate_packages

  # Calculate Strategy Package Solutions Price
  solutions = [full_solution, separate_solution]
  for strategy_package in strategy_packages
    packages = [strategy_package]
    for file in wanted_files
      packages.push separate_package_hash.get file if !(strategy_package.file.includes file)
    solutions.push
      archives: packages # some packages
      price: calculatePrice packages # some packages

  console.log solutions

  # Decision!
  final_solution = full_solution
  for solution in solutions
    final_solution = solution if final_solution.price > solution.price
  console.log "decide to ￥#{final_solution.price.toFixed(7)}"
  return final_solution.archives

compare_files = (now_file_hash, target_file_list) ->
  target_file_list.filter (target_file) -> now_file_hash.get(target_file.name) != target_file.checksum

compare_file_lists = (now_file_list, target_file_list) ->
  now_file_hash = new Map
  now_file_hash.set now_file.name, now_file.checksum for now_file in now_file_list
  compare_files now_file_hash, target_file_list

template = fs.readFileSync(path.join(__dirname, 'template.meta4')).toString()
generate_meta = (packages) ->
  packages = packages.filter (pack) -> pack
  mustache.render template, { "packages": packages }


module.exports.decision = decision
module.exports.compare = compare_file_lists
module.exports.generate = generate_meta
