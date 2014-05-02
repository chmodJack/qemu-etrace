CC = $(CROSS)gcc
LD = $(CC)

CFLAGS  += -Wall -O3 -g
#CFLAGS += -m32
#CFLAGS += -pg
#LDFLAGS += -pg
#LDFLAGS += -static
LDLIBS += -lbfd
LDLIBS += -lopcodes
LDLIBS += -lbfd
LDLIBS += -liberty
LDLIBS += -lz

OBJS += qemu-etrace.o
OBJS += trace-open.o
OBJS += filename.o
OBJS += util.o
OBJS += safeio.o
OBJS += run.o
OBJS += syms.o
OBJS += disas.o
OBJS += coverage.o
OBJS += cov-gcov.o
OBJS += cov-cachegrind.o
OBJS += etrace.o
OBJS += trace-hex.o

TARGET = qemu-etrace

all: $(TARGET).sh

-include $(OBJS:.o=.d)
CFLAGS += -MMD

$(TARGET): $(OBJS)
	$(LD) $(HEAD) $(OBJS) $(LDFLAGS) $(LDLIBS) -o $@

BU_VER=binutils-2.22
BU_FILE=$(BU_VER).tar.gz
BU_URL=http://ftp.gnu.org/gnu/binutils/$(BU_FILE)
BU_INSTALLDIR=$(CURDIR)/binutils-install
BU_BUILDDIR=binutils-build

CPPFLAGS += -I $(BU_INSTALLDIR)/include
LDFLAGS += -L $(BU_INSTALLDIR)/lib

$(BU_FILE):
	if [ ! -f $(BU_FILE) ]; then	\
		wget $(BU_URL) ;	\
	fi

$(BU_VER): $(BU_FILE)
	tar -xzf $(BU_FILE)


binutils: $(BU_VER)
	mkdir -p $(BU_BUILDDIR)
	mkdir -p $(BU_INSTALLDIR)
	cd $(BU_BUILDDIR); \
	if [ ! -f config.log ]; then \
		../$(BU_VER)/configure --enable-targets=all --disable-werror --prefix=$(BU_INSTALLDIR) ; \
	fi;
	$(MAKE) -C $(BU_BUILDDIR)
	$(MAKE) -C $(BU_BUILDDIR) install
	cp $(BU_BUILDDIR)/libiberty/libiberty.a $(BU_INSTALLDIR)/lib

$(TARGET).sh: $(TARGET)
	echo "#!/bin/sh" >$@
	echo "#" >>$@
	echo "# Autogenerated helper script." >>$@
	echo "" >>$@
	echo "BUILD_DIR=$(CURDIR)" >>$@
	if [ -d $(BU_INSTALLDIR) ]; then \
		echo "BU_INSTALLDIR=$(BU_INSTALLDIR)" >>$@; \
		echo "ARGS=\"--nm \$${BU_INSTALLDIR}/bin/nm\"" >>$@; \
		echo "ARGS=\"--objdump \$${BU_INSTALLDIR}/bin/objdump\"" >>$@; \
		echo "ARGS=\"--addr2line \$${BU_INSTALLDIR}/bin/addr2line\"" >>$@; \
	fi
	echo "ETRACE=\$${BUILD_DIR}/qemu-etrace" >>$@
	echo "" >>$@
	echo "\$${ETRACE} \$${ARGS} \$$*" >>$@
	chmod +x $@

clean:
	$(RM) $(OBJS) $(OBJS:.o=.d) $(TARGET) $(TARGET).sh

distclean: clean
	$(RM) -r $(BU_BUILDDIR) $(BU_INSTALLDIR) $(BU_VER)
	$(RM) $(BU_FILE)
