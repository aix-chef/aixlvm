#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  tools.rb
#
# Copyright:: 2016

module AIXLVM
  class StObjPV
    def initialize(system,name)
      @system=system
      @name=name
    end

    def exist?
      out=@system.run('lspv | grep "%s "' % @name)
      return out!=nil
    end

    def get_vgname
      out=@system.run("lspv %s | grep 'VOLUME GROUP:'" % @name)
      if out!=nil
        return out[/VOLUME GROUP:\s*(.*)/,1]
      else
        return nil
      end
    end

    def get_size
      out=@system.run("bootinfo -s %s" % @name)
      if out!=nil
        return out.to_i
      else
        return 0
      end
    end
  end

  class StObjVG
    def initialize(system,name)
      @system=system
      @name=name
      @descript=0
    end

    def read
      if @descript==0
        @descript=@system.run('lsvg %s' % @name)
      end
    end

    def exist?
      read
      return (@descript!=nil)
    end

    def get_pv_list
      pv_list=[]
      out=@system.run("lsvg -p %s" % @name)
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

    def hot_spare?
      read
      if @descript!=nil
        return @descript[/HOT SPARE:\s*([^\s]*)\s.*/,1] !='no'
      else
        return nil
      end
    end

    def get_ppsize
      read
      if @descript!=nil
        return @descript[/PP SIZE:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def get_freepp
      read
      if @descript!=nil
        return @descript[/FREE PPs:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def get_totalpp
      read
      if @descript!=nil
        return @descript[/TOTAL PPs:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def get_mirrorpool
      out=@system.run("lspv -P | grep '%s'" % @name)
      if out!=nil
        mirror_pool=nil
        reg_exp=/^.*#{@name}\s+([^\s]*)$/
        for line in out.split("\n")
          current_pool=line[reg_exp,1]
          if current_pool==nil
            current_pool=""
          end
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

    def create(pvname,mirrorpool)
      if mirrorpool==nil
        cmd="mkvg -y %s -S -f %s" % [@name,pvname]
      else
        cmd="mkvg -y %s -S -p %s -f %s" % [@name,mirrorpool,pvname]
      end
      out=@system.run(cmd)
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def modify(hot_spot)
      out=@system.run("chvg -h %s %s" % [hot_spot,@name])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def add_pv(pvname,mirrorpool)
      if mirrorpool==nil
        cmd="extendvg -f %s %s" % [@name,pvname]
      else
        cmd="extendvg -p %s -f %s %s" % [mirrorpool,@name,pvname]
      end
      out=@system.run(cmd)
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def delete_pv(pvname)
      out=@system.run("reducevg -d %s %s" % [@name,pvname])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end
  end

  class StObjLV
    def initialize(system,name)
      @system=system
      @name=name
      @descript=0
    end
    
    def read
      if @descript==0
        @descript=@system.run('lslv %s' % @name)
      end
    end

    def exist?
      read
      return @descript!=nil
    end

    def get_vg
      read
      if @descript!=nil
        return @descript[/VOLUME GROUP:\s*(.*)\s*/,1]
      else
        return nil
      end
    end

    def get_nbpp
      read
      if @descript!=nil
        return @descript[/PPs:\s*(.*)\s*/,1].to_i
      else
        return nil
      end
    end

    def create(vgname,nb_pp)
      out=@system.run("mklv -y %s %s %d" % [@name,vgname,nb_pp])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end

    def increase(diff_pp)
      out=@system.run("extendlv %s %d" % [@name,diff_pp])
      if out!=nil
        return out
      else
        raise AIXLVM::LVMException.new("system error:%s" % @system.last_error)
      end
    end
  end
end
