ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += findutils
DOWNLOAD          += https://ftp.gnu.org/gnu/findutils/findutils-$(FINDUTILS_VERSION).tar.xz{,.sig}
FINDUTILS_VERSION := 4.7.0
DEB_FINDUTILS_V   ?= $(FINDUTILS_VERSION)

findutils-setup: setup
	$(call PGP_VERIFY,findutils-$(FINDUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,findutils-$(FINDUTILS_VERSION).tar.xz,findutils-$(FINDUTILS_VERSION),findutils)
	
# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/findutils/.build_complete),)
findutils:
	@echo "Using previously built findutils."
else
findutils: findutils-setup gettext
	cd $(BUILD_WORK)/findutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-debug \
		gl_cv_func_ftello_works=yes
	+$(MAKE) -C $(BUILD_WORK)/findutils
	+$(MAKE) -C $(BUILD_WORK)/findutils install \
		DESTDIR=$(BUILD_STAGE)/findutils
	touch $(BUILD_WORK)/findutils/.build_complete
endif

findutils-package: findutils-stage
	# findutils.mk Package Structure
	rm -rf $(BUILD_DIST)/findutils
	mkdir -p $(BUILD_DIST)/findutils
	
	# findutils.mk Prep findutils
	cp -a $(BUILD_STAGE)/findutils/usr $(BUILD_DIST)/findutils
	
	# findutils.mk Sign
	$(call SIGN,findutils,general.xml)
	
	# findutils.mk Make .debs
	$(call PACK,findutils,DEB_FINDUTILS_V)
	
	# findutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/findutils

.PHONY: findutils findutils-package
