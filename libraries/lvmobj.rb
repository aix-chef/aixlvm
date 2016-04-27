#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  lvmobj.rb
#
# Copyright:: 2016

module AIXLVM
  class VolumeGroup
    attr_accessor :physical_volumes
    attr_accessor :physical_partition_size
    attr_accessor :max_physical_volumes
    def initialize(name,system)
      @name=name
      @tools=Tools.new(system)
      @physical_volumes=[]
      @physical_partition_size=2
      @max_physical_volumes=32

      @current_physical_volumes=[]
      @changed=false
    end

    def check_to_change()
      @changed=true
      if not [32, 64, 128, 256, 512, 768, 1024, 2048].include? @max_physical_volumes
        raise AIXLVM::LVMException.new('Illegal number of maximum physical volumes!')
      end
      val=Math.log(@physical_partition_size) / Math.log(2)
      if val!=val.to_i
        raise AIXLVM::LVMException.new('The physical partition size must be a power of 2 between 1 and 1024!')
      end
      for current_pv in @physical_volumes
        if not @tools.pv_exist?(current_pv)
          raise AIXLVM::LVMException.new('physical volume "%s" does not exist!' % current_pv)
        end
        current_vg=@tools.get_vg_from_pv(current_pv)
        if current_vg!=nil and current_vg!=@name
          raise AIXLVM::LVMException.new('physical volume "%s" is use in a different volume group!' % current_pv)
        end
        pv_size=@tools.get_size_from_pv(current_pv)
        if (pv_size/@physical_partition_size) > (@max_physical_volumes*1024)
          raise AIXLVM::LVMException.new('The physical partition size breaks the limit on the number of physical partitions per physical volume!')
        end
      end
      @current_physical_volumes=[]
      if @tools.vg_exist?(@name)
        if @tools.get_vg_ppsize(@name)!=@physical_partition_size
          raise AIXLVM::LVMException.new('The volume group already exists with a different physical partition size!')
        end
        @current_physical_volumes=@tools.get_pv_list_from_vg(@name)
        @changed=@physical_volumes.sort!=@current_physical_volumes.sort
      end
      return @changed
    end

    def create()
      ret = []
      if @changed
        if @current_physical_volumes.empty?
          @tools.create_vg(@name,@physical_partition_size,@physical_volumes[0])
          ret.push("Create volume groupe '%s'" % @name)
          ret.push("Extending '%s' to '%s'" % [@physical_volumes[0],@name])
          @current_physical_volumes.push(@physical_volumes[0])
        end
        for sub_pv in @physical_volumes.sort
          if !@current_physical_volumes.include?(sub_pv)
            ret.push("Extending '%s' to '%s'" % [sub_pv,@name])
            @tools.add_pv_into_vg(@name,sub_pv)
          end
        end
        for old_pv in @current_physical_volumes.sort
          if !@physical_volumes.include?(old_pv)
            ret.push("Reducing '%s' to '%s'" % [old_pv,@name])
            @tools.delete_pv_into_vg(@name,old_pv)
          end
        end
      end
      return ret
    end
  end

  class LogicalVolume
    attr_accessor :group
    attr_accessor :size
    attr_accessor :copies  # [1, 2, 3]
    attr_accessor :scheduling_policy  # ['parallel', 'sequential', 'parallel_write_sequential_read', 'parallel_write_round_robin_read']
    def initialize(name,system)
      @name=name
      @tools=Tools.new(system)
      @group=""
      @size=0
      @copies=1
      @scheduling_policy='parallel'

      @nb_pp=0
      @diff_pp=0
      @changed=false
    end

    def check_to_change()
      @changed=true
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
            raise AIXLVM::LVMException.new('size is too tall!')
          end
        else
          @changed=(@diff_pp!=0)
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