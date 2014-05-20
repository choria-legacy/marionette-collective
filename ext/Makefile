#!/usr/bin/make -f

DESTDIR=

build:

clean:

install: install-bin install-lib install-conf install-plugins install-doc

install-bin:
	install -d $(DESTDIR)/usr/sbin
	install -d $(DESTDIR)/usr/bin
	cp bin/mco $(DESTDIR)/usr/bin
	cp bin/mcollectived $(DESTDIR)/usr/sbin/mcollectived

install-lib:
	install -d $(DESTDIR)/usr/lib/ruby/1.8/
	cp -a lib/* $(DESTDIR)/usr/lib/ruby/1.8/

install-conf:
	install -d $(DESTDIR)/etc/mcollective/
	install -d $(DESTDIR)/etc/init.d
	cp -r etc/* $(DESTDIR)/etc/mcollective/
	cp mcollective.init $(DESTDIR)/etc/init.d/mcollective
	rm $(DESTDIR)/etc/mcollective/ssl/PLACEHOLDER
	rm $(DESTDIR)/etc/mcollective/ssl/clients/PLACEHOLDER

install-plugins:
	install -d $(DESTDIR)/usr/share/mcollective/
	cp -a plugins $(DESTDIR)/usr/share/mcollective/

install-doc:
	install -d $(DESTDIR)/usr/share/doc/
	cp -a doc  $(DESTDIR)/usr/share/doc/mcollective

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mcollectived
	rm -rf $(DESTDIR)/usr/lib/ruby/1.8/mcollective*
	rm -rf $(DESTDIR)/usr/share/mcollective
	rm -rf $(DESTDIR)/etc/mcollective

.PHONY: build clean install uninstall
