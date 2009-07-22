#include "oci8.h"

static VALUE sym_file_readonly;

#ifndef OCI8_USE_CALLBACK_LOB_READ
static VALUE oci8_lob_set_char_width(VALUE self, VALUE vsize)
{
  oci8_handle_t *h;
  int size;

  Get_Handle(self, h); /* 0 */
  size = NUM2INT(vsize); /* 1 */

  if (size <= 0)
    rb_raise(rb_eArgError, "size must be more than one.");
  h->u.lob_locator.char_width = size;
  return vsize;
}
#endif

static VALUE oci8_lob_is_initialized_p(VALUE self, VALUE venv)
{
  oci8_handle_t *h;
  oci8_handle_t *envh;
  boolean is_initialized;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(venv, OCIEnv, envh); /* 1 */

  rv = OCILobLocatorIsInit(envh->hp, h->errhp, h->hp, &is_initialized);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return is_initialized ? Qtrue : Qfalse;
}


/*
=begin
--- OCILobLocator#GetLength()
     get the length of LOB.
     counts by bytes for BLOB, by charactors for CLOB.
=end
 */
static VALUE oci8_lob_get_length(VALUE self, VALUE vsvc)
{
  oci8_handle_t *h;
  oci8_handle_t *svch;
  ub4 len;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */

  rv = OCILobGetLength(svch->hp, h->errhp, h->hp, &len);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return UINT2NUM(len);
}

#ifdef HAVE_OCILOBGETCHUNKSIZE
static VALUE oci8_lob_get_chunk_size(VALUE self, VALUE vsvc)
{
  oci8_handle_t *h;
  oci8_handle_t *svch;
  ub4 len;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */

  rv = OCILobGetChunkSize(svch->hp, h->errhp, h->hp, &len);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return UINT2NUM(len);
}
#endif

#ifdef OCI8_USE_CALLBACK_LOB_READ
static sb4 oci8_callback_lob_read(dvoid *ctxp, CONST dvoid *bufp, ub4 len, ub1 piece)
{
  VALUE v = *((VALUE *)ctxp);

  if (v == Qnil)
    v = rb_str_new(bufp, len);
  else
    v = rb_str_cat(v, bufp, len);

  *((VALUE *)ctxp) = v;
  return OCI_CONTINUE;
}
#endif

static VALUE oci8_lob_read(int argc, VALUE *argv, VALUE self)
{
  VALUE vsvc, voffset, vamt, vcsid, vcsfrm;
  oci8_handle_t *h;
  oci8_handle_t *svch;
  ub4 offset;
  ub2 csid;
  ub1 csfrm;
  ub4 amt;
  sword rv;
  char buf[8192]; /* 8192 is chunk size in a platform. */
#ifndef OCI8_USE_CALLBACK_LOB_READ
  size_t buf_size_in_char;
#endif
  VALUE v = Qnil;

  rb_scan_args(argc, argv, "32", &vsvc, &voffset, &vamt, &vcsid, &vcsfrm);
  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */
  offset = NUM2UINT(voffset); /* 2 */
  amt = NUM2UINT(vamt); /* 3 */
  csid = NIL_P(vcsid) ? 0 : NUM2INT(vcsid); /* 4 */
  csfrm = NIL_P(vcsfrm) ? SQLCS_IMPLICIT : NUM2INT(vcsfrm); /* 5 */

#ifdef OCI8_USE_CALLBACK_LOB_READ
  /* This raises ORA-24812, when the size of readed data is two or
   * three times longer than the size of buf. I couldn't fix it. Thus
   * I use polling way instead of callback method.
   */
  rv = OCILobRead(svch->hp, h->errhp, h->hp, &amt, offset, buf, sizeof(buf), &v, oci8_callback_lob_read, csid, csfrm);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
#else
  /* Disadvantage of polling way in contrast with callback method is
   * that it sets 'amt' the number of characters readed, when charset
   * is fixed size. For single byte charset or variable size charset,
   * it cause no problem because the unit of 'amt' is byte. But for
   * fixed size multibyte charset, how can I know the size of a
   * character from system? Therefore who want to use fixed size
   * multibyte charset must set the size explicitly.
   *
   * Umm, if I could use callback method, I have no need to care about
   * it.
   */
  buf_size_in_char = sizeof(buf) / h->u.lob_locator.char_width;
  do {
    /* initialize buf in zeros everytime to check a nul characters. */
    memset(buf, 0, sizeof(buf));
    rv = OCILobRead(svch->hp, h->errhp, h->hp, &amt, offset, buf, sizeof(buf), NULL, NULL, csid, csfrm);
    if (rv != OCI_SUCCESS && rv != OCI_NEED_DATA)
      oci8_raise(h->errhp, rv, NULL);

    /* Workaround when using Oracle 10.2.0.4 or 11.1.0.6 client and
     * variable-length character set (e.g. AL32UTF8).
     *
     * When the above mentioned condition, amt may be shorter. So
     * amt is increaded until a nul character to know the actually
     * read size.
     */
    while (amt < sizeof(buf) && buf[amt] != '\0') {
      amt++;
    }
    if (amt == 0)
      break;
    /* for fixed size charset, amt is the number of characters stored in buf. */
    if (amt > buf_size_in_char)
      rb_raise(eOCIException, "Too large buffer fetched or you set too large size of a character.");
    amt *= h->u.lob_locator.char_width;
    if (v == Qnil)
      v = rb_str_new(buf, amt);
    else
      v = rb_str_cat(v, buf, amt);
  } while (rv == OCI_NEED_DATA);
#endif
  return v;
}

static VALUE oci8_lob_write(int argc, VALUE *argv, VALUE self)
{
  VALUE vsvc, voffset, vbuf, vcsid, vcsfrm;
  oci8_handle_t *h;
  oci8_handle_t *svch;
  oci8_string_t buf;
  ub4 offset;
  ub2 csid;
  ub1 csfrm;
  ub4 amt;
  sword rv;

  rb_scan_args(argc, argv, "32", &vsvc, &voffset, &vbuf, &vcsid, &vcsfrm);
  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */
  offset = NUM2UINT(voffset); /* 2 */
  Get_String(vbuf, buf); /* 3 */
  csid = NIL_P(vcsid) ? 0 : NUM2INT(vcsid); /* 4 */
  csfrm = NIL_P(vcsfrm) ? SQLCS_IMPLICIT : NUM2INT(vcsfrm); /* 5 */

  amt = buf.len;
  rv = OCILobWrite(svch->hp, h->errhp, h->hp, &amt, offset, buf.ptr, buf.len, OCI_ONE_PIECE, NULL, NULL, csid, csfrm);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return INT2FIX(amt);
}

static VALUE oci8_lob_trim(VALUE self, VALUE vsvc, VALUE len)
{
  oci8_handle_t *h;
  oci8_handle_t *svch;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */

  rv = OCILobTrim(svch->hp, h->errhp, h->hp, NUM2INT(len));
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return self;
}

static VALUE oci8_lob_clone(VALUE self, VALUE vsvc)
{
  oci8_handle_t *h;
  oci8_handle_t *svch;
  oci8_handle_t *envh;
  oci8_handle_t *newh;
  OCILobLocator *hp;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */

  /* get environment handle */
  for (envh = h; envh->type != OCI_HTYPE_ENV; envh = envh->parent);
  rv = OCIDescriptorAlloc(envh->hp, (void *)&hp, h->type, 0, NULL);
  if (rv != OCI_SUCCESS) {
    oci8_env_raise(envh->hp, rv);
  }
#ifdef HAVE_OCILOBLOCATORASSIGN
  /* Oracle 8.1 or upper */
  rv = OCILobLocatorAssign(svch->hp, h->errhp, h->hp, &hp);
#else
  /* Oracle 8.0 */
  rv = OCILobAssign(envh->hp, h->errhp, h->hp, &hp);
#endif
  if (rv != OCI_SUCCESS) {
    OCIDescriptorFree(hp, h->type);
    oci8_raise(h->errhp, rv, NULL);
  }
  newh = oci8_make_handle(h->type, hp, h->errhp, h->parent, 0);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return newh->self;
}

#ifdef HAVE_OCILOBOPEN
static VALUE oci8_lob_open(int argc, VALUE *argv, VALUE self)
{
  VALUE vsvc;
  VALUE vmode = Qnil;
  oci8_handle_t *h;
  oci8_handle_t *svch;
  ub1 mode;
  sword rv;

  rb_scan_args(argc, argv, "11", &vsvc, &vmode);
  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */
  if (vmode == Qnil)
    mode = OCI_DEFAULT;
  else if (vmode == sym_file_readonly)
    mode = OCI_FILE_READONLY;
  else
    rb_raise(rb_eArgError, "expect nil or :file_readonly");
  rv = OCILobOpen(svch->hp, h->errhp, h->hp, mode);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return self;
}
#endif

#ifdef HAVE_OCILOBCLOSE
static VALUE oci8_lob_close(VALUE self, VALUE vsvc)
{
  oci8_handle_t *h;
  oci8_handle_t *svch;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */
  
  rv = OCILobClose(svch->hp, h->errhp, h->hp);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return self;
}
#endif

static VALUE oci8_lobfile_name(VALUE self, VALUE venv)
{
  oci8_handle_t *h;
  oci8_handle_t *envh;
  char dir_alias[31];
  ub2 d_length = sizeof(dir_alias);
  char filename[256];
  ub2 f_length = sizeof(filename);
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(venv, OCIEnv, envh); /* 1 */

  rv = OCILobFileGetName(envh->hp, h->errhp, h->hp, (OraText*)dir_alias, &d_length, (OraText*)filename, &f_length);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return rb_ary_new3(2, rb_str_new(dir_alias, d_length), rb_str_new(filename, f_length));
}

static VALUE oci8_lobfile_set_name(VALUE self, VALUE venv, VALUE vdir, VALUE vfile)
{
  oci8_handle_t *h;
  oci8_handle_t *envh;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(venv, OCIEnv, envh); /* 1 */
  StringValue(vdir); /* 2 */
  StringValue(vfile); /* 3 */

  rv = OCILobFileSetName(envh->hp, h->errhp, (OCILobLocator **)&h->hp,
			 RSTRING_ORATEXT(vdir), RSTRING_LEN(vdir),
			 RSTRING_ORATEXT(vfile), RSTRING_LEN(vfile));
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return self;
}

static VALUE oci8_lobfile_exist_p(VALUE self, VALUE vsvc)
{
  oci8_handle_t *h;
  oci8_handle_t *svch;
  boolean flag;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */

  rv = OCILobFileExists(svch->hp, h->errhp, h->hp, &flag);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return flag ? Qtrue : Qfalse;
}

static VALUE oci8_lob_create_temporary(VALUE self, VALUE vsvc, VALUE vcsid, VALUE vcsfrm, VALUE vlobtype, VALUE vcache, VALUE vduration)
{
#ifdef HAVE_OCILOBCREATETEMPORARY
  oci8_handle_t *h;
  oci8_handle_t *svch;
  ub2 csid;
  ub1 csfrm;
  ub1 lobtype;
  boolean cache;
  OCIDuration duration;
  sword rv;

  Get_Handle(self, h); /* 0 */
  Check_Handle(vsvc, OCISvcCtx, svch); /* 1 */
  csid = NIL_P(vcsid) ? 0 : NUM2INT(vcsid); /* 2 */
  csfrm = NIL_P(vcsfrm) ? SQLCS_IMPLICIT : NUM2INT(vcsfrm); /* 3 */
  lobtype = NUM2INT(vlobtype); /* 4 */
  cache = RTEST(vcache) ? TRUE : FALSE; /* 5 */
  duration = NIL_P(vduration) ? OCI_DURATION_SESSION : NUM2INT(vduration); /* 6 */

  rv = OCILobCreateTemporary(svch->hp, h->errhp, h->hp, csid, csfrm, lobtype, cache, duration);
  if (rv != OCI_SUCCESS)
    oci8_raise(h->errhp, rv, NULL);
  return self;
#else
  rb_notimplement();
#endif
}

void Init_oci8_lob(void)
{
  sym_file_readonly = ID2SYM(rb_intern("file_readonly"));
#ifndef OCI8_USE_CALLBACK_LOB_READ
  rb_define_method(cOCILobLocator, "char_width=", oci8_lob_set_char_width, 1);
#endif
  rb_define_method(cOCILobLocator, "is_initialized?", oci8_lob_is_initialized_p, 1);
  rb_define_method(cOCILobLocator, "getLength", oci8_lob_get_length, 1);
#ifdef HAVE_OCILOBGETCHUNKSIZE
  rb_define_method(cOCILobLocator, "getChunkSize", oci8_lob_get_chunk_size, 1);
#endif
  rb_define_method(cOCILobLocator, "read", oci8_lob_read, -1);
  rb_define_method(cOCILobLocator, "write", oci8_lob_write, -1);
  rb_define_method(cOCILobLocator, "trim", oci8_lob_trim, 2);
  rb_define_method(cOCILobLocator, "clone", oci8_lob_clone, 1);
#ifdef HAVE_OCILOBOPEN
  rb_define_method(cOCILobLocator, "open", oci8_lob_open, -1);
#endif
#ifdef HAVE_OCILOBCLOSE
  rb_define_method(cOCILobLocator, "close", oci8_lob_close, 1);
#endif
  rb_define_method(cOCIFileLocator, "name", oci8_lobfile_name, 1);
  rb_define_method(cOCIFileLocator, "set_name", oci8_lobfile_set_name, 3);
  rb_define_method(cOCIFileLocator, "exists?", oci8_lobfile_exist_p, 1);
  rb_define_method(cOCILobLocator, "create_temporary", oci8_lob_create_temporary, 6);
}
