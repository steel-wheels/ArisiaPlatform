#
#
#

include Makefile.inc

src = ArisiaLanguage.md4
dst = ArisiaLanguage.md

all: $(dst)

clean:
	rm -f $(dst)

$(dst): $(src)
	$(m4_cmd) $(src) > $(dst)


