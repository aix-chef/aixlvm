#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"
require_relative "../../libraries/lvmobj"
require_relative "mock"

class TestVolumGroup < Test::Unit::TestCase
  def setup
    @mock = MockSystem.new()
    @volgroup = AIXLVM::VolumeGroup.new('datavg',@mock)
    @volgroup.physical_volumes=['hdisk1', 'hdisk2']
    @volgroup.physical_partition_size=100
    @volgroup.max_physical_volumes=64
  end

  def test_01_pv_dont_exists
    # One or more of the specified physical volume names do not exist
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', nil)

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change
    }
    assert_equal('physical volume "hdisk2" does not exist!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_02_pv_are_already_use
    # One or more of the specified physical volumes are use in a different volume group
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     foovg')

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('physical volume "hdisk2" is use in a different volume group!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_03_pv_are_manage_by_thirdvm
    # One or more of the specified physical volumes are managed by third-party volume manager
    print("??? third-party volume manager ???\n")
    return
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk2", "2048")

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('physical volume "hdisk1" is managed by third-party volume manager!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_04_bad_block_sizes
    # The block sizes of all the specified physical volumes are not identical
    print("??? block sizes of a PV ???\n")
    return
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk2", "2048")

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('The block sizes of all the specified physical volumes are not identical!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_illegal_nb_max_pv
    # Illegal number of maximum physical volumes
    @volgroup.max_physical_volumes=10
    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('Illegal number of maximum physical volumes!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_06_ppsize_break_limit_nb_pp_per_pv
    # The physical partition size breaks the limit on the number of physical partitions per physical volume
    @volgroup.physical_partition_size=10
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "512")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk2", "2048")

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('The physical partition size breaks the limit on the number of physical partitions per physical volume!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_07_vg_exist_with_diff_ppsize
    # The volume group already exists with a different physical partition size
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk2", "2048")
    @mock.add_retrun('lsvg | grep datavg','datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", 'PP SIZE:        40 megabyte(s)')

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('The volume group already exists with a different physical partition size!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_08_vg_not_exist
    # VG not exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk2", "2048")
    @mock.add_retrun('lsvg | grep datavg', nil)
    assert_equal(true, @volgroup.check_to_change())
    assert_equal('',@mock.residual())
  end

  def test_09_vg_exist_no_change
    # VG not exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk2", "2048")
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", 'PP SIZE:        100 megabyte(s)')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    assert_equal(false, @volgroup.check_to_change())
    assert_equal('',@mock.residual())
  end

  def test_10_vg_exist_with_change_add_disk
    # VG not exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("bootinfo -s hdisk2", "2048")
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", 'PP SIZE:        100 megabyte(s)')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal('',@mock.residual())
  end

end