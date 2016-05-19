#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  logical_volume
#
# Copyright:: 2016

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @logicalvol = AIXLVM::LogicalVolume.new(@new_resource.name,AIXLVM::System.new())
  @logicalvol.group=@new_resource.group
  @logicalvol.size=@new_resource.size
  @logicalvol.copies=@new_resource.copies
end

action :create do
  begin
    if @logicalvol.check_to_change()
      converge_by(@logicalvol.create().join(" | ")) do

      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end
