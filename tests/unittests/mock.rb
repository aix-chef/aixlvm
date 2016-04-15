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

  def add_retrun(value) 
    @out_retrun.push(value)
  end

  def get_cmd() 
    return @cmd_add
  end
  
  def run(cmd)
    @cmd_add.push(cmd)
    return @out_retrun.shift
  end
end
