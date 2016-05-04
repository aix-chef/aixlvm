#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"
require_relative "../../libraries/lvmobj_lv"
require_relative "mock"

class TestLogicalVolume < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @logicalvol = AIXLVM::LogicalVolume.new('part1',@mock)
    @logicalvol.group='datavg'
    @logicalvol.physical_volumes=[]
    @logicalvol.size=1024
    @logicalvol.copies=1
    @logicalvol.stripe='n'
    @logicalvol.scheduling_policy='parallel'
  end

  def test_01_vg_dont_exists()
    @mock.add_retrun('lsvg | grep datavg', nil)
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('volume group "datavg" does not exist!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_02_size_invalid()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        124 megabyte(s)
")
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('size must be multiple to the PP size!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_03_lg_exist_on_other_vg()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        64 megabyte(s)")
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     part1                    VOLUME GROUP:   rootvg')
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('logical volume "part1" exist with other volume group!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_04_illegal_number_of_copies()
    @logicalvol.copies=4
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Illegal number of copies!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_insufficient_space_available_not_exits()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        4 megabyte(s)")
    @mock.add_retrun('lslv part1', nil)
    @mock.add_retrun("lsvg datavg | grep 'FREE PPs:'", 'MAX LVs:            256                      FREE PPs:       116 (464 megabytes) ')
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_06_insufficient_space_available_exits()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        4 megabyte(s)")
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     part1                    VOLUME GROUP:   datavg')
    @mock.add_retrun("lslv part1 | grep 'PPs:'", 'LPs:                10                     PPs:            128 ')
    @mock.add_retrun("lsvg datavg | grep 'FREE PPs:'", 'MAX LVs:            256                      FREE PPs:       116 (464 megabytes) ')
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_07_lv_not_exist()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        4 megabyte(s)")
    @mock.add_retrun('lslv part1', nil)
    @mock.add_retrun("lsvg datavg | grep 'FREE PPs:'", 'MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes) ')
    @mock.add_retrun("mklv -y part1 datavg 256", '')
    assert_equal(true, @logicalvol.check_to_change)
    assert_equal(["Create logical volume 'part1' on volume groupe 'datavg'"], @logicalvol.create())
    assert_equal('',@mock.residual())
  end

  def test_08_lv_exist_no_change()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        4 megabyte(s)")
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     part1                    VOLUME GROUP:   datavg')
    @mock.add_retrun("lslv part1 | grep 'PPs:'", 'LPs:                10                     PPs:            256 ')
    assert_equal(false, @logicalvol.check_to_change)
    assert_equal([], @logicalvol.create())
    assert_equal('',@mock.residual())
  end

  def test_09_lv_exist_with_size_increase()
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        4 megabyte(s)")
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     part1                    VOLUME GROUP:   datavg')
    @mock.add_retrun("lslv part1 | grep 'PPs:'", 'LPs:                10                     PPs:            128 ')
    @mock.add_retrun("lsvg datavg | grep 'FREE PPs:'", 'MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes) ')
    @mock.add_retrun("extendlv part1 128", '')
    assert_equal(true, @logicalvol.check_to_change)
    assert_equal(["Modify logical volume 'part1'"], @logicalvol.create())
    assert_equal('',@mock.residual())
  end

  def test_10_lv_exist_with_size_reduce()
    print("??? how to reduce ???\n")
    return
  end

end
