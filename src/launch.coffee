module = @
require "fy"
{exec} = require "child_process"
config = require "./config"
fs = require "fs"

# TODO config?
@default_param =
  exhaustiveness  : 10
  num_modes       : 10

check_file = (t)->
  fs.existsSync t

check_hex = (t)->
  /^[0-9a-f]+$/.test t

@check_number = check_number = (t)->
  /^-?(\d+)(.\d+)?$/.test t

###
TODO support for https://github.com/QVina/qvina
###
@launch = (opt, cb)->
  {
    task_id
    
    receptor_path
    ligand_path
    
    center_x
    center_y
    center_z
    
    size_x
    size_y
    size_z
    
    exhaustiveness
    num_modes
    seed
    clean_up
  } = opt
  # ###################################################################################################
  #    check
  # ###################################################################################################
  return cb new Error "bad task_id #{task_id}"                if !check_hex task_id
  return cb new Error "bad receptor_path #{receptor_path}"    if !check_file receptor_path
  return cb new Error "bad ligand_path #{ligand_path}"        if !check_file ligand_path
  
  return cb new Error "bad center_x #{center_x}"              if !check_number center_x
  return cb new Error "bad center_y #{center_y}"              if !check_number center_y
  return cb new Error "bad center_z #{center_z}"              if !check_number center_z
  
  return cb new Error "bad size_x #{size_x}"                  if !check_number size_x
  return cb new Error "bad size_y #{size_y}"                  if !check_number size_y
  return cb new Error "bad size_z #{size_z}"                  if !check_number size_z
  
  exhaustiveness ?= module.default_param.exhaustiveness
  return cb new Error "bad exhaustiveness #{exhaustiveness}"  if !check_number exhaustiveness
  
  num_modes ?= module.default_param.num_modes
  return cb new Error "bad num_modes #{num_modes}"            if !check_number num_modes
  
  seed ?= 1
  return cb new Error "bad seed #{seed}"                      if !check_number seed
  
  clean_up ?= true
  # ###################################################################################################
  #    conf
  # ###################################################################################################
  job_dir     = "#{config.path_to_job}/#{task_id}"
  result_path = "#{job_dir}/all.pdbqt"
  conf_path   = "#{job_dir}/conf.txt"
  log_path    = "#{job_dir}/log.txt"
  stderr_path = "#{job_dir}/stderr"
  stdout_path = "#{job_dir}/stdout"
  
  receptor_proxy_path = "#{job_dir}/receptor.pdbqt"
  ligand_proxy_path   = "#{job_dir}/ligand.pdbqt"
  
  conf = """
    receptor = #{receptor_proxy_path}
    ligand = #{ligand_proxy_path}
    out = #{result_path}
    
    center_x = #{center_x}
    center_y = #{center_y}
    center_z = #{center_z}
    
    size_x = #{size_x}
    size_y = #{size_y}
    size_z = #{size_z}
    
    exhaustiveness = #{exhaustiveness}
    num_modes = #{num_modes}
    
    """
  
  await fs.mkdir job_dir,             defer(err);                   return cb err if err
  await fs.writeFile conf_path, conf, defer(err);                   return cb err if err
  
  await fs.copyFile receptor_path, receptor_proxy_path, defer(err); return cb err if err
  await fs.copyFile ligand_path, ligand_proxy_path,     defer(err); return cb err if err
  
  cmd = "/bin/bash -c \"time #{config.path_to_autodock_vina} --seed #{seed} --config #{conf_path} --log #{log_path} 2>#{stderr_path} 1>#{stdout_path}\""
  puts cmd
  await exec cmd, defer(err, stdout, stderr);                       return cb err if err
  
  # ###################################################################################################
  #    read results
  # ###################################################################################################
  await fs.readFile log_path,     defer(err, res_log   );           return cb err if err
  await fs.readFile stderr_path,  defer(err, res_stderr);           return cb err if err
  await fs.readFile stdout_path,  defer(err, res_stdout);           return cb err if err
  await fs.readFile result_path,  defer(err, result);               return cb err if err
  
  res = {
    res_log
    res_stderr
    res_stdout
    result
  }
  # ###################################################################################################
  #    clean up
  # ###################################################################################################
  if clean_up
    await exec "rm -rf #{job_dir}", defer(err);                     return cb err if err
  
  
  cb null, res