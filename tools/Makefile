all: init genxorgconf server-test

CFLAGS=-Os -MMD -pthread -Wall
LDFLAGS=-s -pthread

init: firebox-init
	strip -s -o $@ $<

firebox-init: firebox-init.o firebox-server.o
server-test: server-test.o firebox-server.o
genxorgconf: genxorgconf.cc

-include *.d
