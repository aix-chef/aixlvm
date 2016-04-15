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

  def test_pv_exists
    @mock.add_retrun('hdisk2  00f9fd4bf0d4e037  None
')
    @mock.add_retrun(nil)
    @mock.add_retrun(nil)
    assert_equal(true, @tools.is_pv_exist('hdisk1'))
    assert_equal(false, @tools.is_pv_exist('hdis'))
    assert_equal(false, @tools.is_pv_exist('foo'))
    assert_equal('lspv | grep "hdisk1 "', @mock.get_cmd.at(0))
    assert_equal('lspv | grep "hdis "', @mock.get_cmd.at(1))
    assert_equal('lspv | grep "foo "', @mock.get_cmd.at(2))
  end

  def test_vg_exists
    @mock.add_retrun('rootvg
')
    @mock.add_retrun(nil)
    @mock.add_retrun(nil)
    assert_equal(true, @tools.is_vg_exist('rootvg'))
    assert_equal(false, @tools.is_vg_exist('root'))
    assert_equal(false, @tools.is_vg_exist('datavg'))
    assert_equal('lsvg | grep rootvg', @mock.get_cmd.at(0))
    assert_equal('lsvg | grep root', @mock.get_cmd.at(1))
    assert_equal('lsvg | grep datavg', @mock.get_cmd.at(2))
  end

  def test_lv_exists
    @mock.add_retrun('LOGICAL VOLUME:     hd1                    VOLUME GROUP:   rootvg
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
    @mock.add_retrun(nil)
    @mock.add_retrun(nil)
    assert_equal(true, @tools.is_lv_exist('hd1'))
    assert_equal(false, @tools.is_lv_exist('hd'))
    assert_equal(false, @tools.is_lv_exist('hd123'))
    assert_equal('lslv hd1', @mock.get_cmd.at(0))
    assert_equal('lslv hd', @mock.get_cmd.at(1))
    assert_equal('lslv hd123', @mock.get_cmd.at(2))
  end

end