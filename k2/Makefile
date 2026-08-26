TASS ?= 64tass

KUP_APP := k2uploader.bin
PGZ_APP := k2uploader.pgz
CORE_MGR_APP := k2coremgr.pgz
SOURCE := k2uploader.asm
CORE_MGR_SOURCE := k2coremgr.asm
KUP_LISTING := k2uploader.lst
PGZ_LISTING := k2uploader-pgz.lst

.PHONY: all kup pgz core-manager clean

all: kup pgz core-manager

kup: $(KUP_APP)

pgz: $(PGZ_APP)

core-manager: $(CORE_MGR_APP)

$(KUP_APP): $(SOURCE)
	$(TASS) --quiet -b -L $(KUP_LISTING) -o $@ $<
	@test "$$(wc -c < $@)" -eq 8192 || \
		(echo "$(KUP_APP) must be exactly one 8 KiB KUP block"; exit 1)

$(PGZ_APP): $(SOURCE)
	$(TASS) --quiet --c256-pgz --output-exec=RUN -D PGZ_BUILD=1 \
		-L $(PGZ_LISTING) -o $@ $<

$(CORE_MGR_APP): $(CORE_MGR_SOURCE)
	$(TASS) --quiet --c256-pgz --output-exec=RUN \
		-L k2coremgr.lst -o $@ $<

clean:
	$(RM) $(KUP_APP) $(PGZ_APP) $(CORE_MGR_APP) $(KUP_LISTING) \
		$(PGZ_LISTING) k2coremgr.lst
