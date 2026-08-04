# Armorer Steve™ — Plate Armor Q&A & Cost Estimator
# Build: gcc -O2 -o armorer armorer.c -lmysqlclient -lm

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

CC = gcc
CFLAGS = -O2 -Wall -Wextra
LDFLAGS = -lmysqlclient -lm
MYSQL_CFLAGS = $(shell mysql_config --cflags 2>/dev/null)
MYSQL_LIBS = $(shell mysql_config --libs 2>/dev/null)

ifeq ($(MYSQL_LIBS),)
    MYSQL_CFLAGS = -I/usr/include/mysql
    MYSQL_LIBS = -lmysqlclient
endif

all: armorer

armorer: armorer.c
	$(CC) $(CFLAGS) $(MYSQL_CFLAGS) -o $@ $< $(MYSQL_LIBS) $(LDFLAGS)

install: armorer
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 armorer $(DESTDIR)$(BINDIR)/armorer
	@echo "Installed: $(DESTDIR)$(BINDIR)/armorer"
	@echo "Run: armorer --populate   (first time)"
	@echo "Run: armorer              (interactive Q&A)"

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/armorer

clean:
	rm -f armorer

.PHONY: all install uninstall clean
