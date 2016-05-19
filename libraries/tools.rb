#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  tools.rb
#
# Copyright:: 2016

require 'open3'

module AIXLVM
  class LVMException < Exception
  end

  class BaseSystem
    attr_reader :last_error
    def initialize()
      @last_error=''
    end

    def run(cmd)
      raise "Abstract!"
    end
  end

  class System < BaseSystem
    def run(cmd)
      begin
        stdout, @last_error, status = Open3.capture3({'LANG' => 'C'},*cmd)
        if status.success?
          return stdout.slice!(0..-(1 + $/.size))
        else
          return nil
        end
      rescue
        return nil
      end
    end
  end

end
