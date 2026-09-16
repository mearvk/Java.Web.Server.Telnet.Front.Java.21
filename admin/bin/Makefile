CC ?= cc
CXX ?= c++
CFLAGS ?= -O2 -Wall -Wextra -Wpedantic
CXXFLAGS ?= -O2 -Wall -Wextra -Wpedantic -std=c++17

.PHONY: all clean install

all: jwstf-admin-c jwstf-admin-cpp

jwstf-admin-c: admin-c.c
	$(CC) $(CFLAGS) -o $@ $<

jwstf-admin-cpp: admin-cpp.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

install: all
	install -d "$(DESTDIR)/usr/local/bin"
	install -m 0755 jwstf-admin-c jwstf-admin-cpp "$(DESTDIR)/usr/local/bin/"

clean:
	rm -f jwstf-admin-c jwstf-admin-cpp
