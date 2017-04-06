#
# Configuration
#

# List of ocamlfind libraries used in a project
DEPENDENCIES = ocamlbuild

# ocamlbuild tags (same syntax as in _tags file)
define OCB_TAGS
	true:bin_annot \
	${DEPENDENCIES:%=true:package(%)} \
	<node_modules>:-traverse
endef

# ocamlbuild flags
define OCB_FLAGS
	-no-links \
	-use-ocamlfind \
	${OCB_TAGS:%=-tag-line "%"} \
	-I lib \
	-build-dir $(cur__target_dir)
endef

OCB = ocamlbuild ${OCB_FLAGS}

#
# Shortcuts
#

all: build
build: lib
install: install-lib

#
# Build targets
#

lib:
	@${OCB} Ocamlbuild_bs.cma
	@${OCB} Ocamlbuild_bs.cmxa

#
# Installation
#

install-lib: lib
	@ocamlfind install $(cur__name) lib/META $(cur__target_dir)/lib/Ocamlbuild_bs.*

#
# Utilities
#

clean:
	@${OCB} -clean

.DEFAULT: all
.PHONY: all build install clean lib install-lib
