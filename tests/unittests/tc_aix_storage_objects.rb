#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/storage_objects"
require_relative "mock"

class TestAIXStorage_PV < Test::Unit::TestCase
  def setup
    print("\n")
  end

  def test_01_exists
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk1")
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk10")
    assert_equal(false, @stobj.exist?)
  end

  def test_04_get_vgname
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk10")
    assert_equal(nil, @stobj.get_vgname)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk0")
    assert_equal('rootvg', @stobj.get_vgname)
  end

  def test_07_get_size
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk0")
    assert_equal(16384, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk1")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk2")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk3")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk4")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk5")
    assert_equal(0, @stobj.get_size)
  end
end

class TestAIXStorage_VG < Test::Unit::TestCase
  def setup
    print("\n")
    system("varyoffvg othervg 2>/dev/null")
    system("exportvg othervg 2>/dev/null")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -S -f hdisk1 2>/dev/null")
    system("chvg -h y datavg 2>/dev/null")
    system("extendvg -f datavg hdisk2 2>/dev/null")
  end

  def test_02_exists
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(false, @stobj.exist?)
  end

  def test_05_get_ppsize
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(4, @stobj.get_ppsize)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_ppsize)
  end

  def test_06_get_pv_list
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal([], @stobj.get_pv_list)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(['hdisk1','hdisk2'], @stobj.get_pv_list)
  end

  def test_07_hot_spare
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(true, @stobj.hot_spare?)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.hot_spare?)
  end

  def test_08_get_totalpp
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(2012, @stobj.get_totalpp)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_totalpp)
  end

  def test_03_get_freepp
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(2012, @stobj.get_freepp)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_freepp)
  end

  def test_09_get_mirrorpool
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_mirrorpool)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal('', @stobj.get_mirrorpool)
  end

  def test_10_create
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"othervg")
    @stobj.create('hdisk4','mymirror')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('hdisk10', nil)
    }
    assert_equal('system error:0516-306 mkvg: Unable to find physical volume hdisk10 in the Device', exception.message[0,80])
  end

  def test_11_modify
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    @stobj.modify('y')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.modify('n')
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_12_add_pv
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    @stobj.add_pv('hdisk3', 'mymirror')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.add_pv('hdisk2', nil)
    }
    assert_equal('system error:0516-306 extendvg: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_13_delete_pv
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    @stobj.delete_pv('hdisk2')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.delete_pv('hdisk3')
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end
end

class TestAIXStorage_LV < Test::Unit::TestCase
  def setup
    print("\n")
    print("\n")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -s 4 -f hdisk1 2>/dev/null")
    system("extendvg -f datavg hdisk2 2>/dev/null")
    system("mklv -y part1 datavg 20 2>/dev/null")
  end

  def test_03_exists
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd1')
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd100')
    assert_equal(false, @stobj.exist?)
  end

  def test_02_get_nbpp
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part1')
    assert_equal(20, @stobj.get_nbpp)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part20')
    assert_equal(nil, @stobj.get_nbpp)
  end

  def test_04_create
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part2')
    @stobj.create('datavg',10)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('foovg', 20)
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_05_increase
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part1')
    @stobj.increase(10)
    assert_equal(30, @stobj.get_nbpp)

    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.increase(20)
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find  part3 in the Device', exception.message[0,67])
  end

end