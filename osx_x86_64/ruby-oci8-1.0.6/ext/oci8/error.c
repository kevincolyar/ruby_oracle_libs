/*
  error.c - part of ruby-oci8

  Copyright (C) 2002 KUBO Takehiro <kubo@jiubao.org>

=begin
== OCIError
=end
*/
#include "oci8.h"

static ID oci8_id_caller;
static ID oci8_id_set_backtrace;

RBOCI_NORETURN(static void oci8_raise2(dvoid *errhp, sword status, ub4 type, OCIStmt *stmthp, const char *file, int line));

static void oci8_raise2(dvoid *errhp, sword status, ub4 type, OCIStmt *stmthp, const char *file, int line)
{
  VALUE vcodes = Qnil;
  VALUE vmessages = Qnil;
  VALUE exc;
  char errmsg[1024];
  sb4 errcode;
  ub4 recodeno;
  VALUE msg;
#ifdef OCI_ATTR_PARSE_ERROR_OFFSET
  VALUE vparse_error_offset = Qnil;
#endif
#ifdef OCI_ATTR_STATEMENT
  VALUE vsql = Qnil;
#endif
  int i;
  int rv;
  VALUE backtrace;
#if defined(_WIN32) || defined(WIN32)
  char *p = strrchr(file, '\\');
  if (p != NULL)
    file = p + 1;
#endif

  switch (status) {
  case OCI_ERROR:
  case OCI_SUCCESS_WITH_INFO:
    vcodes = rb_ary_new();
    vmessages = rb_ary_new();
    for (recodeno = 1;;recodeno++) {
      /* get error string */
      rv = OCIErrorGet(errhp, recodeno, NULL, &errcode, TO_ORATEXT(errmsg), sizeof(errmsg), type);
      if (rv != OCI_SUCCESS) {
        break;
      }
      /* chop error string */
      for (i = strlen(errmsg) - 1;i >= 0;i--) {
	if (errmsg[i] == '\n' || errmsg[i] == '\r') {
	  errmsg[i] = '\0';
	} else {
	  break;
	}
      }
      rb_ary_push(vcodes, INT2FIX(errcode));
      rb_ary_push(vmessages, rb_str_new2(errmsg));
    }
    if (RARRAY_LEN(vmessages) > 0) {
      msg = RARRAY_PTR(vmessages)[0];
    } else {
      msg = rb_str_new2("ERROR");
    }
    if (status == OCI_ERROR) {
      exc = eOCIError;
    } else {
      exc = eOCISuccessWithInfo;
    }
    break;
  case OCI_NO_DATA:
    exc = eOCINoData;
    msg = rb_str_new2("No Data");
    break;
  case OCI_INVALID_HANDLE:
    exc = eOCIInvalidHandle;
    msg = rb_str_new2("Invalid Handle");
    break;
  case OCI_NEED_DATA:
    exc = eOCINeedData;
    msg = rb_str_new2("Need Data");
    break;
  case OCI_STILL_EXECUTING:
    exc = eOCIStillExecuting;
    msg = rb_str_new2("Still Executing");
    break;
  case OCI_CONTINUE:
    exc = eOCIContinue;
    msg = rb_str_new2("Continue");
    break;
  default:
    sprintf(errmsg, "Unknown error (%d)", status);
    exc = rb_eStandardError;
    msg = rb_str_new2(errmsg);
  }
  exc = rb_funcall(exc, oci8_id_new, 1, msg);
  if (!NIL_P(vcodes)) {
    rb_ivar_set(exc, oci8_id_code, vcodes);
  }
  if (!NIL_P(vmessages)) {
    rb_ivar_set(exc, oci8_id_message, vmessages);
  }
#ifdef OCI_ATTR_PARSE_ERROR_OFFSET
  if (!NIL_P(vparse_error_offset)) {
    rb_ivar_set(exc, oci8_id_parse_error_offset, vparse_error_offset);
  }
#endif
#ifdef OCI_ATTR_STATEMENT
  if (!NIL_P(vsql)) {
    rb_ivar_set(exc, oci8_id_sql, vsql);
  }
#endif
  /*
   * make error line in C code.
   */
  backtrace = rb_funcall(rb_cObject, rb_intern("caller"), 0);
  sprintf(errmsg, "%s:%d:in oci8lib.so", file, line);
  rb_ary_unshift(backtrace, rb_str_new2(errmsg));
  rb_funcall(exc, rb_intern("set_backtrace"), 1, backtrace);
  rb_exc_raise(exc);
}

static VALUE oci8_error_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE msg;
  VALUE code;

  rb_scan_args(argc, argv, "02", &msg, &code);
  rb_call_super(argc > 1 ? 1 : argc, argv);
  if (!NIL_P(code)) {
    rb_ivar_set(self, oci8_id_code, rb_ary_new3(1, code));
  }
  return Qnil;
}


/*
=begin
--- OCIError#code()
=end
*/
static VALUE oci8_error_code(VALUE self)
{
  VALUE ary = rb_ivar_get(self, oci8_id_code);
  if (NIL_P(ary)) {
    return Qnil;
  }
  Check_Type(ary, T_ARRAY);
  if (RARRAY_LEN(ary) == 0) {
    return Qnil;
  }
  return RARRAY_PTR(ary)[0];
}

/*
=begin
--- OCIError#codes()
=end
*/
static VALUE oci8_error_code_array(VALUE self)
{
  return rb_ivar_get(self, oci8_id_code);
}

/*
=begin
--- OCIError#message()
=end
*/

/*
=begin
--- OCIError#messages()
=end
*/
static VALUE oci8_error_message_array(VALUE self)
{
  return rb_ivar_get(self, oci8_id_message);
}

#ifdef OCI_ATTR_PARSE_ERROR_OFFSET
/*
=begin
--- OCIError#parseErrorOffset()
=end
*/
static VALUE oci8_error_parse_error_offset(VALUE self)
{
  return rb_ivar_get(self, oci8_id_parse_error_offset);
}
#endif

#ifdef OCI_ATTR_STATEMENT
/*
=begin
--- OCIError#sql()
     (Oracle 8.1.6 or later)
=end
*/
static VALUE oci8_error_sql(VALUE self)
{
  return rb_ivar_get(self, oci8_id_sql);
}
#endif

void Init_oci8_error(void)
{
  oci8_id_caller = rb_intern("caller");
  oci8_id_set_backtrace = rb_intern("set_backtrace");

  rb_define_method(eOCIError, "initialize", oci8_error_initialize, -1);
  rb_define_method(eOCIError, "code", oci8_error_code, 0);
  rb_define_method(eOCIError, "codes", oci8_error_code_array, 0);
  rb_define_method(eOCIError, "messages", oci8_error_message_array, 0);
#ifdef OCI_ATTR_PARSE_ERROR_OFFSET
  rb_define_method(eOCIError, "parseErrorOffset", oci8_error_parse_error_offset, 0);
#endif
#ifdef OCI_ATTR_STATEMENT
  rb_define_method(eOCIError, "sql", oci8_error_sql, 0);
#endif
}

void oci8_do_raise(OCIError *errhp, sword status, OCIStmt *stmthp, const char *file, int line)
{
  oci8_raise2(errhp, status, OCI_HTYPE_ERROR, stmthp, file, line);
}

void oci8_do_env_raise(OCIEnv *envhp, sword status, const char *file, int line)
{
  oci8_raise2(envhp, status, OCI_HTYPE_ENV, NULL, file, line);
}
