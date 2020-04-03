assert = require "assert"
fs = require "fs"
{launch} = require "../src/launch"

describe "launch section", ()->
  it "near real test", (on_end)->
    @timeout 2*60*1000 # 2 min
    # NOTE that this result is valid for AutoDock Vina 1.1.2 (May 11, 2011)
    # and yes, this is freshest version http://vina.scripps.edu/download.html
    opt = {
      task_id       : "deadbeef"
      receptor_path : "./test/test_files/receptor.pdbqt"
      ligand_path   : "./test/test_files/ligand.pdbqt"
      
      center_x      : 11
      center_y      : 90.5
      center_z      : 57.5
      
      size_x        : 22
      size_y        : 24
      size_z        : 28
      
      # explicit
      exhaustiveness: 1 # for test only, less cpu usage, worse results
      # clean_up      : false # for debug
      clean_up      : true
    }
    await launch opt, defer(err, res); return on_end err if err
    
    assert.strictEqual res.res_stderr.toString(), ""
    assert.strictEqual res.res_stdout.toString(), fs.readFileSync "./test/test_files/stdout", "utf-8"
    assert.strictEqual res.res_log.toString(),    fs.readFileSync "./test/test_files/log.txt", "utf-8"
    assert.strictEqual res.result.toString(),     fs.readFileSync "./test/test_files/all.pdbqt", "utf-8"
    
    assert !fs.existsSync "./job/deadbeef"
    
    on_end()