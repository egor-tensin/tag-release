include prelude.mk

PKG_NAME ?= tag-release
DESTDIR  ?=

$(eval $(call noexpand,PKG_NAME))
$(eval $(call noexpand,DESTDIR))

.PHONY: all
all:

.PHONY: install
install:
	install -D -m 0644 -t '$(call escape,$(DESTDIR))/usr/share/$(call escape,$(PKG_NAME))/'     LICENSE.txt
	install -D -m 0644 -t '$(call escape,$(DESTDIR))/usr/share/doc/$(call escape,$(PKG_NAME))/' README.md

	install -D -m 0755 -T src/release.py '$(call escape,$(DESTDIR))/usr/bin/$(call escape,$(PKG_NAME))'
