#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  lvmobj.rb
#
# Copyright:: 2016

module AIXLVM

  class LogicalVolume
    attr_accessor :group
    attr_accessor :physical_volumes
    attr_accessor :size
    attr_accessor :copies  # [1, 2, 3]
    attr_accessor :stripe
    attr_accessor :scheduling_policy  # ['parallel', 'sequential', 'parallel_write_sequential_read', 'parallel_write_round_robin_read']
    def initialize(name,system)
      @name=name
      @tools=Tools.new(system)
      @group=""
      @physical_volumes=[]
      @size=0
      @copies=1
      @stripe='n'
      @scheduling_policy='parallel'

      @nb_pp=0
      @diff_pp=0
      @changed=false
    end

    def check_to_change()
      @changed=true
      if not [1,2,3].include?(@copies)
        raise AIXLVM::LVMException.new('Illegal number of copies!')
      end
      if not @tools.vg_exist?(@group)
        raise AIXLVM::LVMException.new('volume group "%s" does not exist!' % @group)
      end
      ppsize=@tools.get_vg_ppsize(@group)
      @nb_pp=@size.to_f/ppsize.to_f
      if (@nb_pp!=@nb_pp.to_i)
        raise AIXLVM::LVMException.new('size must be multiple to the PP size!')
      end
      current_volgroup = @tools.get_vg_list_from_lv(@name)
      if current_volgroup != nil
        if current_volgroup != @group
          raise AIXLVM::LVMException.new('logical volume "%s" exist with other volume group!' % @name)
        end
        current_size = @tools.get_nbpp_from_lv(@name)
        @diff_pp=@nb_pp-current_size
        if @diff_pp>0
          free_pp_in_vg=@tools.get_vg_freepp(@group)
          if free_pp_in_vg<@diff_pp
            raise AIXLVM::LVMException.new('Insufficient space available!')
          end
        else
          @changed=(@diff_pp!=0)
        end
      else
        free_pp_in_vg=@tools.get_vg_freepp(@group)
        if free_pp_in_vg<@nb_pp
          raise AIXLVM::LVMException.new('Insufficient space available!')
        end
      end
      return @changed
    end

    def create()
      ret = []
      if @changed
        if @diff_pp==0
          @tools.create_lv(@name,@group,@nb_pp)
          ret.push("Create logical volume '%s' on volume groupe '%s'" % [@name,@group])
        else
          if @diff_pp>0
            @tools.increase_lv(@name,@diff_pp)
          else
            #
          end
          ret.push("Modify logical volume '%s'" % @name)
        end
      end
      return ret
    end

  end

end