CXX ?= g++
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
CXXFLAGS ?= -O2 -Wall -Wextra -std=c++17
JAVAC ?= javac
JAVA ?= java
PREFIX ?= /bin

.PHONY: all c cpp java clean install install-engine

all: c cpp java

c: bin/blackbelt-c
cpp: bin/blackbelt-cpp
java: bin/BlackBeltCLI.class

bin/blackbelt-c: blackbelt-c.c
	$(CC) $(CFLAGS) -o $@ $<

bin/blackbelt-cpp: blackbelt.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

bin/BlackBeltCLI.class: BlackBeltCLI.java
	$(JAVAC) --release 21 -d . $<

install: all
	install -Dm755 bin/blackbelt-c $(DESTDIR)$(PREFIX)/blackbelt-c
	install -Dm755 bin/blackbelt-cpp $(DESTDIR)$(PREFIX)/blackbelt-cpp
	install -Dm755 bin/blackbelt-engine.sh $(DESTDIR)$(PREFIX)/blackbelt-engine.sh
	install -Dm644 bin/BlackBeltCLI.class $(DESTDIR)$(PREFIX)/BlackBeltCLI.class
	install -Dm644 bin/BlackBeltCLI.java $(DESTDIR)$(PREFIX)/BlackBeltCLI.java

clean:
	rm -f bin/blackbelt-c bin/blackbelt-cpp BlackBeltCLI.class
	rm -f BlackBeltCLI$$\{\$$\}.class
