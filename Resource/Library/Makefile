#
# Makefile for Library
#

src_scrs	= Frame.ts
dst_scrs	= $(src_scrs:.ts=.js)

tsc	= npx tsc
tsc_opt	= -t ES2018 --lib "es2017" --declaration --declarationDir types \
	  --typeRoots types \
	  --alwaysStrict --strict --strictNullChecks --pretty

%.js: %.ts
	$(tsc) $(tsc_opt) $<

all: $(dst_scrs)

clean:
	rm -f $(dst_scrs)


