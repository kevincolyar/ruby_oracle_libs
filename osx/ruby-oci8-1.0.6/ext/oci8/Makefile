
SHELL = /bin/sh

#### Start of system configuration section. ####

srcdir = /Users/kevincolyar/development/dcpud/dccn_universe/lib/third_party/osx/ruby-oci8-1.0.6/ext/oci8
topdir = /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/universal-darwin9.0
hdrdir = $(topdir)
VPATH = $(srcdir):$(topdir):$(hdrdir)
prefix = $(DESTDIR)/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr
exec_prefix = $(prefix)
sitedir = $(DESTDIR)/Library/Ruby/Site
rubylibdir = $(libdir)/ruby/$(ruby_version)
docdir = $(datarootdir)/doc/$(PACKAGE)
dvidir = $(docdir)
datarootdir = $(prefix)/share
archdir = $(rubylibdir)/$(arch)
sbindir = $(exec_prefix)/sbin
psdir = $(docdir)
localedir = $(datarootdir)/locale
htmldir = $(docdir)
datadir = $(datarootdir)
includedir = $(prefix)/include
infodir = $(DESTDIR)/usr/share/info
sysconfdir = $(prefix)/etc
mandir = $(DESTDIR)/usr/share/man
libdir = $(exec_prefix)/lib
sharedstatedir = $(prefix)/com
oldincludedir = $(DESTDIR)/usr/include
pdfdir = $(docdir)
sitearchdir = $(sitelibdir)/$(sitearch)
bindir = $(exec_prefix)/bin
localstatedir = $(prefix)/var
sitelibdir = $(sitedir)/$(ruby_version)
libexecdir = $(exec_prefix)/libexec

CC = gcc
LIBRUBY = $(LIBRUBY_SO)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)

RUBY_EXTCONF_H = extconf.h
CFLAGS   =  -fno-common -arch i386 -Os -pipe -fno-common -I/Library/Oracle/instantclient/10.2.0.4/sdk/include -Wall 
INCFLAGS = -I. -I. -I/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/universal-darwin9.0 -I/Users/kevincolyar/development/dcpud/dccn_universe/lib/third_party/osx/ruby-oci8-1.0.6/ext/oci8
DEFS     = 
CPPFLAGS = -DRUBY_EXTCONF_H=\"$(RUBY_EXTCONF_H)\"  
CXXFLAGS = $(CFLAGS) 
DLDFLAGS = -L. -arch i386  
LDSHARED = cc -arch i386 -pipe -bundle -undefined dynamic_lookup
AR = ar
EXEEXT = 

RUBY_INSTALL_NAME = ruby
RUBY_SO_NAME = ruby
arch = universal-darwin9.0
sitearch = universal-darwin9.0
ruby_version = 1.8
ruby = /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
RUBY = $(ruby)
RM = rm -f
MAKEDIRS = mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp

#### End of system configuration section. ####

preload = 

libpath = . $(libdir)
LIBPATH =  -L. -L$(libdir)
DEFFILE = 

CLEANFILES = mkmf.log
DISTCLEANFILES = 

extout = 
extout_prefix = 
target_prefix = 
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED)  -L/Library/Oracle/instantclient/10.2.0.4 -lclntsh  -lpthread -ldl -lm  
SRCS = oci8.c handle.c const.c env.c error.c svcctx.c server.c session.c stmt.c define.c bind.c describe.c descriptor.c param.c lob.c oradate.c oranumber.c ocinumber.c attr.c
OBJS = oci8.o handle.o const.o env.o error.o svcctx.o server.o session.o stmt.o define.o bind.o describe.o descriptor.o param.o lob.o oradate.o oranumber.o ocinumber.o attr.o
TARGET = oci8lib
DLLIB = $(TARGET).bundle
EXTSTATIC = 
STATIC_LIB = 

RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR    = $(sitelibdir)$(target_prefix)
RUBYARCHDIR   = $(sitearchdir)$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).bundle $(TARGET).il? $(TARGET).tds $(TARGET).map
CLEANOBJS     = *.o *.a *.s[ol] *.pdb *.exp *.bak

all:		$(DLLIB)
static:		$(STATIC_LIB)

clean:
		@-$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES)

distclean:	clean
		@-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		@-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)

realclean:	distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
	$(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
$(RUBYARCHDIR):
	$(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .cxx .cpp .C .o

.cc.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cxx.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cpp.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.C.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.c.o:
	$(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -c $<

$(DLLIB): $(OBJS)
	@-$(RM) $@
	$(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)



###
$(OBJS): $(RUBY_EXTCONF_H)

Makefile: extconf.rb oraconf.rb
	$(RUBY) extconf.rb
oci8.o: $(srcdir)/oci8.c $(srcdir)/oci8.h Makefile
handle.o: $(srcdir)/handle.c $(srcdir)/oci8.h Makefile
const.o: $(srcdir)/const.c $(srcdir)/oci8.h Makefile
env.o: $(srcdir)/env.c $(srcdir)/oci8.h Makefile
error.o: $(srcdir)/error.c $(srcdir)/oci8.h Makefile
svcctx.o: $(srcdir)/svcctx.c $(srcdir)/oci8.h Makefile
server.o: $(srcdir)/server.c $(srcdir)/oci8.h Makefile
session.o: $(srcdir)/session.c $(srcdir)/oci8.h Makefile
stmt.o: $(srcdir)/stmt.c $(srcdir)/oci8.h Makefile
define.o: $(srcdir)/define.c $(srcdir)/oci8.h Makefile
bind.o: $(srcdir)/bind.c $(srcdir)/oci8.h Makefile
describe.o: $(srcdir)/describe.c $(srcdir)/oci8.h Makefile
descriptor.o: $(srcdir)/descriptor.c $(srcdir)/oci8.h Makefile
param.o: $(srcdir)/param.c $(srcdir)/oci8.h Makefile
lob.o: $(srcdir)/lob.c $(srcdir)/oci8.h Makefile
oradate.o: $(srcdir)/oradate.c $(srcdir)/oci8.h Makefile
oranumber.o: $(srcdir)/oranumber.c $(srcdir)/oci8.h Makefile
ocinumber.o: $(srcdir)/ocinumber.c $(srcdir)/oci8.h Makefile
attr.o: $(srcdir)/attr.c $(srcdir)/oci8.h Makefile
