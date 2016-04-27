#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Recipes::  default.rb
#
# Copyright:: 2016
 
aixlvm_volume_group 'datavg' do
    physical_volumes          ['hdisk1', 'hdisk2']
    physical_partition_size   64
    max_physical_volumes      1024  
    action :create
end

aixlvm_volume_group 'foovg' do
    physical_volumes          ['hdisk10']
    physical_partition_size   64
    max_physical_volumes      1024  
    action :create
end

aixlvm_logical_volume 'part1' do
    group 'datavg'
    size   512
    scheduling_policy 'sequential'
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
    copies 3
    scheduling_policy 'parallel_write_round_robin_read'
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

aixlvm_volume_group 'datavg' do
    physical_volumes          ['hdisk1', 'hdisk2', 'hdisk3']
    physical_partition_size   64
    max_physical_volumes      1024  
    action :create
end

aixlvm_logical_volume 'part1' do
    group 'datavg'
    size   2048
    scheduling_policy 'sequential'
    action :create
end
