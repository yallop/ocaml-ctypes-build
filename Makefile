.PHONY: build clean install uninstall

FINDLIB_NAME=ctypes-build

OCAMLBUILD=ocamlbuild -use-ocamlfind -classic-display

TARGETS=.cma .cmxa .cmxs .a

PRODUCTS=$(addprefix ocamlbuild,$(TARGETS))

TYPES=.mli .cmi .cmti

INSTALL:=$(addprefix _build/ocamlbuild/ctypes_rules,$(TYPES)) \
         $(addprefix _build/ctypes/stub_generator,$(TYPES)) \
         $(addprefix _build/ocamlbuild/ocamlbuild,$(TARGETS)) \
         $(addprefix _build/ctypes/ctypes,$(TARGETS))

build:
	$(OCAMLBUILD) $(PRODUCTS)

install:
	ocamlfind install $(FINDLIB_NAME) META $(INSTALL)

uninstall:
	ocamlfind remove $(FINDLIB_NAME)

clean:
	ocamlbuild -clean
