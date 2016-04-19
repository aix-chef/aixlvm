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

    # PV tools
    def pv_exist?(pvname)
      out=@system.run('lspv | grep "%s "' % pvname)
      return out!=nil
    end

    def get_vg_from_pv(pvname)
      out=@system.run("lspv %s | grep 'VOLUME GROUP:'" % pvname)
      if out!=nil
        return out[/VOLUME GROUP:\s*(.*)/,1]
      else
        return nil
      end
    end

    def get_size_from_pv(pvname)
      out=@system.run("bootinfo -s %s" % pvname)
      if out!=nil
        return out.to_i
      else
        return 0
      end
    end
    
    # VG tools
    def get_pv_list_from_vg(vgname)
      pv_list=[]
      out=@system.run("lsvg -p %s" % vgname)
      if out!=nil
        header=true
        out.split("\n").each do |line|
           if header
             header=(line[/PV_NAME/]!='PV_NAME')
           else
              pv_list.push(line[/([^\s]+)/,1])
           end 
        end
      end
      return pv_list
    end

    def vg_exist?(vgname)
      out=@system.run('lsvg | grep %s' % vgname)
      return ((out!=nil) and (vgname==out.strip))
    end

    def get_vg_ppsize(vgname)
      out=@system.run("lsvg %s | grep 'PP SIZE:'" % vgname)
      if out!=nil
        return out[/PP SIZE:\s*(.*)\s/,1].to_i 
      else
        return nil
      end
    end

    # LV tools
    def lv_exist?(lvname)
      out=@system.run('lslv '+lvname)
      return out!=nil
    end
  end
end
