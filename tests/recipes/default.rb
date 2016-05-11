#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Recipes::  default.rb
#
# Copyright:: 2016
 
aixlvm_volume_group 'datavg' do
    physical_volumes          ['hdisk1', 'hdisk2']
    action :create
end

aixlvm_volume_group 'foovg' do
    physical_volumes          ['hdisk10']
    action :create
end

aixlvm_logical_volume 'part1' do
    group 'datavg'
    size   512
    action :create
end

aixlvm_logical_volume 'part2' do
    group 'datavg'
    size   1024
    copies 2
    action :create
end

aixlvm_logical_volume 'part3' do
    group 'foovg'
    size   2048
    action :create
end

aixlvm_filesystem '/lvm/folder1' do
    logical 'part1'
    size   '256M'
    action :create
end

aixlvm_filesystem '/lvm/folder2' do
    logical 'part2'
    size   '1024'
    action :create
end

aixlvm_filesystem '/lvm/folder3' do
    logical 'part2'
    size   '128M'
    action :create
end

aixlvm_volume_group 'datavg' do
    physical_volumes          ['hdisk1', 'hdisk2', 'hdisk3']
    action :create
end

aixlvm_logical_volume 'part1' do
    group 'datavg'
    size   2048
    action :create
end

aixlvm_filesystem '/lvm/folder2' do
    logical 'part2'
    size   '512'
    action :create
end
