TASS ?= 64tass

KUP_APP := k2uploader.bin
PGZ_APP := k2uploader.pgz
CORE_MGR_APP := k2coremgr.pgz
CORE_MGR_KUP_APP := coremgr.kup
SOURCE := k2uploader.asm
CORE_MGR_SOURCE := k2coremgr.asm
KUP_LISTING := k2uploader.lst
PGZ_LISTING := k2uploader-pgz.lst
CORE_MGR_KUP_LISTING := k2coremgr-kup.lst

.PHONY: all kup pgz core-manager core-manager-pgz core-manager-kup clean

all: kup pgz core-manager

kup: $(KUP_APP)

pgz: $(PGZ_APP)

core-manager: $(CORE_MGR_APP) $(CORE_MGR_KUP_APP)

core-manager-pgz: $(CORE_MGR_APP)

core-manager-kup: $(CORE_MGR_KUP_APP)

$(KUP_APP): $(SOURCE)
	$(TASS) --quiet -b -L $(KUP_LISTING) -o $@ $<
	@test "$$(wc -c < $@)" -eq 8192 || \
		(echo "$(KUP_APP) must be exactly one 8 KiB KUP block"; exit 1)

$(PGZ_APP): $(SOURCE)
	$(TASS) --quiet --c256-pgz --output-exec=RUN -D PGZ_BUILD=1 \
		-L $(PGZ_LISTING) -o $@ $<

$(CORE_MGR_APP): $(CORE_MGR_SOURCE)
	$(TASS) --quiet --long-branch --c256-pgz --output-exec=RUN \
		-L k2coremgr.lst -o $@ $<

$(CORE_MGR_KUP_APP): $(CORE_MGR_SOURCE)
	$(TASS) --quiet --long-branch -b -D CORE_MGR_KUP=1 \
		-L $(CORE_MGR_KUP_LISTING) -o $@ $<
	@test "$$(wc -c < $@)" -eq 16384 || \
		(echo "$(CORE_MGR_KUP_APP) must be exactly two 8 KiB KUP blocks"; exit 1)

clean:
	$(RM) $(KUP_APP) $(PGZ_APP) $(CORE_MGR_APP) $(KUP_LISTING) \
		$(PGZ_LISTING) k2coremgr.lst $(CORE_MGR_KUP_APP) \
		$(CORE_MGR_KUP_LISTING)
