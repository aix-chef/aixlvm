#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  ts_all.rb
#
# Copyright:: 2016

require 'test/unit'
require_relative 'tc_tools'
require_relative 'tc_aix_tools' if (/aix/ =~ RUBY_PLATFORM) !=nil