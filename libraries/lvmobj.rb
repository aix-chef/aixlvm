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
    end

    def check_to_change()
      changed=true
      if not [32, 64, 128, 256, 512, 768, 1024, 2048].include? @max_physical_volumes
        raise AIXLVM::LVMException.new('Illegal number of maximum physical volumes!')
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
        if (pv_size/@physical_partition_size) > @max_physical_volumes
          raise AIXLVM::LVMException.new('The physical partition size breaks the limit on the number of physical partitions per physical volume!')
        end
      end
      if @tools.vg_exist?(@name)
        if @tools.get_vg_ppsize(@name)!=@physical_partition_size
          raise AIXLVM::LVMException.new('The volume group already exists with a different physical partition size!')
        end
        changed=@physical_volumes.sort!=@tools.get_pv_list_from_vg(@name).sort
      end
      return changed
    end
  end
end