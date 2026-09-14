# FiduciaryServices™ — Global Transfer Wealth & Architecture Advisor
# Build: gcc -O2 -o fiduciary fiduciary.c -lmysqlclient -lm
# Build: gcc -O2 -o ach_transfer ach_transfer.c -lmysqlclient -lcurl -lm

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
JAVA_SRC = ACHTransferService.java
JAVA_CLASS_DIR = classes

CC = gcc
CFLAGS = -O2 -Wall -Wextra
MYSQL_CFLAGS = $(shell mysql_config --cflags 2>/dev/null)
MYSQL_LIBS = $(shell mysql_config --libs 2>/dev/null)
CURL_CFLAGS = $(shell pkg-config --cflags libcurl 2>/dev/null)
CURL_LIBS = $(shell pkg-config --libs libcurl 2>/dev/null)

ifeq ($(MYSQL_LIBS),)
    MYSQL_CFLAGS = -I/usr/include/mysql
    MYSQL_LIBS = -lmysqlclient
endif

ifeq ($(CURL_LIBS),)
    CURL_LIBS = -lcurl
endif

JAVAC ?= javac
JAVA ?= java
MYSQL_JDBC ?= /usr/share/java/mysql-connector-java.jar

all: fiduciary ach_transfer

fiduciary: fiduciary.c
	$(CC) $(CFLAGS) $(MYSQL_CFLAGS) -o $@ $< $(MYSQL_LIBS) -lm

ach_transfer: ach_transfer.c
	$(CC) $(CFLAGS) $(MYSQL_CFLAGS) $(CURL_CFLAGS) -o $@ $< $(MYSQL_LIBS) $(CURL_LIBS) -lm

java: $(JAVA_SRC)
	@mkdir -p $(JAVA_CLASS_DIR)
	$(JAVAC) -d $(JAVA_CLASS_DIR) $(JAVA_SRC)
	@echo "Java ACH Transfer Service compiled → $(JAVA_CLASS_DIR)/"

install: fiduciary ach_transfer
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 fiduciary $(DESTDIR)$(BINDIR)/fiduciary
	install -m 755 ach_transfer $(DESTDIR)$(BINDIR)/ach_transfer
	@echo "Installed: $(DESTDIR)$(BINDIR)/fiduciary"
	@echo "Installed: $(DESTDIR)$(BINDIR)/ach_transfer"
	@echo ""
	@echo "Run: fiduciary --populate      (first time)"
	@echo "Run: fiduciary                 (interactive Q&A)"
	@echo ""
	@echo "Run: ach_transfer --list-platforms"
	@echo "Run: ach_transfer --platform melio --to 021000021:123456789 --amount 500.00"

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/fiduciary
	rm -f $(DESTDIR)$(BINDIR)/ach_transfer

clean:
	rm -f fiduciary ach_transfer
	rm -rf $(JAVA_CLASS_DIR)

.PHONY: all java install uninstall clean
