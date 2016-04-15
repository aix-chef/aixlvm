#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  tools.rb
#
# Copyright:: 2016

require 'open3'

module AIXLVM
  class BaseSystem
    def run(cmd)
      raise "Abstract!"
    end
  end

  class System < BaseSystem
    def run(cmd)
      begin
        stdout, stderr, status = Open3.capture3(*cmd)
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

  class Tools
    def initialize(system)
      @system=system
    end

    def is_pv_exist(pvname)
      out=@system.run('lspv | grep "'+pvname+' "')
      return out!=nil
    end

    def is_vg_exist(vgname)
      out=@system.run('lsvg | grep '+vgname)
      return ((out!=nil) and (vgname==out.strip))
    end

    def is_lv_exist(lvname)
      out=@system.run('lslv '+lvname)
      return out!=nil
    end
  end
end
