#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Provider::  logical_volume
#
# Copyright:: 2016

actions :create
default_action :create
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :group, :kind_of => String, :required => true
attribute :size, :kind_of => Fixnum, :required => true
attribute :copies, :kind_of => Fixnum, :default => 1, :equal_to => [1, 2, 3]
attribute :scheduling_policy, :kind_of => String, :default => 'parallel', :equal_to => ['parallel', 'sequential', 'parallel_write_sequential_read', 'parallel_write_round_robin_read']
