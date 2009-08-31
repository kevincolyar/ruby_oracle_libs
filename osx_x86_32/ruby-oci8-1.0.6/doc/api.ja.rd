=begin
= Ruby/OCI8 ���API
[ ((<Home|URL:index.ja.html>)) ] [ ((<English|URL:api.en.html>)) | Japanese ]

Ruby/OCI8 ��2���ؤ� API ��ʬ����ޤ����ҤȤĤ�"����API"�ǡ��⤦��Ĥ�"
���API"�Ǥ��������ǤϾ��API�λ���ˡ����⤷�ޤ�������ϲ���API�˽�°
���륯�饹�Ǥ⡢���API ����Ѥ�����ɬ�פʥ��饹�Ϥ����ǲ��⤷�ޤ���

"���API"�� ruby �ǽ񤫤줿�饤�֥��ǡ�"����API"�ξ�˹��ۤ���Ƥ���
����ʣ���� OCI �ι�¤���ä��ơ��ʤ�٤�ñ��˻Ȥ���褦�ˤ��Ƥ����
��������Ū�����ӤǤϤ��� API ����Ѥ��Ƥ���������

"����API"�� C ����ǽ񤫤줿�饤�֥��Ǥ���OCI((-Oracle Call
Interface: ���饯��� C���쥤�󥿡��ե�����-))�Υϥ�ɥ�� ruby �Υ���
���ˡ�OCI �δؿ��� ruby �Υ᥽�åɤإޥåԥ󥰤��Ƥ���ޤ���ruby �� C
����θ�����ͤΰ㤤�ˤ�ꡢñ��ʥޥåԥ󥰤��Ǥ��ʤ��Ȥ���⤢��ޤ�
������ǽ�ʤ����긵�� API ���Ѥ��ʤ��褦�ˤ��Ƥ���ޤ���

�С������ 0.2 �Ǥ� C ����Ǥ�äƾ��API��ľ�ܽ�ľ��������API�Ϥʤ�
�ʤ�ͽ��Ǥ���

== �ܼ�
* ((<���饹����>))
  * ((<OCI8>))
  * ((<OCI8::Cursor>))
  * ((<OCI8::BLOB>))
  * ((<OCI�㳰���饹>))
* ((<�᥽�åɰ���>))
  * OCI8
    * ((<new|OCI8.new>))(userid, password, dbname = nil, privilege = nil)
    * ((<logoff|OCI8#logoff>))()
    * ((<exec|OCI8#exec>))(sql, *bindvars)
    * ((<parse|OCI8#parse>))(sql)
    * ((<commit|OCI8#commit>))()
    * ((<rollback|OCI8#rollback>))()
    * ((<autocommit?|OCI8#autocommit?>))
    * ((<autocommit|OCI8#autocommit>))
    * ((<autocommit=|OCI8#autocommit=>))
    * ((<non_blocking?|OCI8#non_blocking?>))
    * ((<non_blocking=|OCI8#non_blocking=>))
    * ((<break|OCI8#break>))()
  * OCI8::Cursor
    * ((<define|OCI8::Cursor#define>))(pos, type, length = nil)
    * ((<bind_param|OCI8::Cursor#bind_param>))(key, val, type = nil, length = nil)
    * ((<[]|OCI8::Cursor#[]>))(key)
    * ((<[]=|OCI8::Cursor#[]=>))(key, val)
    * ((<keys|OCI8::Cursor#keys>))()
    * ((<exec|OCI8::Cursor#exec>))(*bindvars)
    * ((<type|OCI8::Cursor#type>))
    * ((<row_count|OCI8::Cursor#row_count>))
    * ((<get_col_names|OCI8::Cursor#get_col_names>))
    * ((<getColNames|OCI8::Cursor#getColNames>))
    * ((<fetch|OCI8::Cursor#fetch>))()
    * ((<close|OCI8::Cursor#close>))()
    * ((<rowid|OCI8::Cursor#rowid>))
  * OCI8::BLOB
    * ((<available?|OCI8::BLOB#available?>))
    * ((<read|OCI8::BLOB#read>))(size = nil)
    * ((<write|OCI8::BLOB#write>))(data)
    * ((<size|OCI8::BLOB#size>))
    * ((<size=|OCI8::BLOB#size=>))(len)
    * ((<chunk_size|OCI8::BLOB#chunk_size>))
    * ((<truncate|OCI8::BLOB#truncate>))(len)
    * ((<pos|OCI8::BLOB#pos>))
    * ((<pos=|OCI8::BLOB#pos=>))(pos)
    * ((<tell|OCI8::BLOB#tell>))
    * ((<seek|OCI8::BLOB#seek>))(pos)
    * ((<rewind|OCI8::BLOB#rewind>))
    * ((<eof?|OCI8::BLOB#eof?>))
* ((<���>))
  * ((<"�֥�å���/��֥�å��󥰥⡼��">))
== ���饹����
���API��ɬ�ܤʥ��饹�ϡ�((<OCI8>)), ((<OCI8::Cursor>)), ((<OCI8::BLOB>)),
�����((<OCI�㳰���饹>))�Ǥ���

=== OCI8
���Υ��饹�Υ��󥹥��󥹤ϥǡ����١����ؤ���³���б����ޤ���JDBC ��
java.sql.Connection, Perl/DBI �� database handle: $dbh ���б����ޤ���

ñ��� SQL �μ¹Ԥʤ�С����Υ��饹�ΤߤǼ¹ԤǤ��ޤ���

=== OCI8::Cursor
���Υ��饹�Υ��󥹥��󥹤ϥ��饯����Ѹ�Ǥϥ���������б����ޤ���JDBC
�� java.sql.Statement, Perl/DBI �� statement handle: $sth ���б����ޤ���

���Υ��饹�Υ��󥹥��󥹤� new �ˤ���������ʤ��Ǥ���������ɬ��
((<OCI8#exec>)), ((<OCI8#parse>)) ��ͳ���������Ƥ���������

=== OCI8::BLOB
BLOB �ΥХ��ʥ�ǡ������ɤ߽񤭤���Ȥ��˻��Ѥ��륯�饹�Ǥ���
select ʸ�� BLOB ���Υ��������򤹤�Ȥ��Υ��饹�Υ��󥹥��󥹤���ư
Ū����������ޤ���

=== OCI�㳰���饹
���API��ɬ�פ��㳰���饹�γ��ؤϰʲ��Τ褦�ˤʤäƤ��ޤ���

* ((|OCIException|))
  * ((|OCIError|))
  * ((|OCIInvalidHandle|))
  * ((|OCIBreak|))

((|OCIException|))�� OCI �㳰����ݿƥ��饹�Ǥ���OCI ���㳰�򤹤٤���
­�������Ȥ��Ϥ��Υ��饹�� rescue �˻ȤäƤ���������

((|OCIError|))�ϥ��饯��Υ��顼�����ɤĤ����㳰���饹�Ǥ���
OCIError#message �ǥ�å�������ʸ�����OCIErrror#code �ǥ��顼������
������Ǥ��ޤ���

((|OCIInvalidHandle|))��̵���ʥϥ�ɥ���Ф�������Ԥʤä��Ȥ��˵���
���㳰�Ǥ���

((|OCIBreak|))��((<��֥�å��󥰥⡼��|"�֥�å���/��֥�å��󥰥⡼��">))
���̤Υ���åɤ�� OCI �ƽФ�������󥻥뤵�줿�Ȥ��˵������㳰�Ǥ���

== �᥽�åɰ���
=== OCI8
--- OCI8.new(userid, password, dbname = nil, privilege = nil)
     ((|userid|)), ((|password|)) �Ǥ�äƥ��饯�����³���ޤ���((|dbname|)) �� Net8 ��
     ��³ʸ����Ǥ���DBA ���¤�ɬ�פʾ��� ((|privilege|)) �� :SYSDBA �ޤ�
     �� :SYSOPER����ꤷ�ޤ���


     ��:
       # sqlplus scott/tiger@orcl.world
       conn = OCI8.new("scott", "tiger", "orcl.world")

     ��:
       # sqlplus 'sys/change_on_install as sysdba'
       conn = OCI8.new("sys", "change_on_install", nil, :SYSDBA)

--- OCI8#logoff()
     ���饯��Ȥ���³���ڤ�ޤ������ߥåȤ���Ƥʤ��ȥ�󥶥�������
     ����Хå�����ޤ���

     ��:
       conn = OCI8.new("scott", "tiger")
       ... do something ...
       conn.logoff

--- OCI8#exec(sql, *bindvars)
     sql ʸ��¹Ԥ��ޤ���sql ʸ�� SELECTʸ��INSERT/UPDATE/DELETEʸ��
     CREATE/ALTER/DROPʸ��PL/SQLʸ�����줾���������ͤμ��ब�ۤʤ�
     �ޤ���

     bindvars �������硢�Х�����ѿ��Ȥ��ƥХ���ɤ��Ƥ���¹Ԥ��ޤ���

     SELECT ʸ�ǥ֥�å����Ĥ��Ƥʤ���硢OCI8::Cursor �Υ��󥹥���
     ���֤��ޤ���

     ��:
       conn = OCI8.new('scott', 'tiger')
       cursor = conn.exec('SELECT * FROM emp')
       while r = cursor.fetch()
         puts r.join(',')
       end
       cursor.close
       conn.logoff

     SELECT ʸ�ǥ֥�å����Ĥ��Ƥ����硢���ƥ졼���Ȥ���ư��������
     �����Կ����֤�ޤ����֥�å��ˤϥե��å������ǡ���������Ǥ錄��
     �ޤ���NULL�ͤ� ruby ¦�Ǥ� nil �˥ޥåԥ󥰤��Ƥ���ޤ���


     ��:
       conn = OCI8.new('scott', 'tiger')
       num_rows = conn.exec('SELECT * FROM emp') do |r|
         puts r.join(',')
       end
       puts num_rows.to_s + ' rows were processed.'
       conn.logoff

     INSERT/UPDATE/DELETEʸ�ξ�硢���줾����������Կ����֤�ޤ���

     ��:
       conn = OCI8.new('scott', 'tiger')
       num_rows = conn.exec('UPDATE emp SET sal = sal * 1.1')
       puts num_rows.to_s + ' rows were updated.'
       conn.logoff

     CREATE/ALTER/DROPʸ�ξ�硢true ���֤�ޤ���

     ��:
       conn = OCI8.new('scott', 'tiger')
       conn.exec('CREATE TABLE test (col1 CHAR(6))')
       conn.logoff

     PL/SQLʸ�ξ�硢�¹Ը�ΥХ�����ѿ����ͤ�����Ȥʤä��֤�ޤ���

     ��:
       conn = OCI8.new('scott', 'tiger')
       conn.exec("BEGIN :str := TO_CHAR(:num, 'FM0999'); END;", 'ABCD', 123)
       # => ["0123", 123]
       conn.logoff

     �嵭����Ǥϡ�((|:str|)) �� ((|:num|)) �Ȥ���2�ĤΥХ�����ѿ���
     ����ޤ�������ͤȤ��Ƥ��줾��"��4���ͤ� ABCD ��ʸ����"��"�� 123
     �ο���"�����ꤵ��Ƥ��顢PL/SQLʸ���¹Ԥ��졢�¹Ը�ΥХ�����ѿ�
     ���ͤ�����Ȥ����֤äƤ��ޤ�������ν��֤ϥХ�����ѿ��ν��֤�Ʊ
     ���Ǥ���

--- OCI8#parse(sql)
     ����������������sql ʸ�¹Ԥν����򤷤ޤ���OCI8::Cursor �Υ���
     ���󥹤��֤�ޤ���

--- OCI8#commit()
     �ȥ�󥶥������򥳥ߥåȤ��ޤ���

     ��:
       conn = OCI8.new("scott", "tiger")
       conn.exec("UPDATE emp SET sal = sal * 1.1") # yahoo
       conn.commit
       conn.logoff

--- OCI8#rollback()
     �ȥ�󥶥����������Хå����ޤ���

     ��:
       conn = OCI8.new("scott", "tiger")
       conn.exec("UPDATE emp SET sal = sal * 0.9") # boos
       conn.rollback
       conn.logoff

--- OCI8#autocommit?
     autocommit �⡼�ɤξ��֤��֤��ޤ����ǥե���Ȥ� false �Ǥ�������
     �ͤ� true �ΤȤ���INSERT/UPDATE/DELETEʸ���¹Ԥ������˼�ưŪ��
     ���ߥåȤ���ޤ���

--- OCI8#autocommit
     ((<OCI8#autocommit?>))����̾�Ǥ���

--- OCI8#autocommit=
     autocommit �⡼�ɤξ��֤��ѹ����ޤ���true �� flase �����ꤷ�Ƥ���������

     ��:
       conn = OCI8.new("scott", "tiger")
       conn.autocommit = true
       ... do something ...
       conn.logoff

--- OCI8#non_blocking?
     �֥�å���/��֥�å��󥰥⡼�ɤξ��֤��֤��ޤ����ǥե���Ȥ�
     false���Ĥޤ�֥�å��󥰥⡼�ɤǤ���((<"�֥�å���/��֥�å��󥰥⡼��">))
     �򻲾Ȥ��Ƥ���������


--- OCI8#non_blocking=
     �֥�å���/��֥�å��󥰥⡼�ɤξ��֤��ѹ����ޤ���true ��
     flase �����ꤷ�Ƥ���������((<"�֥�å���/��֥�å��󥰥⡼��">))
     �򻲾Ȥ��Ƥ���������


--- OCI8#break()
     �¹����¾����åɤ� OCI �ƽФ��򥭥�󥻥뤷�ޤ������Υ᥽�åɤ�
     �¹Ԥ���ˤ���֥�å��󥰥⡼�ɤǤ���ɬ�פ�����ޤ���
     ((<"�֥�å���/��֥�å��󥰥⡼��">))�򻲾Ȥ��Ƥ���������

== OCI8::Cursor
--- OCI8::Cursor#define(pos, type, length = nil)

     fetch �Ǽ�������ǡ����η�������Ū�˻��ꤹ�롣parse �� exec �δ�
     �˼¹Ԥ��Ƥ���������pos �� 1 ��������ޤ���length �� type ��
     String ����ꤷ���Ȥ���ͭ���Ǥ���

     ��:
       cursor = conn.parse("SELECT ename, hiredate FROM emp")
       cursor.define(1, String, 20) # 1������ܤ� String �Ȥ��� fetch
       cursor.define(2, Time)       # 2������ܤ� Time �Ȥ��� fetch
       cursor.exec()

--- OCI8::Cursor#bind_param(key, val, type = nil, length = nil)
     ����Ū���ѿ���Х���ɤ��ޤ���

     key �����ͤξ��ϡ��Х�����ѿ��ΰ��֤ˤ�äƥХ���ɤ��ޤ�����
     �֤�1��������ޤ���key ��ʸ����ξ��ϡ��Х�����ѿ���̾���ˤ��
     �ƥХ���ɤ��ޤ���

     ��:
       cursor = conn.parse("SELECT * FROM emp WHERE ename = :ename")
       cursor.bind_param(1, 'SMITH') # bind by position
         ...or...
       cursor.bind_param(':ename', 'SMITH') # bind by name

     ���ͤ�Х���ɤ����硢Fixnum �� Float ���ȤäƤ���������Bignum
     �ϻ��ѤǤ��ޤ��󡣽���ͤ� NULL �ˤ�����ϡ�val �� nil �ˤ��ơ�
     type ��Fixnum �� Float �ˤ��Ƥ���������

     ��:
       cursor.bind_param(1, 1234) # bind as Fixnum, Initial value is 1234.
       cursor.bind_param(1, 1234.0) # bind as Float, Initial value is 1234.0.
       cursor.bind_param(1, nil, Fixnum) # bind as Fixnum, Initial value is NULL.
       cursor.bind_param(1, nil, Float) # bind as Float, Initial value is NULL.

     ʸ�����Х���ɤ����硢val �ˤ��ΤޤޥХ���ɤ���ʸ������ꤷ
     �Ƥ����������Х���ɤ����ϤȤ��ƻȤ����硢���Ϥ���Τ�ɬ�פ�
     Ĺ����ʸ������ꤹ�뤫��type �� String ����ꤷ����� length ���
     �ꤷ�Ƥ���������

     ��:
       cursor = conn.parse("BEGIN :out := :in || '_OUT'; END;")
       cursor.bind_param(':in', 'DATA') # bind as String with width 4.
       cursor.bind_param(':out', nil, String, 7) # bind as String with width 7.
       cursor.exec()
       p cursor[':out'] # => 'DATA_OU'
       # PL/SQL�֥�å���Ǥ� :out �� 8�Х��Ȥ�������7��ʸ���Ȥ��ƥХ����
       # ���Ƥ���Τǡ�7�Х����ܤ��ڤ�Ƥ���

     ʸ����� RAW ���Ȥ��ƥХ���ɤ������ɬ�� type �� OCI8::RAW ��
     ���ꤷ�Ƥ���������

     ��:
       cursor = conn.parse("INSERT INTO raw_table(raw_column) VALUE (:1)")
       cursor.bind_param(1, 'RAW_STRING', OCI8::RAW)
       cursor.exec()
       cursor.close()

--- OCI8::Cursor#[](key)
     �Х�����ѿ����ͤ���Ф��ޤ���

     ����Ū�˥Х���ɤ�����硢((<OCI8::Cursor#bind_param>))�ǻ��ꤷ��
     key �Ǥ�äƼ��Ф��ޤ������֤ˤ��Х���ɡ�̾���ˤ��Х����
     �����ߤ�����硢Ʊ�����Ǥ���ꤷ���Х������ˡ���б����� key ��
     �Ѥ��Ƥ���������

     ��:
       cursor = conn.parse("BEGIN :out := 'BAR'; END;")
       cursor.bind_param(':out', 'FOO') # bind by name
       p cursor[':out'] # => 'FOO'
       p cursor[1] # => nil
       cursor.exec()
       p cursor[':out'] # => 'BAR'
       p cursor[1] # => nil

     ��:
       cursor = conn.parse("BEGIN :out := 'BAR'; END;")
       cursor.bind_param(1, 'FOO') # bind by position
       p cursor[':out'] # => nil
       p cursor[1] # => 'FOO'
       cursor.exec()
       p cursor[':out'] # => nil
       p cursor[1] # => 'BAR'

     ((<OCI8#exec>))��((<OCI8::Cursor#exec>))����Ѥ��ƥХ���ɤ�����
     �硢�Х�����ѿ��ΰ��֤Ǥ�äƼ������ޤ���

     ��:
       cursor = conn.exec("BEGIN :out := 'BAR'; END;", 'FOO')
       # 1st bind variable is bound as String with width 3. Its initial value is 'FOO'
       # After execute, the value become 'BAR'.
       p cursor[1] # => 'BAR'

--- OCI8::Cursor#[]=(key, val)
     �Х�����ѿ����ͤ����ꤷ�ޤ���key �λ�����ˡ��
     ((<OCI8::Cursor#[]>))��Ʊ���Ǥ���((<OCI8::Cursor#bind_param>))�ǻ�
     �ꤷ�� val �����֤����������Ȥ����ޤ����̤��ͤ��֤������Ʋ��٤�
     ((<OCI8::Cursor#exec>))��¹Ԥ������Ȥ��˻��Ѥ��Ƥ���������

     �㣱:
       cursor = conn.parse("INSERT INTO test(col1) VALUES(:1)")
       cursor.bind_params(1, nil, String, 3)
       ['FOO', 'BAR', 'BAZ'].each do |key|
         cursor[1] = key
         cursor.exec
       end
       cursor.close()

     �㣲:
       ['FOO', 'BAR', 'BAZ'].each do |key|
         conn.exec("INSERT INTO test(col1) VALUES(:1)", key)
       end

     �㣱���㣲�Ϸ�̤�Ʊ���Ǥ������㣱�Τۤ�����٤����ʤ��ʤ�ޤ���

--- OCI8::Cursor#keys()
     �Х�����ѿ��� key ������ˤ����֤��ޤ���

--- OCI8::Cursor#exec(*bindvars)
     ��������˳����Ƥ�줿 SQL ��¹Ԥ��ޤ���SQL �� SELECTʸ��
     INSERT/UPDATE/DELETEʸ��CREATE/ALTER/DROPʸ��PL/SQLʸ�����줾���
     �������ͤμ��ब�ۤʤ�ޤ���


     SELECTʸ�ξ�硢select-list �ο����֤�ޤ���

     INSERT/UPDATE/DELETEʸ�ξ�硢���줾����������Կ����֤�ޤ���

     CREATE/ALTER/DROPʸ��PL/SQLʸ�ξ�硢true ���֤�ޤ���
     ((<OCI8#exec>))�Ǥ� PL/SQLʸ�ξ�硢�Х�����ѿ����ͤ�����Ȥʤä�
     �֤�ޤ��������Υ᥽�åɤǤ�ñ�� true ���֤�ޤ����Х�����ѿ���
     �ͤ�((<OCI8::Cursor#[]>))�Ǥ�ä�����Ū�˼������Ƥ���������

--- OCI8::Cursor#type
     SQLʸ�μ����������ޤ�������ͤϡ�
     * OCI8::STMT_SELECT
     * OCI8::STMT_UPDATE
     * OCI8::STMT_DELETE
     * OCI8::STMT_INSERT
     * OCI8::STMT_CREATE
     * OCI8::STMT_DROP
     * OCI8::STMT_ALTER
     * OCI8::STMT_BEGIN
     * OCI8::STMT_DECLARE
     �Τɤ줫�Ǥ���PL/SQLʸ�ξ��ϡ�OCI8::STMT_BEGIN ��
     OCI8::STMT_DECLARE �Ȥʤ�ޤ���

--- OCI8::Cursor#row_count
     ���������Կ����֤��ޤ���

--- OCI8::Cursor#get_col_names
     ����ꥹ�Ȥ�̾��������Ǽ������ޤ���SELECT ʸ�ˤΤ�ͭ���Ǥ���ɬ�� exec ������˻��Ѥ��Ƥ���������

--- OCI8::Cursor#getColNames
     ((<OCI8::Cursor#get_col_names>)) �ؤΥ����ꥢ���Ǥ���

--- OCI8::Cursor#fetch()
     SELECT ʸ�Τߤ�ͭ���Ǥ����ե��å������ǡ���������Ȥ����֤�ޤ���

     ��:
       conn = OCI8.new('scott', 'tiger')
       cursor = conn.exec('SELECT * FROM emp')
       while r = cursor.fetch()
         puts r.join(',')
       end
       cursor.close
       conn.logoff

--- OCI8::Cursor#close()
     ��������򥯥������ޤ���

--- OCI8::Cursor#rowid
     ���߼¹Ԥ��Ƥ���Ԥ� ROWID ��������ޤ���
     ����������줿�ͤϥХ�����ͤȤ��ƻ��ѤǤ��ޤ���
     �դ˸����ȡ��Х���ɤ�����Ū�ˤ������ѤǤ��ޤ���

== OCI8::BLOB
--- OCI8::BLOB#available?
     BLOB ��ͭ�����ɤ��������å����ޤ���
     BLOB ����Ѥ��뤿��ˤϺǽ�˶���BLOB����������ɬ�פ�����ޤ���

     ��:
       conn.exec("CREATE TABLE photo (name VARCHAR2(50), image BLOB)")
       conn.exec("INSERT INTO photo VALUES ('null-data', NULL)")
       conn.exec("INSERT INTO photo VALUES ('empty-data', EMPTY_BLOB())")
       conn.exec("SELECT name, image FROM photo") do |name, image|
         case name
         when 'null-data'
           puts "#{name} => #{image.available?.to_s}"
           # => false
         when 'empty-data'
           puts "#{name} => #{image.available?.to_s}"
           # => true
         end
       end

--- OCI8::BLOB#read(size = nil)
     BLOB ���ǡ������ɤ߹��ߤޤ���size �λ��꤬�ʤ����ϥǡ����κ�
     ��ޤ��ɤ߹��ߤޤ���

     �㣱: BLOB �Υ���󥯥���������ɤ߹��ߡ�
       conn.exec("SELECT name, image FROM photo") do |name, image|
         chunk_size = image.chunk_size
         File.open(name, 'w') do |f|
           until image.eof?
             f.write(image.read(chunk_size))
           end
         end
       end

     �㣲: �����ɤ߹��ߡ�
       conn.exec("SELECT name, image FROM photo") do |name, image|
         File.open(name, 'w') do |f|
           f.write(image.read)
         end
       end

--- OCI8::BLOB#write(data)
     BLOB �إǡ�����񤭹��ߤޤ���
     BLOB �˸������äƤ����ǡ�����Ĺ�����񤭹�����ǡ������Ĺ������
     ((<OCI8::BLOB#size=>)) ��Ĺ���κ������ԤäƤ���������

     �㣱: BLOB �Υ���󥯥�������˽񤭹���
       cursor = conn.parse("INSERT INTO photo VALUES(:name, EMPTY_BLOB())")
       Dir["*.png"].each do |fname|
         cursor.exec(fname)
       end
       conn.exec("SELECT name, image FROM photo") do |name, image|
         chunk_size = image.chunk_size
         File.open(name, 'r') do |f|
           until f.eof?
             image.write(f.read(chunk_size))
           end
           image.size = f.pos
         end
       end
       conn.commit

     �㣲: ���˽񤭹���
       conn.exec("SELECT name, image FROM photo") do |name, image|
         File.open(name, 'r') do |f|
           image.write(f.read)
           image.size = f.pos
         end
       end

--- OCI8::BLOB#size
     BLOB �Υǡ�����Ĺ�����֤��ޤ���

--- OCI8::BLOB#size=(len)
     BLOB �Υǡ�����Ĺ���� len �����ꤷ�ޤ���

--- OCI8::BLOB#chunk_size
     BLOB �Υ���󥯥��������֤��ޤ���

--- OCI8::BLOB#truncate(len)
     BLOB �Υǡ�����Ĺ���� len �����ꤷ�ޤ���

--- OCI8::BLOB#pos
     ����� read/write �γ��ϰ��֤��֤��ޤ���

--- OCI8::BLOB#pos=(pos)
     ����� read/write �γ��ϰ��֤����ꤷ�ޤ���

--- OCI8::BLOB#eof?
     BLOB �κǸ����ã�������ɤ������֤��ޤ���

--- OCI8::BLOB#tell
     ((<OCI8::BLOB#pos>)) ��Ʊ���Ǥ���

--- OCI8::BLOB#seek(pos)
     ((<OCI8::BLOB#pos=>)) ��Ʊ���Ǥ���

--- OCI8::BLOB#rewind
     ����� read/write �γ��ϰ��֤� 0 �����ꤷ�ޤ���

== ���
=== �֥�å���/��֥�å��󥰥⡼��
�ǥե���Ȥϥ֥�å��󥰥⡼�ɤˤʤäƤ��ޤ���((<OCI8#non_blocking=>))
�ǥ⡼�ɤ��ѹ��Ǥ��ޤ���

�֥�å��󥰥⡼�ɤξ�硢�Ť� OCI �θƽФ��򤷤Ƥ���ȡ�����åɤ�Ȥ�
�Ƥ��Ƥ� ruby ���Τ��֥�å�����ޤ�������ϡ�ruby �Υ���åɤϥͥ��ƥ�
�֥���åɤǤϤʤ�����Ǥ���

��֥�å��󥰥⡼�ɤξ�硢�Ť� OCI �θƽФ��Ǥ� ruby ���Τϥ֥�å�
����ޤ���OCI ��ƽФ��Ƥ��륹��åɤΤߤ��֥�å����ޤ������Τ���ꡢ
OCI �ƽФ�����λ���Ƥ��뤫�ɤ����ݡ���󥰤ˤ�äƥ����å����Ƥ���Τǡ�
�ġ��� OCI �ƽФ��������٤��ʤ�ޤ���

((<OCI8#break>)) ���Ѥ���ȡ��̤Υ���åɤ���Ť� OCI �ƽФ��򥭥�󥻥�Ǥ�
�ޤ�������󥻥뤵�줿����åɤǤ� ((|OCIBreak|)) �Ȥ����㳰��󤲤ޤ���

��֥�å��󥰥⡼�ɤ����»���: �̡��Υ���åɤ�Ʊ����³���Ф���Ʊ����
OCI �ƽФ���Ԥ�ʤ��Ǥ���������OCI �饤�֥��¦����֥�å��󥰥⡼��
�Ǥθ�ߤθƽФ����б����Ƥ��뤫�ɤ��������Ǥ������ޤ���ruby �Υ⥸�塼
��¦�Ǥ⡢((<OCI8#break>)) ��¹Ԥ����Ȥ��˥���󥻥뤹��OCI �ƽФ���
ʣ�������硢���ߤμ����Ǥ��б��Ǥ��ޤ���

=end
