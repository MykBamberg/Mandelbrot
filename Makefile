SRCS := mandelbrot.d
TARGET := mandelbrot

COMPILE ?= $(shell \
    if command -v dmd >/dev/null 2>&1; then \
        echo "dmd -O $(SRCS) -of=$(TARGET)"; \
    elif command -v gdc >/dev/null 2>&1; then \
        echo "gdc -O2 $(SRCS) -o $(TARGET)"; \
    elif command -v ldc2 >/dev/null 2>&1; then \
        echo "ldc2 --O2 $(SRCS) -of=$(TARGET)"; \
    else \
        echo "# No D compiler found."; \
    fi)

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

COMPLETIONS_SOURCE := completions/mandelbrot.bash
COMPLETIONSDIR := $(PREFIX)/share/bash-completion/completions
COMPLETIONS_TARGET := $(COMPLETIONSDIR)/mandelbrot

all: $(TARGET)

clean:
	@rm -rf $(TARGET) mandelbrot.o

$(TARGET): $(SRCS)
	$(COMPILE)

install: $(TARGET)
	install -d $(BINDIR)
	install -m 755 $(TARGET) $(BINDIR)/$(TARGET)
	install -d $(COMPLETIONSDIR)
	install -m 644 $(COMPLETIONS_SOURCE) $(COMPLETIONS_TARGET)

uninstall:
	rm -f $(BINDIR)/$(TARGET)
	rm -f $(COMPLETIONS_TARGET)

.PHONY: all clean install uninstall
