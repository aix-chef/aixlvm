#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  lvmobj.rb
#
# Copyright:: 2016

module AIXLVM
  class VolumeGroup
    attr_accessor :physical_volumes
    attr_accessor :use_as_hot_spare
    attr_accessor :mirror_pool_name
    def initialize(name,system)
      @name=name
      @tools=Tools.new(system)
      @physical_volumes=[]
      @use_as_hot_spare='n'
      @mirror_pool_name=nil

      @current_physical_volumes=[]
      @changed=false
    end

    def check_to_change()
      @changed=true
      if (@mirror_pool_name != nil) && !(@mirror_pool_name =~ /^[0-9a-zA-Z]{1,15}$/)
        raise AIXLVM::LVMException.new('illegal_mirror_pool_name!')
      end
      for current_pv in @physical_volumes
        if not @tools.pv_exist?(current_pv)
          raise AIXLVM::LVMException.new('physical volume "%s" does not exist!' % current_pv)
        end
        current_vg=@tools.get_vg_from_pv(current_pv)
        if current_vg!=nil and current_vg!=@name
          raise AIXLVM::LVMException.new('physical volume "%s" is use in a different volume group!' % current_pv)
        end
      end
      @current_physical_volumes=[]
      if @tools.vg_exist?(@name)
        @current_physical_volumes=@tools.get_pv_list_from_vg(@name)
        current_hot_spare=@tools.vg_hot_spare?(@name)
        if (current_hot_spare==(@use_as_hot_spare=='y'))
          @use_as_hot_spare=nil
        end
        @tools.get_mirrorpool_from_vg('datavg')
        @changed=(@physical_volumes.sort!=@current_physical_volumes.sort) || (@use_as_hot_spare!=nil)
      end
      return @changed
    end

    def create()
      ret = []
      if @changed
        if @current_physical_volumes.empty?
          @tools.create_vg(@name,@physical_volumes[0],@mirror_pool_name)
          ret.push("Create volume groupe '%s'" % @name)
          if @use_as_hot_spare=='y'
            @tools.modify_vg('datavg','y')
          end
          ret.push("Extending '%s' to '%s'" % [@physical_volumes[0],@name])
          @current_physical_volumes.push(@physical_volumes[0])
        else
          if (@use_as_hot_spare!=nil)
            @tools.modify_vg('datavg',@use_as_hot_spare)
            ret.push("Modify '%s'" % [@name])
          end
        end
        for sub_pv in @physical_volumes.sort
          if !@current_physical_volumes.include?(sub_pv)
            ret.push("Extending '%s' to '%s'" % [sub_pv,@name])
            @tools.add_pv_into_vg(@name,sub_pv,@mirror_pool_name)
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

end