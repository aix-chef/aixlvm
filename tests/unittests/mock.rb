#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  mock.rb
#
# Copyright:: 2016

require_relative "../../libraries/tools"

class MockSystem < AIXLVM::BaseSystem
  def initialize()
    @out_retrun=[]
    @cmd_add=[]
  end

  def add_retrun(cmd,value)
    @out_retrun.push([cmd,value])
  end

  def get_cmd()
    return @cmd_add
  end

  def residual()
    res=""
    for val in @out_retrun
      res+="%s => %s\n" % val
    end
    return res
  end

  def run(cmd)
    @cmd_add.push(cmd)
    expected_cmd, retvalue = @out_retrun.shift
    if expected_cmd!=cmd
      raise AIXLVM::LVMException.new("System command error:'%s' expected, '%s' return!" % [expected_cmd,cmd])
    end
    if retvalue==nil
      @last_error=cmd
    end
    return retvalue
  end
end
