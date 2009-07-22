/*
  oci8.h - part of ruby-oci8

  Copyright (C) 2002-2006 KUBO Takehiro <kubo@jiubao.org>
*/
#ifndef _RUBY_OCI_H_
#define _RUBY_OCI_H_ 1

#include "ruby.h"
#include "rubyio.h"
#include "intern.h"

#ifndef rb_pid_t
#ifdef WIN32
#define rb_pid_t int
#else
#define rb_pid_t pid_t
#endif
#endif

#include <stdio.h>
#include <stdlib.h>
#ifdef __cplusplus
extern "C" {
#endif
#include <oci.h>
#ifdef __cplusplus
}
#endif
#include "extconf.h"

#ifdef StringValue
/* ruby 1.8 or later */
#define RBOCI_NORETURN(x) NORETURN(x)
#else
/* ruby 1.6 */
#define RBOCI_NORETURN(x) x NORETURN
#define rb_cstr_to_dbl(p, ignore) strtod((p), 0)
#endif

#ifndef RSTRING_PTR
#define RSTRING_PTR(obj) RSTRING(obj)->ptr
#endif
#ifndef RSTRING_LEN
#define RSTRING_LEN(obj) RSTRING(obj)->len
#endif

#ifndef RARRAY_PTR
#define RARRAY_PTR(obj) RARRAY(obj)->ptr
#endif
#ifndef RARRAY_LEN
#define RARRAY_LEN(obj) RARRAY(obj)->len
#endif

#ifndef HAVE_TYPE_ORATEXT
typedef unsigned char oratext;
#endif

#define IS_OCI_ERROR(v) (((v) != OCI_SUCCESS) && ((v) != OCI_SUCCESS_WITH_INFO))

#if defined(__GNUC__) && ((__GNUC__ > 3) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 1))
/* gcc version >= 3.1 */
#define ALWAYS_INLINE inline __attribute__((always_inline))
#endif
#ifdef _MSC_VER
/* microsoft c */
#define ALWAYS_INLINE __forceinline
#endif

#ifdef ALWAYS_INLINE
/*
 * I don't like cast because it can suppress warnings but may hide bugs.
 * These macros make warnings when the source type is invalid.
 */
#define TO_ORATEXT to_oratext
#define TO_CHARPTR to_charptr
static ALWAYS_INLINE OraText *to_oratext(char *c)
{
  return (OraText*)c;
}
static ALWAYS_INLINE char *to_charptr(OraText *c)
{
  return (char*)c;
}
#else
/* if not gcc, use normal cast. */
#define TO_ORATEXT(c) ((OraText*)(c))
#define TO_CHARPTR(c) ((char*)(c))
#endif
#define RSTRING_ORATEXT(obj) TO_ORATEXT(RSTRING_PTR(obj))

enum oci8_bind_type {
  BIND_STRING,
  BIND_FIXNUM,
  BIND_INTEGER_VIA_ORA_NUMBER,
  BIND_TIME_VIA_ORA_DATE,
  BIND_FLOAT,
  BIND_BINARY_DOUBLE,
  BIND_ORA_DATE,
  BIND_ORA_NUMBER,
  BIND_HANDLE
};

/* OraDate - Internal format of DATE */
struct ora_date {
  unsigned char century;
  unsigned char year;
  unsigned char month;
  unsigned char day;
  unsigned char hour;
  unsigned char minute;
  unsigned char second;
};
typedef struct ora_date ora_date_t;

/* Member of ora_vnumber_t and ora_bind_handle_t - Internal format of NUMBER */
struct ora_number {
  unsigned char exponent;
  unsigned char mantissa[20];
};
typedef struct ora_number ora_number_t;

/* OraNumber - Internal format of VARNUM */
struct ora_vnumber {
  unsigned char size;
  struct ora_number num;
};
typedef struct ora_vnumber ora_vnumber_t;

/* OCIEnv, OCISvcCtx, OCIServer, OCISession, OCIStmt, OCIDescribe, OCIParam */
struct oci8_handle {
  ub4 type;
  dvoid *hp;
  OCIError *errhp;
  VALUE self;
  struct oci8_handle *parent;
  size_t size;
  struct oci8_handle **children;
  /* End of common part */
  union {
    struct {
      char is_implicit;
    } param;
#ifndef OCI8_USE_CALLBACK_LOB_READ
    struct {
      int char_width;
    } lob_locator;
#endif
    struct {
      rb_pid_t pid;
    } svcctx;
  } u;
};
typedef struct oci8_handle oci8_handle_t;

/* OCIBind, OCIDefine */
struct oci8_bind_handle {
  ub4 type;
  dvoid *hp;
  OCIError *errhp;
  VALUE self;
  struct oci8_handle *parent;
  size_t size;
  struct oci8_handle **children;
  /* End of common part */
  enum oci8_bind_type bind_type;
  sb2 ind;
  ub2 rlen;
  sb4 value_sz; /* sizeof value */
  union {
    struct {
      sb4 len;
      char buf[1];
    } str;
    long lng;
    double dbl;
    ora_date_t od;
    ora_number_t on;
    struct {
      void *hp;
      VALUE v;
      VALUE klass;
    } handle;
  } value;
};
typedef struct oci8_bind_handle oci8_bind_handle_t;

#define Get_Handle(obj, hp) do { \
  Data_Get_Struct(obj, oci8_handle_t, hp); \
} while (0);

#define Check_Handle(obj, name, hp) do {\
  if (!rb_obj_is_instance_of(obj, c##name)) { \
    rb_raise(rb_eTypeError, "invalid argument %s (expect " #name ")", rb_class2name(CLASS_OF(obj))); \
  } \
  Data_Get_Struct(obj, oci8_handle_t, hp); \
} while (0)

struct oci8_string {
  OraText *ptr;
  ub4 len;
};
typedef struct oci8_string oci8_string_t;

#define Get_String(obj, s) do { \
  if (!NIL_P(obj)) { \
    Check_Type(obj, T_STRING); \
    s.ptr = RSTRING_ORATEXT(obj); \
    s.len = RSTRING_LEN(obj); \
  } else { \
    s.ptr = NULL; \
    s.len = 0; \
  } \
} while (0)

#define Get_Int_With_Default(argc, pos, vval, cval, def) do { \
  if (argc >= pos) { \
    Check_Type(vval, T_FIXNUM); \
    cval = FIX2INT(vval); \
  } else { \
    cval = def; \
  } \
} while (0)

#define ATTR_FOR_HNDL 1
#define ATTR_FOR_DESC 2
#define ATTR_FOR_BOTH (ATTR_FOR_HNDL | ATTR_FOR_DESC)
struct oci8_attr {
  const char *name;
  ub4 attr;
  char attr_type;
  VALUE (*get)(oci8_handle_t *hp, ub4 attr);
  void (*set)(oci8_handle_t *hp, ub4 attr, VALUE value);
};
typedef struct oci8_attr oci8_attr_t;

/* Handle */
extern VALUE cOCIHandle;
extern VALUE cOCIEnv;
extern VALUE cOCISvcCtx;
extern VALUE cOCIServer;
extern VALUE cOCISession;
extern VALUE cOCIStmt;
extern VALUE cOCIDefine;
extern VALUE cOCIBind;
extern VALUE cOCIDescribe;

/* Descriptor */
extern VALUE cOCIDescriptor;
extern VALUE cOCILobLocator;
extern VALUE cOCIFileLocator;
extern VALUE cOCIParam;
extern VALUE cOCIRowid;

/* Exception */
extern VALUE eOCIException;
extern VALUE eOCINoData;
extern VALUE eOCIError;
extern VALUE eOCIInvalidHandle;
extern VALUE eOCINeedData;
extern VALUE eOCIStillExecuting;
extern VALUE eOCIContinue;
extern VALUE eOCISuccessWithInfo;

/* oracle specific type */
extern VALUE cOraDate;
extern VALUE cOraNumber;

/* const.c */
void  Init_oci8_const(void);
extern ID oci8_id_code;
extern ID oci8_id_define_array;
extern ID oci8_id_bind_hash;
extern ID oci8_id_message;
extern ID oci8_id_new;
extern ID oci8_id_parse_error_offset;
extern ID oci8_id_server;
extern ID oci8_id_session;
extern ID oci8_id_sql;

/* handle.c */
void  Init_oci8_handle(void);
VALUE oci8_handle_free(VALUE self);
void oci8_handle_cleanup(oci8_handle_t *);
VALUE oci8_s_new(VALUE self);
oci8_handle_t *oci8_make_handle(ub4 type, dvoid *hp, OCIError *errhp, oci8_handle_t *chp, sb4 value_sz);
void oci8_link(oci8_handle_t *parent, oci8_handle_t *child);
void oci8_unlink(oci8_handle_t *self);

/* env.c */
void Init_oci8_env(void);

/* error.c */
void Init_oci8_error(void);
#define oci8_raise(errhp, status, stmthp) oci8_do_raise((errhp), (status), (stmthp), __FILE__, __LINE__)
#define oci8_env_raise(envhp, status) oci8_do_env_raise((envhp), (status), __FILE__, __LINE__)
RBOCI_NORETURN(void oci8_do_raise(OCIError *, sword status, OCIStmt *, const char *file, int line));
RBOCI_NORETURN(void oci8_do_env_raise(OCIEnv *, sword status, const char *file, int line));

/* svcctx.c */
void Init_oci8_svcctx(void);

/* server.c */
void Init_oci8_server(void);
VALUE oci8_server_version(VALUE self);
#ifdef HAVE_OCISERVERRELEASE
VALUE oci8_server_release(VALUE self);
#endif
VALUE oci8_break(VALUE self);
VALUE oci8_reset(VALUE self);

/* session.c */
void Init_oci8_session(void);

/* stmt.c */
void Init_oci8_stmt(void);

/* bind.c */
void Init_oci8_bind(void);
void oci8_set_value(oci8_bind_handle_t *, VALUE);
VALUE oci8_get_value(oci8_bind_handle_t *);

/* define.c */
void Init_oci8_define(void);

/* describe.c */
void Init_oci8_describe(void);

/* descriptor.c */
void Init_oci8_descriptor(void);
VALUE oci8_param_get(VALUE self, VALUE pos);

/* param.c */
void Init_oci8_param(void);

/* lob.c */
void Init_oci8_lob(void);

/* oradate.c */
void Init_ora_date(void);
void oci8_set_ora_date(ora_date_t *, int year, int month, int day, int hour, int minute, int second);
void oci8_get_ora_date(ora_date_t *, int *year, int *month, int *day, int *hour, int *minute, int *second);

/* oranumber.c */
#define ORA_NUMBER_BUF_SIZE (128 /* max scale */ + 38 /* max precision */ + 1 /* sign */ + 1 /* comma */ + 1 /* nul */)
void Init_ora_number(void);
void ora_number_to_str(unsigned char *buf, size_t *lenp, ora_number_t *on, unsigned char size);

/* ocinumber.c */
int set_oci_vnumber(ora_vnumber_t *result, VALUE num, OCIError *errhp);

/* attr.c */
void Init_oci8_attr(void);
VALUE oci8_attr_get(VALUE self, VALUE vtype);
VALUE oci8_attr_set(VALUE self, VALUE vtype, VALUE vvalue);
extern oci8_attr_t oci8_attr_list[];
extern size_t oci8_attr_size;

#define _D_ fprintf(stderr, "%s:%d - %s\n", __FILE__, __LINE__, __FUNCTION__)
#endif
