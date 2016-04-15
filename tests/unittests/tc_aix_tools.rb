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
  end

  def test_pv_exists
    assert_equal(true, @tools.is_pv_exist('hdisk1'))
    assert_equal(false, @tools.is_pv_exist('hdis'))
    assert_equal(false, @tools.is_pv_exist('foo'))
  end

  def test_vg_exists
    assert_equal(true, @tools.is_vg_exist('rootvg'))
    assert_equal(false, @tools.is_vg_exist('root'))
    assert_equal(false, @tools.is_vg_exist('foovg'))
  end

  def test_lv_exists
    assert_equal(true, @tools.is_lv_exist('hd1'))
    assert_equal(false, @tools.is_lv_exist('hd'))
    assert_equal(false, @tools.is_lv_exist('hd123'))
  end

end