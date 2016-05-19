#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  volume_group
#
# Copyright:: 2016

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @volgroup = AIXLVM::VolumeGroup.new(@new_resource.name,AIXLVM::System.new())
  @volgroup.physical_volumes=@new_resource.physical_volumes
  @volgroup.use_as_hot_spare=@new_resource.use_as_hot_spare
end

action :create do
  begin
    if @volgroup.check_to_change()
      converge_by(@volgroup.create().join(" | ")) do

      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end

