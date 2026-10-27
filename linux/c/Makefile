# Cross-platform C build for Linux, macOS, and Windows (MinGW/MSYS2)
# Supports a GNU-like make environment. On Windows, use a shell such as Git Bash,
# MSYS2, or a MinGW toolchain where `gcc`, `ar`, and `find` are available.

CC ?= gcc
AR ?= ar
RM ?= rm -f
CPPFLAGS ?= -I.
CFLAGS ?= -std=c11 -O2 -Wall -Wextra

# Use a shell-native recursive source discovery strategy.
# On Unix-like hosts, `find` is available. On Windows/MinGW, Git Bash/MSYS2 also provides it.
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

# Example executable linking Main.c and the generated library.
# If Main.c is absent, the link step is skipped by GNU make when the target is
# missing, but if the file exists the executable still builds correctly.
$(APP): $(LIB) ./Main.o
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ ./Main.o $(LIB)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJS) $(LIB) $(APP)
