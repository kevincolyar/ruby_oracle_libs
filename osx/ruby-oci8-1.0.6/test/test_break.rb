# High-level API
require 'oci8'
require 'runit/testcase'
require 'runit/cui/testrunner'
require File.dirname(__FILE__) + '/config'

class TestBreak < RUNIT::TestCase

  def report(str)
    printf "%d: %s\n", (Time.now - $start_time), str
  end
  
  PLSQL_DONE = 1
  OCIBREAK = 2
  SEND_BREAK = 3

  TIME_IN_PLSQL = 3
  TIME_TO_BREAK = 1
  MARGIN = 0.1

  def do_test_ocibreak(conn, expect)
    $start_time = Time.now

    th = Thread.start do 
      begin
	conn.exec("BEGIN DBMS_LOCK.SLEEP(#{TIME_IN_PLSQL}); END;")
	assert_equal(expect[PLSQL_DONE], (Time.now - $start_time + MARGIN).to_i)
      rescue OCIBreak
	assert_equal(expect[OCIBREAK], (Time.now - $start_time + MARGIN).to_i)
      end
    end

    sleep(TIME_TO_BREAK)
    assert_equal(expect[SEND_BREAK], (Time.now - $start_time + MARGIN).to_i)
    conn.break()
    th.join
  end

  def test_set_blocking_mode
    conn = get_oci_connection()
    conn.non_blocking = true
    assert_equal(true, conn.non_blocking?)
    conn.non_blocking = false
    assert_equal(false, conn.non_blocking?)
    conn.non_blocking = true
    assert_equal(true, conn.non_blocking?)
    conn.logoff()
  end

  def test_blocking_mode
    conn = get_oci_connection()
    conn.non_blocking = false
    expect = []
    expect[PLSQL_DONE] = TIME_IN_PLSQL
    expect[OCIBREAK]   = "Invalid status"
    expect[SEND_BREAK] = TIME_IN_PLSQL + TIME_TO_BREAK
    do_test_ocibreak(conn, expect)
    conn.logoff()
  end

  def test_non_blocking_mode
    conn = get_oci_connection()
    conn.non_blocking = true
    expect = []
    expect[PLSQL_DONE] = "Invalid status"
    if RUBY_PLATFORM =~ /mswin32|cygwin|mingw32|bccwin32/
      # raise after sleeping #{TIME_IN_PLSQL} seconds.
      expect[OCIBREAK] = TIME_IN_PLSQL
    else
      # raise immediately by OCI8#break.
      expect[OCIBREAK] = TIME_TO_BREAK
    end
    expect[SEND_BREAK]   = TIME_TO_BREAK
    do_test_ocibreak(conn, expect)
    conn.logoff()
  end
end

if $0 == __FILE__
  RUNIT::CUI::TestRunner.run(TestBreak.suite())
end
