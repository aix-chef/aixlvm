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
  end

  ############################### BASIC TESTS ############################### 

  def test_01_vg_dont_exists()
    @mock.add_retrun('lsvg datavg', nil)
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('volume group "datavg" does not exist!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_02_size_invalid()
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        124 megabyte(s)
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
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('size must be multiple to the PP size!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_03_lg_exist_on_other_vg()
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        64 megabyte(s)
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
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     part1                    VOLUME GROUP:   rootvg')
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('logical volume "part1" exist with other volume group!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_04_insufficient_space_available_not_exits()
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       116 (464 megabytes)
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
    @mock.add_retrun('lslv part1', nil)
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_insufficient_space_available_exits()
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       116 (464 megabytes)
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
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   datavg
    LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
    VG STATE:           active/complete        LV STATE:       opened/syncd
    TYPE:               jfs2                   WRITE VERIFY:   off
    MAX LPs:            512                    PP SIZE:        32 megabyte(s)
    COPIES:             1                      SCHED POLICY:   parallel
    LPs:                10                      PPs:            128
    STALE PPs:          0                      BB POLICY:      relocatable
    INTER-POLICY:       minimum                RELOCATABLE:    yes
    INTRA-POLICY:       center                 UPPER BOUND:    32
    MOUNT POINT:        /home                  LABEL:          /home
    MIRROR WRITE CONSISTENCY: on/ACTIVE
    EACH LP COPY ON A SEPARATE PV ?: yes
    Serialize IO ?:     NO
    INFINITE RETRY:     no
    ')
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_06_lv_not_exist()
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
    @mock.add_retrun('lslv part1', nil)
    @mock.add_retrun("mklv -c 1 -t jfs2 -y part1 datavg 256", '')
    assert_equal(true, @logicalvol.check_to_change)
    assert_equal(["Create logical volume 'part1' on volume groupe 'datavg'"], @logicalvol.create())
    assert_equal('',@mock.residual())
  end

  def test_07_lv_exist_no_change()
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       116 (464 megabytes)
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
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   datavg
    LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
    VG STATE:           active/complete        LV STATE:       opened/syncd
    TYPE:               jfs2                   WRITE VERIFY:   off
    MAX LPs:            512                    PP SIZE:        32 megabyte(s)
    COPIES:             1                      SCHED POLICY:   parallel
    LPs:                10                     PPs:            256
    STALE PPs:          0                      BB POLICY:      relocatable
    INTER-POLICY:       minimum                RELOCATABLE:    yes
    INTRA-POLICY:       center                 UPPER BOUND:    32
    MOUNT POINT:        /home                  LABEL:          /home
    MIRROR WRITE CONSISTENCY: on/ACTIVE
    EACH LP COPY ON A SEPARATE PV ?: yes
    Serialize IO ?:     NO
    INFINITE RETRY:     no
    ')

    assert_equal(false, @logicalvol.check_to_change)
    assert_equal([], @logicalvol.create())
    assert_equal('',@mock.residual())
  end

  def test_08_lv_exist_with_size_increase()
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
    @mock.add_retrun('lslv part1', 'LOGICAL VOLUME:     hd1                    VOLUME GROUP:   datavg
    LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
    VG STATE:           active/complete        LV STATE:       opened/syncd
    TYPE:               jfs2                   WRITE VERIFY:   off
    MAX LPs:            512                    PP SIZE:        32 megabyte(s)
    COPIES:             1                      SCHED POLICY:   parallel
    LPs:                10                     PPs:            128
    STALE PPs:          0                      BB POLICY:      relocatable
    INTER-POLICY:       minimum                RELOCATABLE:    yes
    INTRA-POLICY:       center                 UPPER BOUND:    32
    MOUNT POINT:        /home                  LABEL:          /home
    MIRROR WRITE CONSISTENCY: on/ACTIVE
    EACH LP COPY ON A SEPARATE PV ?: yes
    Serialize IO ?:     NO
    INFINITE RETRY:     no
    ')

    @mock.add_retrun("extendlv part1 128", '')
    assert_equal(true, @logicalvol.check_to_change)
    assert_equal(["Modify logical volume 'part1'"], @logicalvol.create())
    assert_equal('',@mock.residual())
  end

  def test_09_lv_exist_with_size_reduce()
    print("??? how to reduce ???\n")
    return
  end

  ############################### ADVANCED TESTS ############################### 

  def test_10_illegal_number_of_copies()
    @logicalvol.copies=4
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Illegal number of copies!', exception.message)
    
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          2                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         2                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @logicalvol.copies=3
    exception = assert_raise(AIXLVM::LVMException) {
      @logicalvol.check_to_change
    }
    assert_equal('Illegal number of copies!', exception.message)

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
    @mock.add_retrun('lslv part1', nil)
    assert_equal(true, @logicalvol.check_to_change)
    
    assert_equal('',@mock.residual())
  end

end
