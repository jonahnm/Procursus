ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += idevicerestore
IDEVICERESTORE_COMMIT  := 7d622d916be16f2df5a72bf53a42f3a326bbfaa4
IDEVICERESTORE_VERSION := 1.0.0+git20220628.$(shell echo $(IDEVICERESTORE_COMMIT) | cut -c -7)
DEB_IDEVICERESTORE_V   ?= $(IDEVICERESTORE_VERSION)

idevicerestore-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,idevicerestore,$(IDEVICERESTORE_COMMIT),$(IDEVICERESTORE_COMMIT))
	$(call EXTRACT_TAR,idevicerestore-$(IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(IDEVICERESTORE_COMMIT),idevicerestore)

ifneq ($(wildcard $(BUILD_WORK)/idevicerestore/.build_complete),)
idevicerestore:
	@echo "Using previously built idevicerestore."
else
idevicerestore: idevicerestore-setup curl libimobiledevice-glue libimobiledevice libirecovery libplist libzip
	cd $(BUILD_WORK)/idevicerestore && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		PACKAGE_VERSION="$(IDEVICERESTORE_VERSION)"
		zlib_LIBS="-L$(TARGET_SYSROOT)/usr/lib -lz" \
		zlib_CFLAGS="-I$(TARGET_SYSROOT)/usr/include"
	+$(MAKE) -C $(BUILD_WORK)/idevicerestore
	+$(MAKE) -C $(BUILD_WORK)/idevicerestore install \
		DESTDIR="$(BUILD_STAGE)/idevicerestore"
	$(call AFTER_BUILD)
endif

idevicerestore-package: idevicerestore-stage
	# idevicerestore.mk Package Structure
	rm -rf $(BUILD_DIST)/idevicerestore

	# idevicerestore.mk Prep idevicerestore
	cp -a $(BUILD_STAGE)/idevicerestore $(BUILD_DIST)

	# idevicerestore.mk Sign
	$(call SIGN,idevicerestore,general.xml)

	# idevicerestore.mk Make .debs
	$(call PACK,idevicerestore,DEB_IDEVICERESTORE_V)

	# idevicerestore.mk Build cleanup
	rm -rf $(BUILD_DIST)/idevicerestore

.PHONY: idevicerestore idevicerestore-package
