#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_aix_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"

class TestAIXTools_VG < Test::Unit::TestCase
  def setup
    @tools = AIXLVM::Tools.new(AIXLVM::System.new())
    print("\n")
    system("varyoffvg othervg 2>/dev/null")
    system("exportvg othervg 2>/dev/null")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -S -f hdisk1 2>/dev/null")
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

  def test_08_get_vg_totalpp
    assert_equal(nil, @tools.get_vg_totalpp('foovg'))
    assert_equal(2012, @tools.get_vg_totalpp('datavg'))
  end

  def test_09_get_mirrorpool_from_vg
    assert_equal(nil, @tools.get_mirrorpool_from_vg('foovg'))
    assert_equal('', @tools.get_mirrorpool_from_vg('datavg'))
    assert_equal('', @tools.get_mirrorpool_from_vg('rootvg'))
  end

  def test_10_create_vg
    @tools.create_vg('othervg','hdisk4','mymirror')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.create_vg('foovg','hdisk10', nil)
    }
    assert_equal('system error:0516-306 mkvg: Unable to find physical volume hdisk10 in the Device', exception.message[0,80])
  end

  def test_11_modify_vg
    @tools.modify_vg('datavg','y')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.modify_vg('foovg','n')
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_12_add_pv_into_vg
    @tools.add_pv_into_vg('datavg','hdisk3', 'mymirror')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.add_pv_into_vg('foovg','hdisk2', nil)
    }
    assert_equal('system error:0516-306 extendvg: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_13_delete_pv_into_vg
    @tools.delete_pv_into_vg('datavg','hdisk2')
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.delete_pv_into_vg('foovg','hdisk3')
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end
end

class TestAIXTools_LV < Test::Unit::TestCase
  def setup
    @tools = AIXLVM::Tools.new(AIXLVM::System.new())
    print("\n")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -s 4 -f hdisk1 2>/dev/null")
    system("extendvg -f datavg hdisk2 2>/dev/null")
    system("mklv -y part1 datavg 20 2>/dev/null")
  end

  def test_01_get_vg_list_from_lv
    assert_equal('rootvg', @tools.get_vg_list_from_lv('hd1'))
    assert_equal(nil, @tools.get_vg_list_from_lv('hd'))
  end

  def test_02_get_nbpp_from_lv
    assert_equal(20, @tools.get_nbpp_from_lv('part1'))
    assert_equal(nil, @tools.get_nbpp_from_lv('part20'))
  end

  def test_03_get_vg_freepp
    assert_equal(2026, @tools.get_vg_freepp('datavg'))
    assert_equal(nil, @tools.get_vg_freepp('foovg'))
  end

  def test_04_create_lv
    @tools.create_lv('part2', 'datavg',10)
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.create_lv('part3','foovg', 20)
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_05_increase_lv
    @tools.increase_lv('part1', 10)
    exception = assert_raise(AIXLVM::LVMException) {
      @tools.increase_lv('part3', 20)
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find  part3 in the Device', exception.message[0,67])
    assert_equal(30, @tools.get_nbpp_from_lv('part1'))
  end

end