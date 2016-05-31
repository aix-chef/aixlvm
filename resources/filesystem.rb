#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  filesystem
#
# Copyright:: 2016

actions :create, :mount, :umount, :defragfs
default_action :create
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :logical, :kind_of => String, :required => true
attribute :size, :kind_of => String, :required => true
