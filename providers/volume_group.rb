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
  @volgroup.physical_partition_size=@new_resource.physical_partition_size
  @volgroup.max_physical_volumes=@new_resource.max_physical_volumes
end

action :create do
  if @volgroup.check_to_change()
    converge_by(@volgroup.create().join(" | ")) do
      
    end
  end
end

