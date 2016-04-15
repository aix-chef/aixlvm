#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Recipes::  default.rb
#
# Copyright:: 2016

aixlvm_physical_volume 'hdisk1' do
    allocatable  true
    action :create
end

aixlvm_physical_volume 'hdisk2' do
    allocatable  true
    action :create
end

aixlvm_volume_group 'datavg' do
    physical_volumes ['hdisk1', 'hdisk2']
    pp_size   4
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
    action :create
end

aixlvm_filesystem 'dir1' do
    logical 'part1'
    size   '1024M'
    mount_point '/lvm/folder1'
    action :create
end

aixlvm_filesystem 'dir2' do
    logical 'part2'
    size   '1024'
    mount_point '/lvm/folder2'
    action :create
end

aixlvm_filesystem 'dir3' do
    logical 'part2'
    size   '2G'
    mount_point '/lvm/folder3'
    action :create
end
