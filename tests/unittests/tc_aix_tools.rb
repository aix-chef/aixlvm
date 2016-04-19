#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_aix_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"

class TestAIXTools < Test::Unit::TestCase
  def setup
    @tools = AIXLVM::Tools.new(AIXLVM::System.new())
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -s 4 -f hdisk1 2>/dev/null")
    system("extendvg -f datavg hdisk2 2>/dev/null")
  end

  def test_01_pv_exists
    assert_equal(true, @tools.pv_exist?('hdisk1'))
    assert_equal(false, @tools.pv_exist?('hdis'))
    assert_equal(false, @tools.pv_exist?('foo'))
    assert_equal(false, @tools.pv_exist?('hdisk5'))
  end

  def test_02_vg_exists
    assert_equal(true, @tools.vg_exist?('datavg'))
    assert_equal(false, @tools.vg_exist?('root'))
    assert_equal(false, @tools.vg_exist?('foovg'))
  end

  def test_03_lv_exists
    assert_equal(true, @tools.lv_exist?('hd1'))
    assert_equal(false, @tools.lv_exist?('hd'))
    assert_equal(false, @tools.lv_exist?('hd123'))
  end

  def test_04_get_vg_from_pv
    assert_equal('datavg', @tools.get_vg_from_pv('hdisk1'))
    assert_equal('datavg', @tools.get_vg_from_pv('hdisk2'))
    assert_equal(nil, @tools.get_vg_from_pv('hdisk3'))
    assert_equal(nil, @tools.get_vg_from_pv('hdisk4'))
    assert_equal(nil, @tools.get_vg_from_pv('hdisk5'))
  end

  def test_05_vg_ppsize
    assert_equal(nil, @tools.get_vg_ppsize('foovg'))
    assert_equal(4, @tools.get_vg_ppsize('datavg'))
  end

  def test_06_get_pv_list_from_vg
    assert_equal([], @tools.get_pv_list_from_vg('foovg'))
    assert_equal(['hdisk1','hdisk2'], @tools.get_pv_list_from_vg('datavg'))
  end

  def test_07_get_size_from_pv
    assert_equal(16384, @tools.get_size_from_pv('hdisk0'))
    assert_equal(4096, @tools.get_size_from_pv('hdisk1'))
    assert_equal(4096, @tools.get_size_from_pv('hdisk2'))
    assert_equal(4096, @tools.get_size_from_pv('hdisk3'))
    assert_equal(4096, @tools.get_size_from_pv('hdisk4'))
    assert_equal(0, @tools.get_size_from_pv('hdisk5'))
  end

end