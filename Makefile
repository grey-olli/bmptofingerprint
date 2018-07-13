OUTDIR = .
OUTPUT = $(OUTDIR)/fingerprint
SRC = fingerprint.c
DUMMY := $(shell test -d $(OUTDIR) || mkdir $(OUTDIR))

all :
	./build.sh
check :
	./test_resulting_binaries.sh
clean :
	./cleanup.sh

.PHONY: all clean check
