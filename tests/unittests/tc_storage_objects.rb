#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/storage_objects"
require_relative "mock"

class TestStorage_PV < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @stobj = AIXLVM::StObjPV.new(@mock,"hdisk1")
  end

  def test_01_exists
    @mock.add_retrun('lspv | grep "hdisk1 "','hdisk2  00f9fd4bf0d4e037  None
')
    @mock.add_retrun('lspv | grep "hdisk1 "',nil)
    assert_equal(true, @stobj.exist?)
    assert_equal(false, @stobj.exist?)
    assert_equal('',@mock.residual())
  end

  def test_04_get_vgname
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg
')
    assert_equal(nil, @stobj.get_vgname)
    assert_equal('datavg', @stobj.get_vgname)
    assert_equal('',@mock.residual())
  end
end

class TestStorage_VG < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
  end

  def test_02_exists
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          yes (one to one)         BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg datavg', nil)
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(false, @stobj.exist?)
    assert_equal('',@mock.residual())
  end

  def test_05_get_ppsize
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          yes (one to one)         BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg datavg', nil)
    assert_equal(4, @stobj.get_ppsize)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(nil, @stobj.get_ppsize)
    assert_equal('',@mock.residual())
  end

  def test_06_get_pv_list
    @mock.add_retrun("lsvg -p datavg", nil)
    @mock.add_retrun("lsvg -p datavg", 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205
')
    assert_equal([], @stobj.get_pv_list)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(['hdisk1','hdisk2'], @stobj.get_pv_list)
    assert_equal('',@mock.residual())
  end

  def test_07_hot_spare
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          yes (one to one)         BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg datavg', nil)
    assert_equal(true, @stobj.hot_spare?)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(false, @stobj.hot_spare?)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(nil, @stobj.hot_spare?)
    assert_equal('',@mock.residual())
  end

  def test_08_get_totalpp
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg datavg', nil)
    assert_equal(3018, @stobj.get_totalpp)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(nil, @stobj.get_totalpp)
    assert_equal('',@mock.residual())
  end

  def test_03_get_freepp
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg datavg', nil)
    assert_equal(2250, @stobj.get_freepp)
    @stobj = AIXLVM::StObjVG.new(@mock,"datavg")
    assert_equal(nil, @stobj.get_freepp)
    assert_equal('',@mock.residual())
  end

  def test_09_get_mirrorpool
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
    assert_equal(nil, @stobj.get_mirrorpool)
    assert_equal('', @stobj.get_mirrorpool)
    assert_equal('mymirror', @stobj.get_mirrorpool)
    assert_equal('???', @stobj.get_mirrorpool)
    assert_equal('',@mock.residual())
  end

  def test_10_create
    @mock.add_retrun("mkvg -y datavg -S -f hdisk1", '')
    @mock.add_retrun("mkvg -y datavg -S -p mirrorpool -f hdisk1", '')
    @mock.add_retrun("mkvg -y datavg -S -f hdisk2", nil)
    @stobj.create('hdisk1', nil)
    @stobj.create('hdisk1', 'mirrorpool')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('hdisk2', nil)
    }
    assert_equal('system error:mkvg -y datavg -S -f hdisk2', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_11_modify
    @mock.add_retrun("chvg -h y datavg", '')
    @mock.add_retrun("chvg -h n datavg", nil)
    @stobj.modify('y')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.modify('n')
    }
    assert_equal('system error:chvg -h n datavg', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_12_add_pv
    @mock.add_retrun("extendvg -f datavg hdisk2", '')
    @mock.add_retrun("extendvg -p mypool -f datavg hdisk2", '')
    @mock.add_retrun("extendvg -f datavg hdisk2", nil)
    @stobj.add_pv('hdisk2',nil)
    @stobj.add_pv('hdisk2','mypool')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.add_pv('hdisk2',nil)
    }
    assert_equal('system error:extendvg -f datavg hdisk2', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_13_delete_pv
    @mock.add_retrun("reducevg -d datavg hdisk3", '')
    @mock.add_retrun("reducevg -d datavg hdisk3", nil)
    @stobj.delete_pv('hdisk3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.delete_pv('hdisk3')
    }
    assert_equal('system error:reducevg -d datavg hdisk3', exception.message)
    assert_equal('',@mock.residual())
  end
end

class TestStorage_LV < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @stobj = AIXLVM::StObjLV.new(@mock,'hd1')
  end

  def test_03_exists
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
    @mock.add_retrun('lslv hd1', nil)
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjLV.new(@mock,'hd1')
    assert_equal(false, @stobj.exist?)
    assert_equal('',@mock.residual())
  end

  def test_01_get_vg
    @mock.add_retrun('lslv hd1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            12
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /home                  LABEL:          /home
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lslv hd1', nil)
    assert_equal('rootvg', @stobj.get_vg)
    @stobj = AIXLVM::StObjLV.new(@mock,'hd1')
    assert_equal(nil, @stobj.get_vg)
  end

  def test_02_get_nbpp
    @mock.add_retrun('lslv hd1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            12
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /home                  LABEL:          /home
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lslv hd1', nil)
    assert_equal(12, @stobj.get_nbpp)
    @stobj = AIXLVM::StObjLV.new(@mock,'hd1')
    assert_equal(nil, @stobj.get_nbpp)
  end

  def test_04_create
    @mock.add_retrun("mklv -y hd1 datavg 10", '')
    @mock.add_retrun("mklv -y hd1 datavg 20", nil)
    @stobj.create('datavg',10)
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('datavg', 20)
    }
    assert_equal('system error:mklv -y hd1 datavg 20', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_increase
    @mock.add_retrun("extendlv hd1 10", '')
    @mock.add_retrun("extendlv hd1 20", nil)
    @stobj.increase(10)
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.increase(20)
    }
    assert_equal('system error:extendlv hd1 20', exception.message)
    assert_equal('',@mock.residual())
  end

end