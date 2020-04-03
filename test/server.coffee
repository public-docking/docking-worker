assert = require "assert"
fs = require "fs"
mock_server = require "../src/mock_server"
mock_go = require "../src/go"

describe "server section", ()->
  it "near real test", (on_end)->
    @timeout 2*60*1000 # 2 min
    
    mock_server.start()
    await setTimeout defer(), 100 # wait for start
    await
      mock_server.result_callback = defer(res)
      mock_go.start()
    
    mock_go.stop()
    mock_server.stop()
    
    assert.strictEqual res.res_stderr.toString(), ""
    assert.strictEqual res.res_stdout.toString(), fs.readFileSync "./test/test_files/stdout", "utf-8"
    assert.strictEqual res.res_log.toString(),    fs.readFileSync "./test/test_files/log.txt", "utf-8"
    assert.strictEqual res.result.toString(),     fs.readFileSync "./test/test_files/all.pdbqt", "utf-8"
    
    assert !fs.existsSync "./job/deadbeefaaa"
    
    on_end()
