tiny_busybox: tiny_busybox_finish

BUSYBOX=busybox-1.36.0

busybox-1.36.0.tar.bz2:
	wget https://busybox.net/downloads/$(BUSYBOX).tar.bz2

busybox_extracted: $(BUSYBOX).tar.bz2
	tar -xf $(BUSYBOX).tar.bz2
	cp busybox.config /.config
	touch busybox_extracted

busybox_build:
	$(MAKE) -C $(BUSYBOX) CC=musl-gcc
	cp $(BUSYBOX)/busybox .

tiny_busybox_finish: busybox_build
