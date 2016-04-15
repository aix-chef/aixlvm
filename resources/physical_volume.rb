#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  physical_volume
#
# Copyright:: 2016

actions :create
default_action :create
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :allocatable, :kind_of => [TrueClass, FalseClass], :default => true
