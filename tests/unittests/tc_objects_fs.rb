#
# Author:: Laurent GAY (<laurent.gay@atos.net>)
# Cookbook Name:: lvmaix
# Tests::  tc_tools.rb
#
# Copyright:: 2016

require "test/unit"

require_relative "../../libraries/tools"
require_relative "../../libraries/lvmobj_fs"
require_relative "mock"

class TestFileSystem < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new()
    @filesystem = AIXLVM::FileSystem.new('/opt/data',@mock)
    @filesystem.logical_volume='lv22'
    @filesystem.size='250M'
  end

  ############################### BASIC TESTS ############################### 

  def test_01_lv_dont_exists
    @mock.add_retrun('lslv lv22', nil)

    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change
    }
    assert_equal('logical volume "lv22" does not exist!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_02_fs_are_already_use_in_different_lv
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        32 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            1
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /                      LABEL:          /
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change()
    }
    assert_equal('logical volume "lv22" has already another file system!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_03_size_invalid
    @filesystem.size='250k'
    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change()
    }
    assert_equal('Invalid size!', exception.message)

    @filesystem.size='abc'
    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change()
    }
    assert_equal('Invalid size!', exception.message)

    @filesystem.size='25.14.14'
    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change()
    }
    assert_equal('Invalid size!', exception.message)
    assert_equal('',@mock.residual())

    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        32 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            1024
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        N/A                    LABEL:          None
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data",nil)
    @filesystem.size='25G'
    assert_equal(true,@filesystem.check_to_change())
  end

  def test_04_insufficient_space_available_not_exist
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            60
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        N/A                    LABEL:          None
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data",nil)
    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change
    }
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('',@mock.residual())
  end

  def test_05_insufficient_space_available_exist
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            60
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data","#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:part1:jfs2:::2031616:rw:yes:no")
    exception = assert_raise(AIXLVM::LVMException) {
      @filesystem.check_to_change
    }
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('',@mock.residual())
  end
  
  def test_06_fs_not_exist()
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        N/A                    LABEL:          None
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data",nil)
    @mock.add_retrun("crfs -v jfs2 -d lv22 -m /opt/data -A yes", '')
    @mock.add_retrun("chfs -a size=250M /opt/data", '')
    assert_equal(true, @filesystem.check_to_change)
    assert_equal(["Create file system '/opt/data' on logical volume 'lv22'"], @filesystem.create())
    assert_equal('',@mock.residual())
  end

  def test_07_fs_exist_no_change()
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data","#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::512000:rw:yes:no")
    assert_equal(false, @filesystem.check_to_change)
    assert_equal([], @filesystem.create())
    assert_equal('',@mock.residual())
  end

  def test_08_fs_exist_with_size_increase()
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data","#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::250:rw:yes:no")
    @mock.add_retrun("chfs -a size=250M /opt/data", '')
    assert_equal(true, @filesystem.check_to_change)
    assert_equal(["Modify file system '/opt/data'"], @filesystem.create())
    assert_equal('',@mock.residual())
  end

  def test_09_fs_exist_with_size_reduce()
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun("lsfs -c /opt/data","#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun("chfs -a size=250M /opt/data", '')
    assert_equal(true, @filesystem.check_to_change)
    assert_equal(["Modify file system '/opt/data'"], @filesystem.create())
    assert_equal('',@mock.residual())
  end
  
end
