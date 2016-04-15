#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  physical_volume
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
  Chef::Log.fatal('physical volume :create => no implemented!')
end
