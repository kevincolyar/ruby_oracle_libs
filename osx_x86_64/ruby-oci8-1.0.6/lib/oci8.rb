#   --*- ruby -*--
# This is based on yoshidam's oracle.rb.
#
# sample one liner:
#  ruby -r oci8 -e 'OCI8.new("scott", "tiger", nil).exec("select * from emp") do |r| puts r.join(","); end'
#  # select all data from emp and print them as CVS format.

if RUBY_PLATFORM =~ /cygwin/
  # Cygwin manages environment variables by itself.
  # They don't synchroize with Win32's ones.
  # This set some Oracle's environment variables to win32's enviroment.
  require 'Win32API'
  win32setenv = Win32API.new('Kernel32.dll', 'SetEnvironmentVariableA', 'PP', 'I')
  ['NLS_LANG', 'ORA_NLS10', 'ORA_NLS32', 'ORA_NLS33', 'ORACLE_BASE', 'ORACLE_HOME', 'ORACLE_SID', 'TNS_ADMIN', 'LOCAL'].each do |name|
    val = ENV[name]
    win32setenv.call(name, val && val.dup)
  end
end

require 'oci8lib'
require 'date'
require 'thread'

class OCIBreak < OCIException
  def initialize(errstr = "Canceled by user request.")
    super(errstr)
  end
end

class OCIDefine # :nodoc:
  # define handle of OCILobLocator needs @env and @svc.
  def set_handle(env, svc, ctx) 
    @env = env
    @svc = svc
    @ctx = ctx
  end
end

class OCIBind # :nodoc:
  # define handle of OCILobLocator needs @env and @svc.
  def set_handle(env, svc, ctx)
    @env = env
    @svc = svc
    @ctx = ctx
  end
end

class OCI8
  @@error_in_initialization = nil
  begin
    OCIEnv.initialise(OCI_OBJECT)
    @@env = OCIEnv.init()
  rescue OCIError
    # don't raise this error at this time.
    @@error_in_initialization = $!
  end

  VERSION = '1.0.6'
  CLIENT_VERSION = '1020'
  # :stopdoc:
  RAW = OCI_TYPECODE_RAW
  STMT_SELECT = OCI_STMT_SELECT
  STMT_UPDATE = OCI_STMT_UPDATE
  STMT_DELETE = OCI_STMT_DELETE
  STMT_INSERT = OCI_STMT_INSERT
  STMT_CREATE = OCI_STMT_CREATE
  STMT_DROP = OCI_STMT_DROP
  STMT_ALTER = OCI_STMT_ALTER
  STMT_BEGIN = OCI_STMT_BEGIN
  STMT_DECLARE = OCI_STMT_DECLARE
  # :startdoc:

  # sql type (varchar, varchar2)
  SQLT_CHR = 1
  # sql type (number, double precision, float, real, numeric, int, integer, smallint)
  SQLT_NUM = 2
  # sql type (long)
  SQLT_LNG = 8
  # sql type (date)
  SQLT_DAT = 12
  # sql type (raw)
  SQLT_BIN = 23
  # sql type (long raw)
  SQLT_LBI = 24
  # sql type (char)
  SQLT_AFC = 96
  # sql type (binary_float)
  SQLT_IBFLOAT = 100
  # sql type (binary_double)
  SQLT_IBDOUBLE = 101
  # sql type (rowid)
  SQLT_RDD = 104
  # sql type (clob)
  SQLT_CLOB = 112
  # sql type (blob)
  SQLT_BLOB = 113
  # sql type (bfile)
  SQLT_BFILE = 114
  # sql type (result set)
  SQLT_RSET = 116
  # sql type (timestamp), not supported yet.
  #
  # If you want to fetch a timestamp before native timestamp data type
  # will be supported, fetch data as an OraDate by adding the following
  # code to your code.
  #   OCI8::BindType::Mapping[OCI8::SQLT_TIMESTAMP] = OCI8::BindType::OraDate
  SQLT_TIMESTAMP = 187
  # sql type (timestamp with time zone), not supported yet
  SQLT_TIMESTAMP_TZ = 188
  # sql type (interval year to month), not supported yet
  SQLT_INTERVAL_YM = 189
  # sql type (interval day to second), not supported yet
  SQLT_INTERVAL_DS = 190
  # sql type (timestamp with local time zone), not supported yet
  SQLT_TIMESTAMP_LTZ = 232

  # charset form
  SQLCS_IMPLICIT = 1
  SQLCS_NCHAR = 2

  # mapping of sql type number to sql type name.
  SQLT_NAMES = {}
  constants.each do |name|
    next if name.index("SQLT_") != 0
    val = const_get name.intern
    if val.is_a? Fixnum
      SQLT_NAMES[val] = name
    end
  end

  module Util # :nodoc:
    CTX_EXECFLAG = 0
    CTX_MUTEX = 1
    CTX_THREAD = 2
    CTX_LONG_READ_LEN = 3

    def do_ocicall(ctx)
      sleep_time = 0.01
      ctx[CTX_MUTEX].lock
      ctx[CTX_THREAD] = Thread.current
      begin
        yield
      rescue OCIStillExecuting # non-blocking mode
        ctx[CTX_MUTEX].unlock
        sleep(sleep_time)
        ctx[CTX_MUTEX].lock
        if ctx[CTX_THREAD].nil?
          raise OCIBreak
        end
        # expand sleep time to prevent busy loop.
        sleep_time *= 2 if sleep_time < 0.5
        retry
      ensure
        ctx[CTX_THREAD] = nil
        ctx[CTX_MUTEX].unlock
      end
    end # do_ocicall
  end
  include Util

  def parse_connect_string(connstr)
    if connstr !~ /^([^(\s|\@)]*)\/([^(\s|\@)]*)(?:\@(\S+))?(?:\s+as\s+(\S*)\s*)?$/i
      raise ArgumentError, %Q{invalid connect string "#{connstr}" (expect "username/password[@(tns_name|//host[:port]/service_name)][ as (sysdba|sysoper)]")}
    end
    uid, pswd, conn, privilege = $1, $2, $3, $4
    case privilege.upcase
    when 'SYSDBA'
      privilege = :SYSDBA
    when 'SYSOPER'
      privilege = :SYSOPER
    end if privilege
    if uid.length == 0 && pswd.length == 0
      # external credential
      uid = nil
      pswd = nil
    end
    return uid, pswd, conn, privilege
  end
  private :parse_connect_string

  def initialize(*args)
    raise @@error_in_initialization if @@error_in_initialization
    case args.length
    when 1
      uid, pswd, conn, privilege = parse_connect_string(args[0])
    when 2, 3, 4
      uid, pswd, conn, privilege = *args
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 1..4)"
    end
    case privilege
    when nil
      @privilege = nil
    when :SYSDBA
      @privilege = OCI_SYSDBA
    when :SYSOPER
      @privilege = OCI_SYSOPER
    else
      raise ArgumentError, "invalid privilege name #{privilege} (expect :SYSDBA, :SYSOPER or nil)"
    end

    @prefetch_rows = nil
    @ctx = [0, Mutex.new, nil, 65535]
    if @privilege or (uid.nil? and pswd.nil?)
      @svc = @@env.alloc(OCISvcCtx)
      @srv = @@env.alloc(OCIServer)
      @auth = @@env.alloc(OCISession)
      @privilege ||= OCI_DEFAULT

      if uid.nil? and pswd.nil?
        # external credential
        cred = OCI_CRED_EXT
      else
        # RDBMS credential
        cred = OCI_CRED_RDBMS
        @auth.attrSet(OCI_ATTR_USERNAME, uid)
        @auth.attrSet(OCI_ATTR_PASSWORD, pswd)
      end
      do_ocicall(@ctx) { @srv.attach(conn) }
      begin
        @svc.attrSet(OCI_ATTR_SERVER, @srv)
        do_ocicall(@ctx) { @auth.begin(@svc, cred, @privilege) }
        @svc.attrSet(OCI_ATTR_SESSION, @auth)
      rescue
        @srv.detach()
        raise
      end
    else
      @svc = @@env.logon(uid, pswd, conn)
    end
    @svc.instance_variable_set(:@env, @@env)
  end # initialize

  def logoff
    rollback()
    if @privilege
      do_ocicall(@ctx) { @auth.end(@svc) }
      do_ocicall(@ctx) { @srv.detach() }
    else
      @svc.logoff
    end
    @svc.free()
    true
  end # logoff

  def exec(sql, *bindvars)
    cursor = OCI8::Cursor.new(@@env, @svc, @ctx)
    cursor.prefetch_rows = @prefetch_rows if @prefetch_rows
    cursor.parse(sql)
    if cursor.type == OCI_STMT_SELECT && ! block_given?
      cursor.exec(*bindvars)
      cursor
    else
      begin
        ret = cursor.exec(*bindvars)
        case cursor.type
        when OCI_STMT_SELECT
          cursor.fetch { |row| yield(row) }   # for each row
          cursor.row_count()
        when OCI_STMT_BEGIN, OCI_STMT_DECLARE # PL/SQL block
          ary = []
          cursor.keys.sort.each do |key|
            ary << cursor[key]
          end
          ary
        else
          ret
        end
      ensure
        cursor.close
      end
    end
  end # exec

  def parse(sql)
    cursor = OCI8::Cursor.new(@@env, @svc, @ctx)
    cursor.prefetch_rows = @prefetch_rows if @prefetch_rows
    cursor.parse(sql)
    cursor
  end # parse

  def commit
    do_ocicall(@ctx) { @svc.commit }
    self
  end # commit

  def rollback
    do_ocicall(@ctx) { @svc.rollback }
    self
  end # rollback

  def autocommit?
    (@ctx[CTX_EXECFLAG] & OCI_COMMIT_ON_SUCCESS) == OCI_COMMIT_ON_SUCCESS
  end # autocommit?

  # add alias compatible with 'Oracle7 Module for Ruby'.
  alias autocommit autocommit?

  def autocommit=(ac)
    if ac
      commit()
      @ctx[CTX_EXECFLAG] |= OCI_COMMIT_ON_SUCCESS
    else
      @ctx[CTX_EXECFLAG] &= ~OCI_COMMIT_ON_SUCCESS
    end
    ac
  end # autocommit=

  def prefetch_rows=(rows)
    @prefetch_rows = rows
  end

  def non_blocking?
    @svc.attrGet(OCI_ATTR_NONBLOCKING_MODE)
  end # non_blocking?

  def non_blocking=(nb)
    if (nb ? true : false) != non_blocking?
      # If the argument and the current status are different,
      # toggle blocking / non-blocking.
      @srv = @svc.attrGet(OCI_ATTR_SERVER) unless @srv
      @srv.attrSet(OCI_ATTR_NONBLOCKING_MODE, nil)
    end
  end # non_blocking=

  def break
    @ctx[CTX_MUTEX].synchronize do
      @svc.break()
      unless @ctx[CTX_THREAD].nil?
        @ctx[CTX_THREAD].wakeup()
        @ctx[CTX_THREAD] = nil
        if @svc.respond_to?("reset")
          begin
            @svc.reset()
          rescue OCIError
            raise if $!.code != 1013 # ORA-01013
          end
        end
      end
    end
  end # break

  def long_read_len
    @ctx[OCI8::Util::CTX_LONG_READ_LEN]
  end

  def long_read_len=(len)
    @ctx[OCI8::Util::CTX_LONG_READ_LEN] = len
  end

  def describe_table(table_name)
    desc = @@env.alloc(OCIDescribe)
    desc.attrSet(OCI_ATTR_DESC_PUBLIC, -1)
    do_ocicall(@ctx) { desc.describeAny(@svc, table_name.to_s, OCI_PTYPE_UNK) }
    param = desc.attrGet(OCI_ATTR_PARAM)

    case param.attrGet(OCI_ATTR_PTYPE)
    when OCI_PTYPE_TABLE
      OCI8::Metadata::Table.new(param)
    when OCI_PTYPE_VIEW
      OCI8::Metadata::View.new(param)
    when OCI_PTYPE_SYN
      schema_name = param.attrGet(OCI_ATTR_SCHEMA_NAME)
      name = param.attrGet(OCI_ATTR_NAME)
      link = param.attrGet(OCI_ATTR_LINK)
      if link.length != 0
        translated_name = schema_name + '.' + name + '@' + link
      else
        translated_name = schema_name + '.' + name
      end
      describe_table(translated_name)
    else
      raise OCIError.new("ORA-04043: object #{table_name} does not exist", 4043)
    end
  end

  module BindType
    # get/set String
    String = Object.new
    class << String
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_CHR, val, length || (val.nil? ? nil : val.length)]
      end
    end

    # get/set RAW
    RAW = Object.new
    class << RAW
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_BIN, val, length || (val.nil? ? nil : val.length)]
      end
    end

    # get/set OraDate
    OraDate = Object.new
    class << OraDate
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_DAT, val, nil]
      end
    end

    # get/set Time
    Time = Object.new
    class << Time
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_DAT, val, nil]
      end
      def decorate(b)
        def b.set(val)
          super(val && ::OraDate.new(val.year, val.mon, val.mday, val.hour, val.min, val.sec))
        end
        def b.get()
          (val = super()) && val.to_time
        end
      end
    end

    # get/set Date
    Date = Object.new
    class << Date
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_DAT, val, nil]
      end
      def decorate(b)
        def b.set(val)
          super(val && ::OraDate.new(val.year, val.mon, val.mday))
        end
        def b.get()
          (val = super()) && val.to_date
        end
      end
    end

    if defined? ::DateTime # ruby 1.8.0 or upper
      # get/set DateTime 
      DateTime = Object.new
      class << DateTime
        def fix_type(env, val, length, precision, scale)
          [OCI8::SQLT_DAT, val, nil]
        end
        def decorate(b)
          def b.set(val)
            super(val && ::OraDate.new(val.year, val.mon, val.mday, val.hour, val.min, val.sec))
          end
          def b.get()
            (val = super()) && val.to_datetime
          end
        end
      end
    end

    # get/set Float
    Float = Object.new
    class << Float
      def fix_type(env, val, length, precision, scale)
        [::Float, val, nil]
      end
    end

    if defined? OCI_TYPECODE_BDOUBLE
      BinaryDouble = Object.new
      class << BinaryDouble
        def fix_type(env, val, length, precision, scale)
          [SQLT_IBDOUBLE, val, nil]
        end
      end
    end

    # get/set Fixnum
    Fixnum = Object.new
    class << Fixnum
      def fix_type(env, val, length, precision, scale)
        [::Fixnum, val, nil]
      end
    end

    # get/set Integer
    Integer = Object.new
    class << Integer
      def fix_type(env, val, length, precision, scale)
        [::Integer, val, nil]
      end
    end

    # get/set OraNumber
    OraNumber = Object.new
    class << OraNumber
      def fix_type(env, val, length, precision, scale)
        [::OraNumber, val, nil]
      end
    end

    # get/set Number (for OCI8::SQLT_NUM)
    Number = Object.new
    class << Number
      def fix_type(env, val, length, precision, scale)
        if scale == -127
          if precision == 0
            # NUMBER declared without its scale and precision. (Oracle 9.2.0.3 or above)
            ::OCI8::BindType::Mapping[:number_no_prec_setting].fix_type(env, val, length, precision, scale)
          else
            # FLOAT or FLOAT(p)
            [::Float, val, nil]
          end
        elsif scale == 0
          if precision == 0
            # NUMBER whose scale and precision is unknown
            # or
            # NUMBER declared without its scale and precision. (Oracle 9.2.0.2 or below)
            ::OCI8::BindType::Mapping[:number_unknown_prec].fix_type(env, val, length, precision, scale)
          elsif precision <= 9
            # NUMBER(p, 0); p is less than or equals to the precision of Fixnum
            [::Fixnum, val, nil]
          else
            # NUMBER(p, 0); p is greater than the precision of Fixnum
            [::Integer, val, nil]
          end
        else
          # NUMBER(p, s)
          if precision < 15 # the precision of double.
            [::Float, val, nil]
          else
            # use BigDecimal instead?
            [::OraNumber, val, nil]
          end
        end
      end
    end

    # get/set OCIRowid
    OCIRowid = Object.new
    class << OCIRowid
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_RDD, nil, val]
      end
    end

    # get/set BLOB
    BLOB = Object.new
    class << BLOB
      def check_type(val)
        raise ArgumentError, "invalid argument: #{val.class} (expect OCI8::BLOB)" unless val.is_a? OCI8::BLOB
      end
      def fix_type(env, val, length, precision, scale)
        unless val.nil?
          check_type(val)
          val = val.instance_variable_get(:@locator)
        end
        [OCI8::SQLT_BLOB, nil, val]
      end
      def decorate(b)
        def b.set(val)
          check_type(val)
          val = val.instance_variable_get(:@locator)
          super(val)
        end
        def b.get()
          (val = super()) && OCI8::BLOB.new(@svc, val.clone(@svc))
        end
      end
    end

    # get/set CLOB
    CLOB = Object.new
    class << CLOB
      def check_type(val)
        raise ArgumentError, "invalid argument: #{val.class} (expect OCI8::CLOB)" unless val.is_a? OCI8::CLOB
      end
      def fix_type(env, val, length, precision, scale)
        unless val.nil?
          check_type(val)
          val = val.instance_variable_get(:@locator)
        end
        [OCI8::SQLT_CLOB, nil, val]
      end
      def decorate(b)
        def b.set(val)
          check_type(val)
          val = val.instance_variable_get(:@locator)
          super(val)
        end
        def b.get()
          (val = super()) && OCI8::CLOB.new(@svc, val.clone(@svc))
        end
      end
    end

    # get/set NCLOB
    NCLOB = Object.new
    class << NCLOB
      def check_type(val)
        raise ArgumentError, "invalid argument: #{val.class} (expect OCI8::NCLOB)" unless val.is_a? OCI8::NCLOB
      end
      def fix_type(env, val, length, precision, scale)
        unless val.nil?
          check_type(val)
          val = val.instance_variable_get(:@locator)
        end
        [OCI8::SQLT_CLOB, nil, val]
      end
      def decorate(b)
        b.attrSet(OCI_ATTR_CHARSET_FORM, SQLCS_NCHAR)
        def b.set(val)
          check_type(val)
          val = val.instance_variable_get(:@locator)
          super(val)
        end
        def b.get()
          (val = super()) && OCI8::NCLOB.new(@svc, val.clone(@svc))
        end
      end
    end

    # get/set BFILE
    BFILE = Object.new
    class << BFILE
      def check_type(val)
        raise ArgumentError, "invalid argument: #{val.class} (expect OCI8::BFILE)" unless val.is_a? OCI8::BFILE
      end
      def fix_type(env, val, length, precision, scale)
        unless val.nil?
          check_type(val)
          val = val.instance_variable_get(:@locator)
        end
        [OCI8::SQLT_BFILE, nil, val]
      end
      def decorate(b)
        def b.set(val)
          check_type(val)
          val = val.instance_variable_get(:@locator)
          super(val)
        end
        def b.get()
          (val = super()) && OCI8::BFILE.new(@svc, val.clone(@svc))
        end
      end
    end

    # get Cursor
    Cursor = Object.new
    class << Cursor
      def fix_type(env, val, length, precision, scale)
        [OCI8::SQLT_RSET, nil, val]
      end
      def decorate(b)
        def b.get()
          (val = super()) && OCI8::Cursor.new(@env, @svc, @ctx, val)
        end
        def b.pre_fetch_hook()
          set(@env.alloc(OCIStmt))
        end
      end
    end

    Mapping = {}
  end # BindType

  class Cursor

    include OCI8::Util

    # for backward compatibility
    def self.select_number_as=(val) # :nodoc:
      if val == ::Fixnum
        bind_type = ::OCI8::BindType::Fixnum
      elsif val == ::Integer
        bind_type = ::OCI8::BindType::Integer
      elsif val == ::Float
        bind_type = ::OCI8::BindType::Float
      else
        raise ArgumentError, "must be Fixnum, Integer or Float"
      end
      ::OCI8::BindType::Mapping[:number_unknown_prec] = bind_type
    end

    # for backward compatibility
    def self.select_number_as # :nodoc:
      ::OCI8::BindType::Mapping[:number_unknown_prec].fix_type(nil, nil, nil, nil, nil)[0]
    end

    def initialize(env, svc, ctx, stmt = nil)
      if Process.pid != svc.pid
        raise "The connection cannot be reused in the forked process."
      end
      @env = env
      @svc = svc
      @ctx = ctx
      @binds = nil
      @parms = []
      @defns = nil
      if stmt.nil?
        @stmt = @env.alloc(OCIStmt)
        @stmttype = nil
      else
        @stmt = stmt
        @stmttype = @stmt.attrGet(OCI_ATTR_STMT_TYPE)
        define_columns()
      end
    end # initialize

    def parse(sql)
      free_binds()
      @parms = []
      @stmt.prepare(sql)
      @stmttype = do_ocicall(@ctx) { @stmt.attrGet(OCI_ATTR_STMT_TYPE) }
    end # parse

    def define(pos, type, length = nil)
      @defns = [] if @defns.nil?
      if type == String and length.nil?
        length = 4000
      end
      b = bind_or_define(:define, pos, nil, type, length, nil, nil, false)
      @defns[pos].free() unless @defns[pos].nil?
      @defns[pos] = b
      self
    end # define

    def bind_param(key, val, type = nil, length = nil)
      @binds = {} if @binds.nil?
      b = bind_or_define(:bind, key, val, type, length, nil, nil, false)
      @binds[key].free() unless @binds[key].nil?
      @binds[key] = b
      self
    end # bind_param

    # get bind value
    def [](key)
      if @binds.nil? or @binds[key].nil?
        return nil 
      end
      @binds[key].get()
    end

    # set bind value
    def []=(key, val)
      if @binds.nil? or @binds[key].nil?
        return nil 
      end
      @binds[key].set(val)
    end

    # get bind keys
    def keys
      if @binds.nil?
        []
      else
        @binds.keys
      end
    end

    def exec(*bindvars)
      bind_params(*bindvars)
      case @stmttype
      when OCI_STMT_SELECT
        do_ocicall(@ctx) { @stmt.execute(@svc, 0, OCI_DEFAULT) }
        define_columns()
      else
        do_ocicall(@ctx) { @stmt.execute(@svc, 1, @ctx[CTX_EXECFLAG]) }
        @stmt.attrGet(OCI_ATTR_ROW_COUNT)
      end
    end # exec

    def type
      @stmttype
    end

    def row_count
      @stmt.attrGet(OCI_ATTR_ROW_COUNT)
    end

    def get_col_names
      @parms.collect do |p|
        do_ocicall(@ctx) { p.attrGet(OCI_ATTR_NAME) }
      end
    end # get_col_names

    # add alias compatible with 'Oracle7 Module for Ruby'.
    alias getColNames get_col_names

    def column_metadata
      @parms.collect do |p|
        OCI8::Metadata::Column.new(p)
      end
    end

    def fetch
      if iterator?
        while ret = fetch_a_row()
          yield(ret)
        end
      else
        fetch_a_row()
      end
    end # fetch

    def fetch_hash
      if iterator?
        while ret = fetch_a_hash_row()
          yield(ret)
        end
      else
        fetch_a_hash_row
      end
    end # fetch_hash

    def close
      @env = nil
      @svc = nil
      free_defns()
      free_binds()
      @stmt.free()
      @parms = nil
      @stmttype = nil
    end # close

    # Get the rowid of the last inserted/updated/deleted row.
    def rowid
      # get the binary rowid
      rid = @stmt.attrGet(OCI_ATTR_ROWID)
      # convert it to a string rowid.
      if rid.respond_to? :to_s
        # (Oracle 9.0 or upper)
        rid.to_s
      else
        # (Oracle 8.1 or lower)
        stmt = @env.alloc(OCIStmt)
        stmt.prepare('begin :1 := :2; end;')
        b = stmt.bindByPos(1, OCI8::SQLT_CHR, 64)
        stmt.bindByPos(2, OCI8::SQLT_RDD, rid)
        do_ocicall(@ctx) { stmt.execute(@svc, 1, OCI_DEFAULT) }
        str_rid = b.get()
        stmt.free()
        str_rid
      end
    end

    def prefetch_rows=(rows)
      @stmt.attrSet(OCI_ATTR_PREFETCH_ROWS, rows)
    end

    private

    def bind_or_define(bind_type, key, val, type, length, precision, scale, strict_check)
      if type.nil?
        if val.nil?
          raise "bind type is not given." if type.nil?
        else
          if val.class == Class
            type = val
            val = nil
          else
            type = val.class
          end
        end
      end

      binder = OCI8::BindType::Mapping[type]
      if binder
        type, val, option = binder.fix_type(@env, val, length, precision, scale)
      else
        if strict_check
          raise "unsupported datatype: #{SQLT_NAMES[type] ? SQLT_NAMES[type] : type}"
        else
          option = length
        end
      end

      case bind_type
      when :bind
        if key.is_a? Fixnum
          b = @stmt.bindByPos(key, type, option)
        else
          b = @stmt.bindByName(key, type, option)
        end
      when :define
        b = @stmt.defineByPos(key, type, option)
      end
      b.set_handle(@env, @svc, @ctx)

      if binder && binder.respond_to?(:decorate)
        # decorate the bind handle.
        binder.decorate(b)
      end

      b.set(val) unless val.nil?
      b
    end # bind_or_define

    def define_columns
      num_cols = @stmt.attrGet(OCI_ATTR_PARAM_COUNT)
      1.upto(num_cols) do |i|
        @parms[i - 1] = @stmt.paramGet(i)
      end
      @defns = Array.new(@parms.size) if @defns.nil?
      1.upto(num_cols) do |i|
        @defns[i] = define_a_column(i) if @defns[i].nil?
      end
      num_cols
    end # define_columns

    def define_a_column(i)
      p = @parms[i - 1]
      datatype = do_ocicall(@ctx) { p.attrGet(OCI_ATTR_DATA_TYPE) }
      datasize = do_ocicall(@ctx) { p.attrGet(OCI_ATTR_DATA_SIZE) }
      precision = do_ocicall(@ctx) { p.attrGet(OCI_ATTR_PRECISION) }
      scale = do_ocicall(@ctx) { p.attrGet(OCI_ATTR_SCALE) }
      csfrm = nil

      case datatype
      when SQLT_CHR, SQLT_AFC
        # character size may become large on character set conversion.
        # The length of a half-width kana is one in Shift_JIS, two in EUC-JP,
        # three in UTF-8.
        datasize *= 3
      when SQLT_LNG, SQLT_LBI
        datasize = @ctx[OCI8::Util::CTX_LONG_READ_LEN]
      when SQLT_CLOB
        datatype = :nclob if p.attrGet(OCI_ATTR_CHARSET_FORM) == SQLCS_NCHAR
      when SQLT_BIN
        datasize *= 2 if OCI8::BindType::Mapping[datatype] == OCI8::BindType::String
      when SQLT_RDD
        datasize = 64
      end

      bind_or_define(:define, i, nil, datatype, datasize, precision, scale, true)
    end # define_a_column

    def bind_params(*bindvars)
      bindvars.each_with_index do |val, i|
        if val.is_a? Array
          bind_param(i + 1, val[0], val[1], val[2])
        else
          bind_param(i + 1, val)
        end
      end
    end # bind_params

    def fetch_a_row
      @defns.each do |d|
        d.pre_fetch_hook if d.respond_to? :pre_fetch_hook
      end
      res = do_ocicall(@ctx) { @stmt.fetch() }
      return nil if res.nil?
      res.collect do |r| r.get() end
    end # fetch_a_row

    def fetch_a_hash_row
      if rs = fetch_a_row()
        ret = {}
        @parms.each do |p|
          ret[p.attrGet(OCI_ATTR_NAME)] = rs.shift
        end
        ret
      else 
        nil
      end
    end # fetch_a_hash_row

    def free_defns
      unless @defns.nil?
        @defns.each do |b|
          b.free() unless b.nil?
        end
      end
      @defns = nil
    end # free_defns

    def free_binds
      unless @binds.nil?
        @binds.each_value do |b|
          b.free()
        end
      end
      @binds = nil
    end # free_binds
  end # OCI8::Cursor

  class LOB
    attr :pos
    def initialize(svc, val)
      svc = svc.instance_variable_get(:@svc) if svc.is_a? OCI8
      raise "invalid argument" unless svc.is_a? OCISvcCtx
      @env = svc.instance_variable_get(:@env)
      @svc = svc
      @csid = 0
      @pos = 0
      if val.is_a? OCILobLocator
        @locator = val
      else
        @locator = @env.alloc(OCILobLocator)
        @locator.create_temporary(@svc, @csid, @csfrm, @lobtype, false, nil)
        val.nil? || write(val.to_s)
      end
    end

    def available?
      @locator.is_initialized?(@env)
    end

    def truncate(len)
      raise "uninitialized LOB" unless available?
      @locator.trim(@svc, len)
      self
    end

    def read(readlen = nil)
      rest = self.size - @pos
      return nil if rest == 0 # eof.
      if readlen.nil? or readlen > rest
        readlen = rest # read until EOF.
      end
      begin
        rv = @locator.read(@svc, @pos + 1, readlen, @csid, @csfrm)
      rescue OCIError
        raise if $!.code != 22289
        # ORA-22289: cannot perform FILEREAD operation on an unopened file or LOB.
        open
        retry
      end
      @pos += readlen
      rv
    end

    def write(data)
      raise "uninitialized LOB" unless available?
      size = @locator.write(@svc, @pos + 1, data, @csid, @csfrm)
      @pos += size
      size
    end

    def size
      raise "uninitialized LOB" unless available?
      begin
        rv = @locator.getLength(@svc)
      rescue OCIError
        raise if $!.code != 22289
        # ORA-22289: cannot perform FILEREAD operation on an unopened file or LOB.
        open
        retry
      end
      rv
    end

    def size=(len)
      raise "uninitialized LOB" unless available?
      @locator.trim(@svc, len)
      len
    end

    def chunk_size # in bytes.
      raise "uninitialized LOB" unless available?
      @locator.getChunkSize(@svc)
    end

    def eof?
      @pos == size
    end

    def tell
      @pos
    end

    def seek(pos, whence = IO::SEEK_SET)
      length = size
      case whence
      when IO::SEEK_SET
        @pos = pos
      when IO::SEEK_CUR
        @pos += pos
      when IO::SEEK_END
        @pos = length + pos
      end
      @pos = length if @pos >= length
      @pos = 0 if @pos < 0
      self
    end

    def rewind
      @pos = 0
      self
    end

    def close
      @locator.free()
    end

  end

  class BLOB < LOB
    def initialize(*arg)
      @lobtype = 1
      @csfrm = SQLCS_IMPLICIT
      super(*arg)
    end
  end

  class CLOB < LOB
    def initialize(*arg)
      @lobtype = 2
      @csfrm = SQLCS_IMPLICIT
      super(*arg)
    end
  end

  class NCLOB < LOB
    def initialize(*arg)
      @lobtype = 2
      @csfrm = SQLCS_NCHAR
      super(*arg)
    end
  end

  class BFILE < LOB
    attr_reader :dir_alias
    attr_reader :filename
    def initialize(svc, locator)
      raise "invalid argument" unless svc.is_a? OCISvcCtx
      raise "invalid argument" unless locator.is_a? OCIFileLocator
      @env = svc.instance_variable_get(:@env)
      @svc = svc
      @locator = locator
      @pos = 0
      @dir_alias, @filename = @locator.name(@env)
    end

    def dir_alias=(val)
      @locator.set_name(@env, val, @filename)
      @dir_alias = val
    end

    def filename=(val)
      @locator.set_name(@env, @dir_alias, val)
      @filename = val
    end

    def truncate(len)
      raise RuntimeError, "cannot modify a read-only BFILE object"
    end
    def write(data)
      raise RuntimeError, "cannot modify a read-only BFILE object"
    end
    def size=(len)
      raise RuntimeError, "cannot modify a read-only BFILE object"
    end

    def open
      begin
        @locator.open(@svc, :file_readonly)
      rescue OCIError
        raise if $!.code != 22290
        # ORA-22290: operation would exceed the maximum number of opened files or LOBs.
        @svc.close_all_files
        @locator.open(@svc, :file_readonly)
      end
    end

    def exists?
      @locator.exists?(@svc)
    end
  end

  # bind or explicitly define
  BindType::Mapping[::String]       = BindType::String
  BindType::Mapping[::OCI8::RAW]    = BindType::RAW
  BindType::Mapping[::OraDate]      = BindType::OraDate
  BindType::Mapping[::Time]         = BindType::Time
  BindType::Mapping[::Date]         = BindType::Date
  BindType::Mapping[::DateTime]     = BindType::DateTime if defined? DateTime
  BindType::Mapping[::OCIRowid]     = BindType::OCIRowid
  BindType::Mapping[::OCI8::BLOB]   = BindType::BLOB
  BindType::Mapping[::OCI8::CLOB]   = BindType::CLOB
  BindType::Mapping[::OCI8::NCLOB]  = BindType::NCLOB
  BindType::Mapping[::OCI8::BFILE]  = BindType::BFILE
  BindType::Mapping[::OCI8::Cursor] = BindType::Cursor

  # implicitly define

  # datatype        type     size prec scale
  # -------------------------------------------------
  # CHAR(1)       SQLT_AFC      1    0    0
  # CHAR(10)      SQLT_AFC     10    0    0
  BindType::Mapping[OCI8::SQLT_AFC] = BindType::String

  # datatype        type     size prec scale
  # -------------------------------------------------
  # VARCHAR(1)    SQLT_CHR      1    0    0
  # VARCHAR(10)   SQLT_CHR     10    0    0
  # VARCHAR2(1)   SQLT_CHR      1    0    0
  # VARCHAR2(10)  SQLT_CHR     10    0    0
  BindType::Mapping[OCI8::SQLT_CHR] = BindType::String

  # datatype        type     size prec scale
  # -------------------------------------------------
  # RAW(1)        SQLT_BIN      1    0    0
  # RAW(10)       SQLT_BIN     10    0    0
  BindType::Mapping[OCI8::SQLT_BIN] = BindType::RAW

  # datatype        type     size prec scale
  # -------------------------------------------------
  # LONG          SQLT_LNG      0    0    0
  BindType::Mapping[OCI8::SQLT_LNG] = BindType::String

  # datatype        type     size prec scale
  # -------------------------------------------------
  # LONG RAW      SQLT_LBI      0    0    0
  BindType::Mapping[OCI8::SQLT_LBI] = BindType::RAW

  # datatype        type     size prec scale
  # -------------------------------------------------
  # CLOB          SQLT_CLOB  4000    0    0
  BindType::Mapping[OCI8::SQLT_CLOB] = BindType::CLOB
  BindType::Mapping[:nclob] = BindType::NCLOB  # if OCI_ATTR_CHARSET_FORM is SQLCS_NCHAR.

  # datatype        type     size prec scale
  # -------------------------------------------------
  # BLOB          SQLT_BLOB  4000    0    0
  BindType::Mapping[OCI8::SQLT_BLOB] = BindType::BLOB

  # datatype        type     size prec scale
  # -------------------------------------------------
  # BFILE         SQLT_BFILE  4000    0    0
  BindType::Mapping[OCI8::SQLT_BFILE] = BindType::BFILE

  # datatype        type     size prec scale
  # -------------------------------------------------
  # DATE          SQLT_DAT      7    0    0
  BindType::Mapping[OCI8::SQLT_DAT] = BindType::OraDate

  BindType::Mapping[OCI8::SQLT_TIMESTAMP] = BindType::OraDate

  # datatype        type     size prec scale
  # -------------------------------------------------
  # ROWID         SQLT_RDD      4    0    0
  BindType::Mapping[OCI8::SQLT_RDD] = BindType::String

  # datatype           type     size prec scale
  # -----------------------------------------------------
  # FLOAT            SQLT_NUM     22  126 -127
  # FLOAT(1)         SQLT_NUM     22    1 -127
  # FLOAT(126)       SQLT_NUM     22  126 -127
  # DOUBLE PRECISION SQLT_NUM     22  126 -127
  # REAL             SQLT_NUM     22   63 -127
  # calculated value SQLT_NUM     22    0    0
  # NUMBER           SQLT_NUM     22    0    0 (Oracle 9.2.0.2 or below)
  # NUMBER           SQLT_NUM     22    0 -127 (Oracle 9.2.0.3 or above)
  # NUMBER(1)        SQLT_NUM     22    1    0
  # NUMBER(38)       SQLT_NUM     22   38    0
  # NUMBER(1, 0)     SQLT_NUM     22    1    0
  # NUMBER(38, 0)    SQLT_NUM     22   38    0
  # NUMERIC          SQLT_NUM     22   38    0
  # INT              SQLT_NUM     22   38    0
  # INTEGER          SQLT_NUM     22   38    0
  # SMALLINT         SQLT_NUM     22   38    0
  BindType::Mapping[OCI8::SQLT_NUM] = BindType::Number

  # This parameter specify the ruby datatype for
  # calculated number values whose precision is unknown in advance.
  #   select col1 * 1.1 from tab1;
  # For Oracle 9.2.0.2 or below, this is also used for NUMBER
  # datatypes that have no explicit setting of their precision
  # and scale.
  BindType::Mapping[:number_unknown_prec] = BindType::Float

  # This parameter specify the ruby datatype for NUMBER datatypes
  # that have no explicit setting of their precision and scale.
  #   create table tab1 (col1 number);
  #   select col1 from tab1;
  # note: This is available only on Oracle 9.2.0.3 or above.
  # see:  Oracle 9.2.0.x Patch Set Notes.
  BindType::Mapping[:number_no_prec_setting] = BindType::Float

  # datatype         type       size prec scale
  # -------------------------------------------------
  # BINARY FLOAT   SQLT_IBFLOAT   4    0    0
  # BINARY DOUBLE  SQLT_IBDOUBLE  8    0    0
  if defined? BindType::BinaryDouble
    BindType::Mapping[OCI8::SQLT_IBFLOAT] = BindType::BinaryDouble
    BindType::Mapping[OCI8::SQLT_IBDOUBLE] = BindType::BinaryDouble
  else
    BindType::Mapping[OCI8::SQLT_IBFLOAT] = BindType::Float
    BindType::Mapping[OCI8::SQLT_IBDOUBLE] = BindType::Float
  end

  # cursor in result set.
  BindType::Mapping[SQLT_RSET] = BindType::Cursor
end # OCI8

class OraDate
  def to_time
    begin
      Time.local(year, month, day, hour, minute, second)
    rescue ArgumentError
      msg = format("out of range of Time (expect between 1970-01-01 00:00:00 UTC and 2037-12-31 23:59:59, but %04d-%02d-%02d %02d:%02d:%02d %s)", year, month, day, hour, minute, second, Time.at(0).zone)
      raise RangeError.new(msg)
    end
  end

  def to_date
    Date.new(year, month, day)
  end

  if defined? DateTime # ruby 1.8.0 or upper
    def to_datetime
      DateTime.new(year, month, day, hour, minute, second)
    end
  end

  def yaml_initialize(type, val) # :nodoc:
    initialize(*val.split(/[ -\/:]+/).collect do |i| i.to_i end)
  end

  def to_yaml(opts = {}) # :nodoc:
    YAML.quick_emit(object_id, opts) do |out|
      out.scalar(taguri, self.to_s, :plain)
    end
  end

  def to_json(options=nil) # :nodoc:
    to_datetime.to_json(options)
  end
end

class OraNumber
  def yaml_initialize(type, val) # :nodoc:
    initialize(val)
  end

  def to_yaml(opts = {}) # :nodoc:
    YAML.quick_emit(object_id, opts) do |out|
      out.scalar(taguri, self.to_s, :plain)
    end
  end

  def to_json(options=nil) # :nodoc:
    to_s
  end
end


#
# OCI8::Metadata::Column
#
class OCI8
  module Metadata

    # Abstract super class for Metadata classes.
    class Base
      # This class's code was copied from svn trunk whick will be ruby-oci8 2.0.

      # SQLT values to name
      DATA_TYPE_MAP = {} # :nodoc:
      TYPE_PROC_MAP = {} # :nodoc:

      # SQLT_CHR
      DATA_TYPE_MAP[1] = :varchar2
      TYPE_PROC_MAP[1] = Proc.new do |p|
        if p.charset_form == :nchar
          "NVARCHAR2(#{p.char_size})"
        else
          if (p.respond_to? :char_used?) && (p.char_used?)
            "VARCHAR2(#{p.char_size} CHAR)"
          else
            "VARCHAR2(#{p.data_size})"
          end
        end
      end

      # SQLT_NUM
      DATA_TYPE_MAP[2] = :number
      TYPE_PROC_MAP[2] = Proc.new do |p|
        begin
          case p.scale
          when -127
            case p.precision
            when 0
              "NUMBER"
            when 126
              "FLOAT"
            else
              "FLOAT(#{p.precision})"
            end
          when 0
            case p.precision
            when 0
              "NUMBER"
            else
              "NUMBER(#{p.precision})"
            end
          else
            "NUMBER(#{p.precision},#{p.scale})"
          end
        rescue OCIError
          "NUMBER"
        end
      end

      # SQLT_LNG
      DATA_TYPE_MAP[8] = :long
      TYPE_PROC_MAP[8] = "LONG"

      # SQLT_DAT
      DATA_TYPE_MAP[12] = :date
      TYPE_PROC_MAP[12] = "DATE"

      # SQLT_BIN
      DATA_TYPE_MAP[23] = :raw
      TYPE_PROC_MAP[23] = Proc.new do |p|
        "RAW(#{p.data_size})"
      end

      # SQLT_LBI
      DATA_TYPE_MAP[24] = :long_raw
      TYPE_PROC_MAP[24] = "LONG RAW"

      # SQLT_AFC
      DATA_TYPE_MAP[96] = :char
      TYPE_PROC_MAP[96] = Proc.new do |p|
        if p.charset_form == :nchar
          "NCHAR(#{p.char_size})"
        else
          if (p.respond_to? :char_used?) && (p.char_used?)
            "CHAR(#{p.char_size} CHAR)"
          else
            "CHAR(#{p.data_size})"
          end
        end
      end

      # SQLT_IBFLOAT
      DATA_TYPE_MAP[100] = :binary_float
      TYPE_PROC_MAP[100] = "BINARY_FLOAT"

      # SQLT_IBDOUBLE
      DATA_TYPE_MAP[101] = :binary_double
      TYPE_PROC_MAP[101] = "BINARY_DOUBLE"

      # SQLT_RDD
      DATA_TYPE_MAP[104] = :rowid
      TYPE_PROC_MAP[104] = "ROWID"

      # SQLT_NTY
      DATA_TYPE_MAP[108] = :named_type
      TYPE_PROC_MAP[108] = "Object"

      # SQLT_REF
      DATA_TYPE_MAP[110] = :ref
      TYPE_PROC_MAP[110] = "REF"

      # SQLT_CLOB
      DATA_TYPE_MAP[112] = :clob
      TYPE_PROC_MAP[112] = Proc.new do |p|
        if p.charset_form == :nchar
          "NCLOB"
        else
          "CLOB"
        end
      end

      # SQLT_BLOB
      DATA_TYPE_MAP[113] = :blob
      TYPE_PROC_MAP[113] = "BLOB"

      # SQLT_BFILE
      DATA_TYPE_MAP[114] = :bfile
      TYPE_PROC_MAP[114] = "BFILE"

      # SQLT_TIMESTAMP
      DATA_TYPE_MAP[187] = :timestamp
      TYPE_PROC_MAP[187] = Proc.new do |p|
        fsprecision = p.fsprecision
        if fsprecision == 6
          "TIMESTAMP"
        else
          "TIMESTAMP(#{fsprecision})"
        end
      end

      # SQLT_TIMESTAMP_TZ
      DATA_TYPE_MAP[188] = :timestamp_tz
      TYPE_PROC_MAP[188] = Proc.new do |p|
        fsprecision = p.fsprecision
        if fsprecision == 6
          "TIMESTAMP WITH TIME ZONE"
        else
          "TIMESTAMP(#{fsprecision}) WITH TIME ZONE"
        end
      end

      # SQLT_INTERVAL_YM
      DATA_TYPE_MAP[189] = :interval_ym
      TYPE_PROC_MAP[189] = Proc.new do |p|
        lfprecision = p.lfprecision
        if lfprecision == 2
          "INTERVAL YEAR TO MONTH"
        else
          "INTERVAL YEAR(#{lfprecision}) TO MONTH"
        end
      end

      # SQLT_INTERVAL_DS
      DATA_TYPE_MAP[190] = :interval_ds
      TYPE_PROC_MAP[190] = Proc.new do |p|
        lfprecision = p.lfprecision
        fsprecision = p.fsprecision
        if lfprecision == 2 && fsprecision == 6
          "INTERVAL DAY TO SECOND"
        else
          "INTERVAL DAY(#{lfprecision}) TO SECOND(#{fsprecision})"
        end
      end

      # SQLT_TIMESTAMP_LTZ
      DATA_TYPE_MAP[232] = :timestamp_ltz
      TYPE_PROC_MAP[232] = Proc.new do |p|
        fsprecision = p.fsprecision
        if fsprecision == 6
          "TIMESTAMP WITH LOCAL TIME ZONE"
        else
          "TIMESTAMP(#{fsprecision}) WITH LOCAL TIME ZONE"
        end
      end

      def inspect # :nodoc:
        "#<#{self.class.name}:(#{@obj_id}) #{@obj_schema}.#{@obj_name}>"
      end

      private

      def __data_type(p)
        DATA_TYPE_MAP[p.attrGet(OCI_ATTR_DATA_TYPE)] || p.attrGet(OCI_ATTR_DATA_TYPE)
      end

      def __type_string(p)
        type = TYPE_PROC_MAP[p.attrGet(OCI_ATTR_DATA_TYPE)] || "unknown(#{p.attrGet(OCI_ATTR_DATA_TYPE)})"
        type = type.call(self) if type.is_a? Proc
        if respond_to?(:nullable?) && !nullable?
          type + " NOT NULL"
        else
          type
        end
      end

      def initialize_table_or_view(param)
        @num_cols = param.attrGet(OCI_ATTR_NUM_COLS)
        @obj_id = param.attrGet(OCI_ATTR_OBJ_ID)
        @obj_name = param.attrGet(OCI_ATTR_OBJ_NAME)
        @obj_schema = param.attrGet(OCI_ATTR_OBJ_SCHEMA)
        colparam = param.attrGet(OCI_ATTR_LIST_COLUMNS)
        @columns = []
        1.upto @num_cols do |i|
          @columns << OCI8::Metadata::Column.new(colparam.paramGet(i))
        end
      end
    end

    class Table < Base
      attr_reader :num_cols
      attr_reader :obj_name
      attr_reader :obj_schema
      attr_reader :columns

      def initialize(param)
        initialize_table_or_view(param)
      end
    end

    class View < Base
      attr_reader :num_cols
      attr_reader :obj_name
      attr_reader :obj_schema
      attr_reader :columns

      def initialize(param)
        initialize_table_or_view(param)
      end
    end

    class Column < Base
      attr_reader :name
      attr_reader :type_string
      attr_reader :data_type
      attr_reader :charset_form
      def nullable?; @nullable; end

      # string data type
      def char_used?; @char_used; end if defined? OCI_ATTR_CHAR_USED
      attr_reader :char_size if defined? OCI_ATTR_CHAR_SIZE
      attr_reader :data_size
      attr_reader :charset_id

      # number data type
      attr_reader :precision
      attr_reader :scale

      # interval
      if defined? OCI_ATTR_FSPRECISION and defined? OCI_ATTR_LFPRECISION
        # Oracle 8i or upper has OCI_ATTR_FSPRECISION and OCI_ATTR_LFPRECISION
        @@is_fsprecision_available = true
      else
        @@is_fsprecision_available = false
      end
      attr_reader :fsprecision
      attr_reader :lfprecision

      def initialize(param)
        @name = param.attrGet(OCI_ATTR_NAME)
        @data_type = __data_type(param)

        @data_size = param.attrGet(OCI_ATTR_DATA_SIZE)
        @char_used = param.attrGet(OCI_ATTR_CHAR_USED) if defined? OCI_ATTR_CHAR_USED
        @char_size = param.attrGet(OCI_ATTR_CHAR_SIZE) if defined? OCI_ATTR_CHAR_SIZE

        @precision = param.attrGet(OCI_ATTR_PRECISION)
        @scale = param.attrGet(OCI_ATTR_SCALE)
        @nullable = param.attrGet(OCI_ATTR_IS_NULL)
        @charset_id = param.attrGet(OCI_ATTR_CHARSET_ID)
        @charset_form = case param.attrGet(OCI_ATTR_CHARSET_FORM)
                        when 0: nil
                        when 1; :implicit
                        when 2; :nchar
                        when 3; :explicit
                        when 4; :flexible
                        when 5; :lit_null
                        else raise "unknown charset_form #{param.attrGet(OCI_ATTR_CHARSET_FORM)}"
                        end

        @fsprecision = nil
        @lfprecision = nil
        if @@is_fsprecision_available
          begin
            @fsprecision = param.attrGet(OCI_ATTR_FSPRECISION)
            @lfprecision = param.attrGet(OCI_ATTR_LFPRECISION)
          rescue OCIError
            raise if $!.code != 24316 # ORA-24316: illegal handle type
            # Oracle 8i could not use OCI_ATTR_FSPRECISION and
            # OCI_ATTR_LFPRECISION even though it defines these
            # constants in oci.h.
            @@is_fsprecision_available = false
          end
        end

        @type_string = __type_string(param)
      end

      def to_s
        %Q{"#{@name}" #{@type_string}}
      end

      def inspect # :nodoc:
        "#<#{self.class.name}: #{@name} #{@type_string}>"
      end
    end
  end
end
