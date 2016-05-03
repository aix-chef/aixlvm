#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"
require_relative "mock"

class TestTools_VG < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @tools = AIXLVM::Tools.new(@mock)
  end

  def test_01_pv_exists
    @mock.add_retrun('lspv | grep "hdisk1 "','hdisk2  00f9fd4bf0d4e037  None
')
    @mock.add_retrun('lspv | grep "hdis "',nil)
    @mock.add_retrun('lspv | grep "foo "', nil)
    assert_equal(true, @tools.pv_exist?('hdisk1'))
    assert_equal(false, @tools.pv_exist?('hdis'))
    assert_equal(false, @tools.pv_exist?('foo'))
    assert_equal('',@mock.residual())
  end

  def test_02_vg_exists
    @mock.add_retrun('lsvg | grep rootvg', 'rootvg
')
    @mock.add_retrun('lsvg | grep root', nil)
    @mock.add_retrun('lsvg | grep datavg', nil)
    assert_equal(true, @tools.vg_exist?('rootvg'))
    assert_equal(false, @tools.vg_exist?('root'))
    assert_equal(false, @tools.vg_exist?('datavg'))
    assert_equal('',@mock.residual())
  end

  def test_03_lv_exists
    @mock.add_retrun('lslv hd1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        32 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            1
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /home                  LABEL:          /home
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lslv hd', nil)
    @mock.add_retrun('lslv hd123', nil)
    assert_equal(true, @tools.lv_exist?('hd1'))
    assert_equal(false, @tools.lv_exist?('hd'))
    assert_equal(false, @tools.lv_exist?('hd123'))
    assert_equal('',@mock.residual())
  end

  def test_04_get_vg_from_pv
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg
')
    assert_equal(nil, @tools.get_vg_from_pv('hdisk1'))
    assert_equal('datavg', @tools.get_vg_from_pv('hdisk2'))
    assert_equal('',@mock.residual())
  end

  def test_05_vg_ppsize
    @mock.add_retrun("lsvg foovg | grep 'PP SIZE:'", nil)
    @mock.add_retrun("lsvg datavg | grep 'PP SIZE:'", "VG STATE:           active                   PP SIZE:        124 megabyte(s)
")
    assert_equal(nil, @tools.get_vg_ppsize('foovg'))
    assert_equal(124, @tools.get_vg_ppsize('datavg'))
    assert_equal('',@mock.residual())
  end

  def test_06_get_pv_list_from_vg
    @mock.add_retrun("lsvg -p foovg", nil)
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205
')
    assert_equal([], @tools.get_pv_list_from_vg('foovg'))
    assert_equal(['hdisk1','hdisk2'], @tools.get_pv_list_from_vg('datavg'))
    assert_equal('',@mock.residual())
  end

  def test_07_vg_hot_spare
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          yes (one to one)         BB POLICY:      relocatable')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", 'HOT SPARE:          no                       BB POLICY:      relocatable')
    @mock.add_retrun("lsvg datavg | grep 'HOT SPARE:'", nil)
    assert_equal(true, @tools.vg_hot_spare?('datavg'))
    assert_equal(false, @tools.vg_hot_spare?('datavg'))
    assert_equal(nil, @tools.vg_hot_spare?('datavg'))
    assert_equal('',@mock.residual())
  end

  def test_08_get_vg_totalpp
    @mock.add_retrun("lsvg datavg | grep 'TOTAL PPs:'", nil)
    @mock.add_retrun("lsvg datavg | grep 'TOTAL PPs:'", 'VG PERMISSION:      read/write               TOTAL PPs:      511 (16352 megabytes)')
    @mock.add_retrun("lsvg datavg | grep 'TOTAL PPs:'", 'VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)')
    assert_equal(nil, @tools.get_vg_totalpp('datavg'))
    assert_equal(511, @tools.get_vg_totalpp('datavg'))
    assert_equal(3018, @tools.get_vg_totalpp('datavg'))
    assert_equal('',@mock.residual())
  end

  def test_09_get_mirrorpool_from_vg
    @mock.add_retrun("lspv -P | grep 'datavg'", nil)
    @mock.add_retrun("lspv -P | grep 'datavg'", 'hdisk1            datavg            
hdisk2            datavg            
hdisk3            datavg  
')
    @mock.add_retrun("lspv -P | grep 'datavg'", 'hdisk1            datavg             mymirror
hdisk2            datavg            mymirror
hdisk3            datavg            mymirror')
    @mock.add_retrun("lspv -P | grep 'datavg'", 'hdisk1            datavg           foomirror            
    hdisk2            datavg            mymirror
    hdisk3            datavg            mymirror')
    assert_equal(nil, @tools.get_mirrorpool_from_vg('datavg'))
    assert_equal('', @tools.get_mirrorpool_from_vg('datavg'))
    assert_equal('mymirror', @tools.get_mirrorpool_from_vg('datavg'))
    assert_equal('???', @tools.get_mirrorpool_from_vg('datavg'))
    assert_equal('',@mock.residual())
  end

  def test_10_create_vg
    @mock.add_retrun("mkvg -y datavg -S -f hdisk1", '')
    @mock.add_retrun("mkvg -y datavg -S -p mirrorpool -f hdisk1", '')
    @mock.add_retrun("mkvg -y foovg -S -f hdisk2", nil)
    @tools.create_vg('datavg','hdisk1', nil)
    @tools.create_vg('datavg','hdisk1', 'mirrorpool')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.create_vg('foovg','hdisk2', nil)
    }
    assert_equal('system error:mkvg -y foovg -S -f hdisk2', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_11_modify_vg
    @mock.add_retrun("chvg -h y datavg", '')
    @mock.add_retrun("chvg -h n foovg", nil)
    @tools.modify_vg('datavg','y')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.modify_vg('foovg','n')
    }
    assert_equal('system error:chvg -h n foovg', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_12_add_pv_into_vg
    @mock.add_retrun("extendvg -f datavg hdisk2", '')
    @mock.add_retrun("extendvg -p mypool -f datavg hdisk2", '')
    @mock.add_retrun("extendvg -f foovg hdisk2", nil)
    @tools.add_pv_into_vg('datavg','hdisk2',nil)
    @tools.add_pv_into_vg('datavg','hdisk2','mypool')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.add_pv_into_vg('foovg','hdisk2',nil)
    }
    assert_equal('system error:extendvg -f foovg hdisk2', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_13_delete_pv_into_vg
    @mock.add_retrun("reducevg -d datavg hdisk3", '')
    @mock.add_retrun("reducevg -d foovg hdisk3", nil)
    @tools.delete_pv_into_vg('datavg','hdisk3')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.delete_pv_into_vg('foovg','hdisk3')
    }
    assert_equal('system error:reducevg -d foovg hdisk3', exception.message)
    assert_equal('',@mock.residual())
  end

end

class TestTools_LV < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @tools = AIXLVM::Tools.new(@mock)
  end

  def test_01_get_vg_list_from_lv
    @mock.add_retrun('lslv hd1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        32 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            1
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /home                  LABEL:          /home
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lslv hd', nil)
    assert_equal('rootvg', @tools.get_vg_list_from_lv('hd1'))
    assert_equal(nil, @tools.get_vg_list_from_lv('hd'))
  end

  def test_02_get_nbpp_from_lv
    @mock.add_retrun("lslv hd1 | grep 'PPs:'", "LPs:                10                     PPs:            12 ")
    @mock.add_retrun("lslv hd3 | grep 'PPs:'", nil)
    assert_equal(12, @tools.get_nbpp_from_lv('hd1'))
    assert_equal(nil, @tools.get_nbpp_from_lv('hd3'))
  end

  def test_03_get_vg_freepp
    @mock.add_retrun("lsvg datavg | grep 'FREE PPs:'", "MAX LVs:            256                      FREE PPs:       116 (7424 megabytes) ")
    @mock.add_retrun("lsvg foovg | grep 'FREE PPs:'", nil)
    assert_equal(116, @tools.get_vg_freepp('datavg'))
    assert_equal(nil, @tools.get_vg_freepp('foovg'))
  end

  def test_04_create_lv
    @mock.add_retrun("mklv -y part1 datavg 10", '')
    @mock.add_retrun("mklv -y part2 foovg 20", nil)
    @tools.create_lv('part1', 'datavg',10)
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.create_lv('part2','foovg', 20)
    }
    assert_equal('system error:mklv -y part2 foovg 20', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_increase_lv
    @mock.add_retrun("extendlv part1 10", '')
    @mock.add_retrun("extendlv part2 20", nil)
    @tools.increase_lv('part1', 10)
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.increase_lv('part2', 20)
    }
    assert_equal('system error:extendlv part2 20', exception.message)
    assert_equal('',@mock.residual())
  end

end