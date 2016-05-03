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
    print("\n")
    @mock = MockSystem.new()
    @volgroup = AIXLVM::VolumeGroup.new('datavg',@mock)
    @volgroup.physical_volumes=['hdisk1', 'hdisk2']
    @volgroup.use_as_hot_spare='n'
    @volgroup.mirror_pool_name=nil
  end

  def test_01_pv_dont_exists
    # One or more of the specified physical volume names do not exist
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
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
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)

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
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)

    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('The block sizes of all the specified physical volumes are not identical!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_illegal_mirror_pool_name
    @volgroup.mirror_pool_name="sz!erf-22"
    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('illegal_mirror_pool_name!', exception.message)
    @volgroup.mirror_pool_name="copy0poolcopy0pool"
    exception = assert_raise(AIXLVM::LVMException) {
      @volgroup.check_to_change()
    }
    assert_equal('illegal_mirror_pool_name!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_06_vg_not_exist
    # VG not exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg | grep datavg', nil)
    @mock.add_retrun('mkvg -y datavg -S -f hdisk1','')
    @mock.add_retrun('extendvg -f datavg hdisk2','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Create volume groupe 'datavg'","Extending 'hdisk1' to 'datavg'","Extending 'hdisk2' to 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_07_vg_not_exist_with_hot_spare
    # VG not exist and not error case
    @volgroup.use_as_hot_spare='y'
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg | grep datavg', nil)
    @mock.add_retrun('mkvg -y datavg -S -f hdisk1','')
    @mock.add_retrun('chvg -h y datavg','')
    @mock.add_retrun('extendvg -f datavg hdisk2','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Create volume groupe 'datavg'","Extending 'hdisk1' to 'datavg'","Extending 'hdisk2' to 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_08_vg_not_exist_with_mirror_pool
    # VG not exist and not error case
    @volgroup.mirror_pool_name="copy0pool"
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg | grep datavg', nil)
    @mock.add_retrun('mkvg -y datavg -S -p copy0pool -f hdisk1','')
    @mock.add_retrun('extendvg -p copy0pool -f datavg hdisk2','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Create volume groupe 'datavg'","Extending 'hdisk1' to 'datavg'","Extending 'hdisk2' to 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_09_vg_exist_no_change
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lspv -P | grep 'datavg'","")
    assert_equal(false, @volgroup.check_to_change())
    assert_equal([], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_10_vg_exist_with_change_add_disk
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lspv -P | grep 'datavg'","")
    @mock.add_retrun('extendvg -f datavg hdisk2','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Extending 'hdisk2' to 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_11_vg_exist_with_change_remove_disk
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205
    hdisk3            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lspv -P | grep 'datavg'","")
    @mock.add_retrun('reducevg -d datavg hdisk3','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Reducing 'hdisk3' to 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_12_vg_exist_with_change__add_remove_disk
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk3            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lspv -P | grep 'datavg'","")
    @mock.add_retrun('extendvg -f datavg hdisk2','')
    @mock.add_retrun('reducevg -d datavg hdisk3','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Extending 'hdisk2' to 'datavg'", "Reducing 'hdisk3' to 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_13_vg_exist_change_hot_spare
    # VG exist and not error case
    @volgroup.use_as_hot_spare='y'
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lspv -P | grep 'datavg'","")
    @mock.add_retrun('chvg -h y datavg','')
    assert_equal(true, @volgroup.check_to_change())
    assert_equal(["Modify 'datavg'"], @volgroup.create())
    assert_equal('',@mock.residual())
  end

  def test_14_vg_exist_change_mirror_pool
    # VG exist and not error case
    @volgroup.mirror_pool_name="copy0pool"
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lsvg | grep datavg', 'datavg')
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lspv -P | grep 'datavg'","")
    assert_equal(false, @volgroup.check_to_change())
    assert_equal([], @volgroup.create())
    assert_equal('',@mock.residual())
  end

end

class TestLogicalVolume < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @logicalvol = AIXLVM::LogicalVolume.new('part1',@mock)
    @logicalvol.group='datavg'
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
