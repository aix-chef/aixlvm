#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  ts_all.rb
#
# Copyright:: 2016

require 'test/unit'
require_relative 'tc_tools'
require_relative 'tc_aix_tools' if (/aix/ =~ RUBY_PLATFORM) !=nil
require_relative 'tc_storage_objects.rb'
require_relative 'tc_aix_storage_objects.rb' if (/aix/ =~ RUBY_PLATFORM) !=nil
require_relative 'tc_objects_vg'
require_relative 'tc_objects_lv'