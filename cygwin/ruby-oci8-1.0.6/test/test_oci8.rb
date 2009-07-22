require 'oci8'
require 'runit/testcase'
require 'runit/cui/testrunner'
require File.dirname(__FILE__) + '/config'

class TestOCI8 < RUNIT::TestCase

  def setup
    @conn = get_oci_connection()
  end

  def teardown
    @conn.logoff
  end

  def test_select
    drop_table('test_table')
    sql = <<-EOS
CREATE TABLE test_table
  (C CHAR(10) NOT NULL,
   V VARCHAR2(20),
   N NUMBER(10, 2),
   D1 DATE, D2 DATE, D3 DATE, D4 DATE,
   INT NUMBER(30), BIGNUM NUMBER(30))
STORAGE (
   INITIAL 4k
   NEXT 4k
   MINEXTENTS 1
   MAXEXTENTS UNLIMITED
   PCTINCREASE 0)
EOS
    @conn.exec(sql)
    cursor = @conn.parse("INSERT INTO test_table VALUES (:C, :V, :N, :D1, :D2, :D3, :D4, :INT, :BIGNUM)")
    1.upto(10) do |i|
      if i == 1
	dt = [nil, OraDate]
      else
	dt = OraDate.new(2000 + i, 8, 3, 23, 59, 59)
      end
      cursor.exec(format("%10d", i * 10), i.to_s, i, dt, dt, dt, dt, i * 11111111111, i * 10000000000)
    end
    cursor.close
    cursor = @conn.parse("SELECT * FROM test_table ORDER BY c")
    cursor.define(5, Time) # define 5th column as Time
    cursor.define(6, Date) # define 6th column as Date
    cursor.define(7, DateTime) if defined? DateTime # define 7th column as DateTime
    cursor.define(8, Integer) # define 8th column as Integer
    cursor.define(9, Bignum) # define 9th column as Bignum
    cursor.exec
    assert_equal(["C", "V", "N", "D1", "D2", "D3", "D4", "INT", "BIGNUM"], cursor.get_col_names)
    1.upto(10) do |i|
      rv = cursor.fetch
      assert_equal(format("%10d", i * 10), rv[0])
      assert_equal(i.to_s, rv[1])
      assert_equal(i, rv[2])
      if i == 1
	assert_nil(rv[3])
	assert_nil(rv[4])
	assert_nil(rv[5])
	assert_nil(rv[6])
      else
	dt = OraDate.new(2000 + i, 8, 3, 23, 59, 59)
	assert_equal(dt, rv[3])
	assert_equal(dt.to_time, rv[4])
	assert_equal(dt.to_date, rv[5])
	assert_equal(dt.to_datetime, rv[6]) if defined? DateTime
      end
      assert_equal(i * 11111111111, rv[7])
      assert_equal(i * 10000000000, rv[8])
    end
    assert_nil(cursor.fetch)

    # fetch_hash with block
    cursor.exec
    i = 1
    cursor.fetch_hash do |row|
      assert_equal(format("%10d", i * 10), row['C'])
      assert_equal(i.to_s, row['V'])
      assert_equal(i, row['N'])
      if i == 1
	assert_nil(row['D1'])
	assert_nil(row['D2'])
	assert_nil(row['D3'])
	assert_nil(row['D4'])
      else
	dt = OraDate.new(2000 + i, 8, 3, 23, 59, 59)
	assert_equal(dt, row['D1'])
	assert_equal(dt.to_time, row['D2'])
	assert_equal(dt.to_date, row['D3'])
	assert_equal(dt.to_datetime, row['D4']) if defined? DateTime
      end
      assert_equal(i * 11111111111, row['INT'])
      assert_equal(i * 10000000000, row['BIGNUM'])
      i += 1
    end
    assert_equal(i, 11)

    cursor.close
    drop_table('test_table')
  end

  def test_bind_cursor
    drop_table('test_table')
    sql = <<-EOS
CREATE TABLE test_table
  (C CHAR(10) NOT NULL,
   V VARCHAR2(20),
   N NUMBER(10, 2),
   D1 DATE, D2 DATE, D3 DATE,
   INT NUMBER(30), BIGNUM NUMBER(30))
STORAGE (
   INITIAL 4k
   NEXT 4k
   MINEXTENTS 1
   MAXEXTENTS UNLIMITED
   PCTINCREASE 0)
EOS
    @conn.exec(sql)
    cursor = @conn.parse("INSERT INTO test_table VALUES (:C, :V, :N, :D1, :D2, :D3, :INT, :BIGNUM)")
    1.upto(10) do |i|
      if i == 1
	dt = [nil, OraDate]
      else
	dt = OraDate.new(2000 + i, 8, 3, 23, 59, 59)
      end
      cursor.exec(format("%10d", i * 10), i.to_s, i, dt, dt, dt, i, i)
    end
    cursor.close
    plsql = @conn.parse("BEGIN OPEN :cursor FOR SELECT * FROM test_table ORDER BY c; END;")
    plsql.bind_param(':cursor', OCI8::Cursor)
    plsql.exec
    cursor = plsql[':cursor']
    cursor.define(5, Time) # define 5th column as Time
    cursor.define(6, Date) # define 6th column as Date
    cursor.define(7, Integer) # define 7th column as Integer
    cursor.define(8, Bignum) # define 8th column as Integer
    assert_equal(["C", "V", "N", "D1", "D2", "D3", "INT", "BIGNUM"], cursor.get_col_names)
    1.upto(10) do |i|
      rv = cursor.fetch
      assert_equal(format("%10d", i * 10), rv[0])
      assert_equal(i.to_s, rv[1])
      assert_equal(i, rv[2])
      if i == 1
	assert_nil(rv[3])
	assert_nil(rv[4])
	assert_nil(rv[5])
      else
	dt = OraDate.new(2000 + i, 8, 3, 23, 59, 59)
	assert_equal(dt, rv[3])
	assert_equal(dt.to_time, rv[4])
	assert_equal(dt.to_date, rv[5])
      end
      assert_equal(i, rv[6])
      assert_equal(i, rv[7])
    end
    assert_nil(cursor.fetch)
    cursor.close
    drop_table('test_table')
  end

  def test_cursor_in_result_set
    drop_table('test_table')
    sql = <<-EOS
CREATE TABLE test_table (N NUMBER(10, 2))
STORAGE (
   INITIAL 4k
   NEXT 4k
   MINEXTENTS 1
   MAXEXTENTS UNLIMITED
   PCTINCREASE 0)
EOS
    @conn.exec(sql)
    cursor = @conn.parse("INSERT INTO test_table VALUES (:1)")
    1.upto(10) do |i|
      cursor.exec(i)
    end
    cursor.close
    cursor = @conn.exec(<<EOS)
select a.n, cursor (select a.n + b.n
                      from test_table b
                     order by n)
  from test_table a
 order by n
EOS
    1.upto(10) do |i|
      row = cursor.fetch
      assert_equal(i, row[0])
      cursor_in_result_set = row[1]
      1.upto(10) do |j|
        row2 = cursor_in_result_set.fetch
        assert_equal(i + j, row2[0])
      end
      assert_nil(cursor_in_result_set.fetch) # check end of row data
      cursor_in_result_set.close
    end
    assert_nil(cursor.fetch) # check end of row data
    drop_table('test_table')
  end

  if $oracle_version >= 1000
    # Oracle 10g or upper
    def test_binary_float
      cursor = @conn.parse("select CAST(:1 AS BINARY_FLOAT), CAST(:2 AS BINARY_DOUBLE) from dual")
      bind_val = -1.0
      cursor.bind_param(1, 10.0, OCI8::SQLT_IBDOUBLE)
      cursor.bind_param(2, nil, OCI8::SQLT_IBDOUBLE)
      while bind_val < 10.0
        cursor[2] = bind_val
        cursor.exec
        rv = cursor.fetch
        assert_equal(10.0, rv[0])
        assert_equal(bind_val, rv[1])
        bind_val += 1.234
      end
      [-1.0/0.0, # -Infinite
       +1.0/0.0, # +Infinite
       0.0/0.0   # NaN
      ].each do |num|
        cursor[1] = num
        cursor[2] = num
        cursor.exec
        rv = cursor.fetch
        if num.nan?
          assert(rv[0].nan?)
          assert(rv[1].nan?)
        else
          assert_equal(num, rv[0])
          assert_equal(num, rv[1])
        end
      end
      cursor.close
    end
  end

  def test_clob_nclob_and_blob
    drop_table('test_table')
    sql = <<-EOS
CREATE TABLE test_table (id number(5), C CLOB, NC NCLOB, B BLOB)
STORAGE (
   INITIAL 100k
   NEXT 100k
   MINEXTENTS 1
   MAXEXTENTS UNLIMITED
   PCTINCREASE 0)
EOS
    @conn.exec(sql)
    cursor = @conn.parse("INSERT INTO test_table VALUES (:1, :2, :3, :4)")
    0.upto(9) do |i|
      val = format('%d', i) * 4096
      cursor.exec(i, OCI8::CLOB.new(@conn, val), OCI8::NCLOB.new(@conn, val), OCI8::BLOB.new(@conn, val))
    end
    cursor.close
    cursor = @conn.exec("select * from test_table order by id")
    0.upto(9) do |i|
      rv = cursor.fetch
      val = format('%d', i) * 4096
      assert_equal(i, rv[0])
      assert_instance_of(OCI8::CLOB, rv[1])
      assert_instance_of(OCI8::NCLOB, rv[2])
      assert_instance_of(OCI8::BLOB, rv[3])
      assert_equal(val, rv[1].read)
      assert_equal(val, rv[2].read)
      assert_equal(val, rv[3].read)
    end
    assert_nil(cursor.fetch)
    cursor.close
    drop_table('test_table')
  end
end # TestOCI8

if $0 == __FILE__
  RUNIT::CUI::TestRunner.run(TestOCI8.suite())
end
