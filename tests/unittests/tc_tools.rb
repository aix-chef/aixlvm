#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"
require_relative "mock"

class TestTools < Test::Unit::TestCase
  def setup
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

  def test_07_get_size_from_pv
    @mock.add_retrun("bootinfo -s hdisk10", nil)
    @mock.add_retrun("bootinfo -s hdisk1", "4096")
    assert_equal(0, @tools.get_size_from_pv('hdisk10'))
    assert_equal(4096, @tools.get_size_from_pv('hdisk1'))
    assert_equal('',@mock.residual())
  end

end