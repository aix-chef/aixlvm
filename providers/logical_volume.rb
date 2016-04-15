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
  return
end

action :create do
  Chef::Log.fatal('logical volume :create => no implemented!')
end
