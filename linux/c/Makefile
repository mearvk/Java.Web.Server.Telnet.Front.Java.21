# Cross-platform C build for Linux, macOS, and Windows (MinGW/MSYS2)
# Supports a GNU-like make environment. On Windows, use a shell such as Git Bash,
# MSYS2, or a MinGW toolchain where `gcc`, `ar`, and `find` are available.

CC ?= gcc
AR ?= ar
RM ?= rm -f
CPPFLAGS ?= -I.
CFLAGS ?= -std=c11 -O2 -Wall -Wextra

UNAME_S := $(shell uname -s 2>/dev/null)
ifeq ($(OS),Windows_NT)
  SRCS := $(shell dir /s /b *.c 2>nul)
else
  SRCS := $(shell find . -name '*.c' -print)
endif

OBJS := $(SRCS:.c=.o)
LIB := libconverted.a
APP := app

.PHONY: all clean

all: $(LIB) $(APP)

$(LIB): $(OBJS)
	$(AR) rcs $@ $(OBJS)

$(APP): $(LIB) ./Main.o
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ ./Main.o $(LIB)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJS) $(LIB) $(APP)
