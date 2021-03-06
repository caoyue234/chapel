ifndef CHPL_MAKE_HOME
export CHPL_MAKE_HOME=$(shell pwd)/../..
endif

CHPL_MAKE_HOST_TARGET = --target
include $(CHPL_MAKE_HOME)/make/Makefile.base

#
# Cray X* builds are cross-compilations.
#
ifneq (, $(filter cray-x%,$(CHPL_MAKE_TARGET_PLATFORM)))
CHPL_JEMALLOC_CFG_OPTIONS += --host=x86_64-cle-linux-gnu
else ifneq ($(CHPL_MAKE_HOST_PLATFORM),$(CHPL_MAKE_TARGET_PLATFORM))
CHPL_JEMALLOC_CFG_OPTIONS += --host=$(CHPL_MAKE_TARGET_PLATFORM)-unknown-linux-gnu
endif

CHPL_JEMALLOC_CFG_OPTIONS += --prefix=$(JEMALLOC_INSTALL_DIR) \
			     --with-jemalloc-prefix=je_

# Unless the user explicitly asks for stats gathering, disable it since
# there is some runtime overhead of this capability
ifeq (, $(CHPL_JEMALLOC_ENABLE_STATS))
CHPL_JEMALLOC_CFG_OPTIONS += --disable-stats
endif

# As an optimization, use jemalloc's decay-based purging instead of the
# default ratio-based purging
CHPL_JEMALLOC_CFG_OPTIONS += --with-malloc-conf=purge:decay


# jemalloc wants you to set EXTRA_CFLAGS instead of CFLAGS:
#  """
#  EXTRA_CFLAGS="?"
#
#  Append these flags to CFLAGS.  This makes it possible to add flags such as
#  -Werror, while allowing the configure script to determine what other flags
#  are appropriate for the specified configuration.
#
#  The configure script specifically checks whether an optimization flag (-O*)
#  is specified in EXTRA_CFLAGS, and refrains from specifying an optimization
#  level if it finds that one has already been specified.
#  """
CHPL_JEMALLOC_EXTRA_CFLAGS += $(CFLAGS)

CHPL_JEMALLOC_CFG_OPTIONS += $(CHPL_JEMALLOC_MORE_CFG_OPTIONS)

default: all

all: jemalloc

clean: FORCE
	rm -rf $(JEMALLOC_BUILD_SUBDIR)

cleanall: FORCE
	rm -rf build

clobber: FORCE
	rm -rf build install

jemalloc: configure-jemalloc build-jemalloc install-jemalloc

configure-jemalloc: FORCE
	mkdir -p $(JEMALLOC_BUILD_DIR)
	cd $(JEMALLOC_BUILD_DIR) && $(JEMALLOC_SUBDIR)/configure CC='$(CC)' EXTRA_CFLAGS='$(CHPL_JEMALLOC_EXTRA_CFLAGS)' $(CHPL_JEMALLOC_CFG_OPTIONS)

build-jemalloc: FORCE
	cd $(JEMALLOC_BUILD_DIR) && $(MAKE) build_lib_static

install-jemalloc: FORCE
	cd $(JEMALLOC_BUILD_DIR) && $(MAKE) install_lib_static
	cd $(JEMALLOC_BUILD_DIR) && $(MAKE) install_bin
	cd $(JEMALLOC_BUILD_DIR) && $(MAKE) install_include


FORCE:

.NOTPARALLEL:
