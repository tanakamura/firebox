all: init genxorgconf

CFLAGS=-Os -MMD
LDFLAGS=-s

init: firebox-init.o
genxorgconf: genxorgconf.cc

-include *.d
