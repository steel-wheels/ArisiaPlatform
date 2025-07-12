#
#
#

include Makefile.inc

lang_src = ArisiaLanguage.md4
lang_dst = ArisiaLanguage.md
lang_ref = Grammar.md4 \
	   Introduction.md4 \
	   References.md4 \
	   Transpile.md4

stack_src = ArisiaStack.md4
stack_dst = ArisiaStack.md
stack_ref = References.md4

all: $(lang_dst) $(stack_dst)

clean:
	rm -f $(lang_dst) $(stack_dst)

$(lang_dst): $(lang_src) $(lang_ref)
	$(m4_cmd) $(lang_src) > $(lang_dst)

$(stack_dst): $(stack_src) $(stack_ref)
	$(m4_cmd) $(stack_src) > $(stack_dst)

