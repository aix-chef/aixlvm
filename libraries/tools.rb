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
        stdout, @last_error, status = Open3.capture3(*cmd)
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

    def vg_hot_spare?(vgname)
      out=@system.run("lsvg %s | grep 'HOT SPARE:'" % vgname)
      if out!=nil
        return out[/HOT SPARE:\s*([^\s]*)\s.*/,1] !='no'
      else
        return nil
      end
    end

    def get_vg_ppsize(vgname)
      out=@system.run("lsvg %s | grep 'PP SIZE:'" % vgname)
      if out!=nil
        return out[/PP SIZE:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def get_vg_freepp(vgname)
      out=@system.run("lsvg %s | grep 'FREE PPs:'" % vgname)
      if out!=nil
        return out[/FREE PPs:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def get_vg_totalpp(vgname)
      out=@system.run("lsvg %s | grep 'TOTAL PPs:'" % vgname)
      if out!=nil
        return out[/TOTAL PPs:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def get_mirrorpool_from_vg(vgname)
      out=@system.run("lspv -P | grep '%s'" % vgname)
      if out!=nil
        mirror_pool=nil
        for line in out.split("\n")
          current_pool=line[/.*#{vgname}\s+(.*)/,1]
          if mirror_pool==nil
            mirror_pool=current_pool
          else
            if mirror_pool!=current_pool
              mirror_pool="???"
            end
          end
        end
        return mirror_pool
      else
        return nil
      end
    end

    def create_vg(vgname,pvname,mirrorpool)
      if mirrorpool==nil
        cmd="mkvg -y %s -S -f %s" % [vgname,pvname]
      else
        cmd="mkvg -y %s -S -p %s -f %s" % [vgname,mirrorpool,pvname]
      end
      out=@system.run(cmd)
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def modify_vg(vgname,hot_spot)
      out=@system.run("chvg -h %s %s" % [hot_spot,vgname])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def add_pv_into_vg(vgname,pvname,mirrorpool)
      if mirrorpool==nil
        cmd="extendvg -f %s %s" % [vgname,pvname]
      else
        cmd="extendvg -p %s -f %s %s" % [mirrorpool,vgname,pvname]
      end
      out=@system.run(cmd)
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def delete_pv_into_vg(vgname,pvname)
      out=@system.run("reducevg -d %s %s" % [vgname,pvname])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    # LV tools
    def get_vg_list_from_lv(lvname)
      out=@system.run('lslv '+lvname)
      if out!=nil
        return out[/VOLUME GROUP:\s*(.*)\s*/,1]
      else
        return nil
      end
    end

    def lv_exist?(lvname)
      return get_vg_list_from_lv(lvname)!=nil
    end

    def get_nbpp_from_lv(lvname)
      out=@system.run("lslv %s | grep 'PPs:'" % lvname)
      if out!=nil
        return out[/PPs:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def create_lv(lvname,vgname,nb_pp)
      out=@system.run("mklv -y %s %s %d" % [lvname,vgname,nb_pp])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def increase_lv(lvname,diff_pp)
      out=@system.run("extendlv %s %d" % [lvname,diff_pp])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

  end
end
