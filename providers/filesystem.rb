#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  filesystem
#
# Copyright:: 2016

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @filesystem = AIXLVM::FileSystem.new(@new_resource.name,AIXLVM::System.new())
  @filesystem.logical_volume=@new_resource.logical
  @filesystem.size=@new_resource.size
end

action :create do
  begin
    if @filesystem.check_to_change()
      converge_by(@filesystem.create().join(" | ")) do

      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end

action :mount do
  begin
    if @filesystem.check_to_mount(true)
      converge_by(@filesystem.mount().join(" | ")) do

      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end

action :umount do
  begin
    if @filesystem.check_to_mount(false)
      converge_by(@filesystem.umount().join(" | ")) do

      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end
