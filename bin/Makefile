CXX ?= g++
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
CXXFLAGS ?= -O2 -Wall -Wextra -std=c++17
JAVAC ?= javac
PREFIX ?= /bin

.PHONY: all c cpp java clean install

all: c cpp java

c: blackbelt-c
cpp: blackbelt-cpp
java: BlackBeltCLI.class

blackbelt-c: blackbelt-c.c
	$(CC) $(CFLAGS) -o $@ $<

blackbelt-cpp: blackbelt.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

BlackBeltCLI.class: BlackBeltCLI.java
	$(JAVAC) --release 21 -d . $<

install: all
	install -Dm755 blackbelt-c $(DESTDIR)$(PREFIX)/blackbelt-c
	install -Dm755 blackbelt-cpp $(DESTDIR)$(PREFIX)/blackbelt-cpp
	install -Dm755 blackbelt-engine.sh $(DESTDIR)$(PREFIX)/blackbelt-engine.sh
	install -Dm644 BlackBeltCLI.class $(DESTDIR)$(PREFIX)/BlackBeltCLI.class
	install -Dm644 BlackBeltCLI.java $(DESTDIR)$(PREFIX)/BlackBeltCLI.java

clean:
	rm -f blackbelt-c blackbelt-cpp BlackBeltCLI.class
