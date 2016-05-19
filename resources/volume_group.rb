#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  volume_group
#
# Copyright:: 2016

actions :create
default_action :create
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :physical_volumes, :kind_of => Array, :required => true
attribute :use_as_hot_spare, :kind_of => String, :default => 'n', :equal_to => ['y','n']
