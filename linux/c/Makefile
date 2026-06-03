CC = gcc
CFLAGS = -std=c11 -O2 -Wall -Wextra
SRCS = main.c commons.c international_common.c national.c nitro.c
OBJS = $(SRCS:.c=.o)
TARGET = webexpress

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
