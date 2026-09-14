CC = gcc
CFLAGS = -std=c11 -O2 -Wall -Wextra -I.

# find all .c files recursively under this directory
SRCS := $(shell find . -name '*.c')
OBJS := $(SRCS:.c=.o)
LIB := libconverted.a
APP := app

.PHONY: all clean

all: $(LIB) $(APP)

# archive library of all objects
$(LIB): $(OBJS)
ar rcs $@ $(OBJS)

# example executable linking Main.c and the library
# If Main.c does not exist, this target will still attempt to build (no-op)
$(APP): $(LIB) ./Main.o
$(CC) $(CFLAGS) -o $@ ./Main.o $(LIB)

# generic rule to compile .c -> .o
%.o: %.c
$(CC) $(CFLAGS) -c $< -o $@

clean:
rm -f $(OBJS) $(LIB) $(APP)

