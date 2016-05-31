#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Library::  lvmobj.rb
#
# Copyright:: 2016

require_relative "storage_objects"

module AIXLVM
  class FileSystem
    attr_accessor :group
    attr_accessor :logical_volume
    attr_accessor :size
    def initialize(name,system)
      @name=name
      @system=system
      @logical_volume=""
      @size=''

      @complet_size=0
      @current_size=0
    end

    def check_to_change()
      @changed=true
      res=/^[0-9]+(\.[0-9]+|)(|M|G)$/.match(@size)
      if res
        case res[2]
        when 'G'
          @complet_size=@size.to_f*1024
        when 'M'
          @complet_size=@size.to_f
        else
          @complet_size=@size.to_f/2.0
        end
      else
        raise AIXLVM::LVMException.new('Invalid size!')
      end
      lv_obj=StObjLV.new(@system,@logical_volume)
      if not lv_obj.exist?
        raise AIXLVM::LVMException.new('logical volume "%s" does not exist!' % @logical_volume)
      end
      current_mount=lv_obj.get_mount
      if (current_mount!=nil) and (current_mount!='') and (current_mount!=@name)
        raise AIXLVM::LVMException.new('logical volume "%s" has already another file system!' % @logical_volume)
      end
      fs_obj=StObjFS.new(@system,@name)
      if fs_obj.exist?
        @current_size=fs_obj.get_size
        @changed=(@complet_size!=@current_size)
      end
      if @complet_size>(lv_obj.get_nbpp*lv_obj.get_ppsize)
        raise AIXLVM::LVMException.new('Insufficient space available!')
      end
      return @changed
    end

    def create()
      ret = []
      if @changed
        fs_obj=StObjFS.new(@system,@name)
        if @current_size!=0
          fs_obj.modify(@complet_size)
          ret.push("Modify file system '%s'" % @name)
        else
          fs_obj.create(@logical_volume)
          fs_obj.modify(@complet_size)
          ret.push("Create file system '%s' on logical volume '%s'" % [@name,@logical_volume])
        end
      end
      return ret
    end

    def check_to_mount(is_mount)
      fs_obj=StObjFS.new(@system,@name)
      if ! fs_obj.exist?
        raise AIXLVM::LVMException.new("Filesystem doesn't exist!")
      end
      if is_mount
        return !fs_obj.mounted?
      else
        return fs_obj.mounted?
      end
    end

    def mount
      ret = []
      fs_obj=StObjFS.new(@system,@name)
      fs_obj.mount
      ret.push("File system '%s' mounted" % [@name])
      return ret
    end

    def umount
      ret = []
      fs_obj=StObjFS.new(@system,@name)
      fs_obj.umount
      ret.push("File system '%s' umounted" % [@name])
      return ret
    end

    def check_to_defrag()
      fs_obj=StObjFS.new(@system,@name)
      if ! fs_obj.exist?
        raise AIXLVM::LVMException.new("Filesystem doesn't exist!")
      end
      if fs_obj.get_format!='jfs2'
        raise AIXLVM::LVMException.new("Filesystem doesn't jfs2!")
      end
      if fs_obj.readonly?
        raise AIXLVM::LVMException.new("Filesystem is readonly!")
      end
      if !fs_obj.mounted?
        raise AIXLVM::LVMException.new("Filesystem doesn't mount!")
      end
      return true
    end

    def defragfs
      ret = []
      fs_obj=StObjFS.new(@system,@name)
      fs_obj.defragfs
      ret.push("File system '%s' defraged" % [@name])
      return ret
    end

  end

end