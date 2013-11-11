-include config.mak

LIBFIRM_CPPFLAGS ?= -I../libfirm/include -I../libfirm/build/gen/include/libfirm
LIBFIRM_LFLAGS   ?= -L../libfirm/build/debug -lfirm
INSTALL ?= install
DLLEXT ?= .so
CC ?= gcc
AR ?= ar
CFLAGS ?= -O0 -g3

guessed_target := $(shell $(CC) -dumpmachine)
TARGET         ?= $(guessed_target)
TARGET_CC      ?= $(TARGET)-gcc

ifeq ($(findstring x86_64, $(TARGET)), x86_64)
	# compile library normally but runtime in 32bit mode
	RT_CFLAGS += -m32
	RT_LFLAGS += -m32
endif
ifeq ($(findstring darwin11, $(TARGET)), darwin11)
	# compile library normally but runtime in 32bit mode
	RT_CFLAGS += -m32
	RT_LFLAGS += -m32
endif
ifeq ($(findstring i686-invasic, $(TARGET)), i686-invasic)
	OCTOPOS_BASE=../octopos-app/releases/current/x86guest/multitile
	GCC_INCLUDE:=$(shell $(TARGET_CC) --print-file-name=include)
	RT_CFLAGS += -m32 -fno-stack-protector -mfpmath=sse -msse2 -nostdinc -isystem $(GCC_INCLUDE) -I $(OCTOPOS_BASE)/include
	RT_LFLAGS += -m32 -nostdlib -Wl,-T,$(OCTOPOS_BASE)/lib/sections.x $(OCTOPOS_BASE)/lib/libcsubset.a $(OCTOPOS_BASE)/lib/liboctopos.a
endif
ifeq ($(findstring sparc-invasic, $(TARGET)), sparc-invasic)
	OCTOPOS_BASE=../octopos-app/releases/current/leon/4t-sf-chipit-w-iotile
	GCC_INCLUDE:=$(shell $(TARGET_CC) --print-file-name=include)
	RT_CFLAGS += -msoft-float -fno-stack-protector -nostdinc -I $(OCTOPOS_BASE)/include -isystem $(GCC_INCLUDE)
	RT_LFLAGS += -msoft-float -nostdlib -Wl,-T,$(OCTOPOS_BASE)/lib/sections.x $(OCTOPOS_BASE)/lib/libcsubset.a $(OCTOPOS_BASE)/lib/liboctopos.a
endif

BUILDDIR=build
RUNTIME_BUILDDIR=$(BUILDDIR)/$(TARGET)
GOAL = $(BUILDDIR)/liboo$(DLLEXT)
GOAL_RT_SHARED = $(RUNTIME_BUILDDIR)/liboo_rt$(DLLEXT)
GOAL_RT_STATIC = $(RUNTIME_BUILDDIR)/liboo_rt.a
# sparc-elf-gcc does not support shared libraries
ifeq ($(findstring sparc-invasic, $(TARGET)), sparc-invasic)
	GOAL =
	GOAL_RT_SHARED =
endif
CPPFLAGS = -I. -I./include/ $(LIBFIRM_CPPFLAGS) $(LIBUNWIND_CPPFLAGS)
CFLAGS += -Wall -W -Wstrict-prototypes -Wmissing-prototypes -Werror -std=c99 -pedantic
# disabled the following warnings for now. They fail on OS/X Snow Leopard:
# the first one gives false positives because of system headers, the later one
# doesn't exist in the old gcc there
#CFLAGS += -Wunreachable-code -Wlogical-op
LFLAGS +=
PIC_FLAGS = -fpic
SOURCES = $(wildcard src-cpp/*.c) $(wildcard src-cpp/adt/*.c)
SOURCES_RT = $(wildcard src-cpp/rt/*.c)
SOURCES := $(filter-out src-cpp/gen_%.c, $(SOURCES)) src-cpp/gen_irnode.c
OBJECTS = $(addprefix $(BUILDDIR)/, $(addsuffix .o, $(basename $(SOURCES))))
OBJECTS_RT_SHARED = $(addprefix $(RUNTIME_BUILDDIR)/shared/, $(addsuffix .o, $(basename $(SOURCES_RT))))
OBJECTS_RT_STATIC = $(addprefix $(RUNTIME_BUILDDIR)/static/, $(addsuffix .o, $(basename $(SOURCES_RT))))
DEPS = $(OBJECTS:%.o=%.d) $(OBJECTS_RT_SHARED:%.o=%.d) $(OBJECTS_RT_STATIC:%.o=%.d)

Q ?= @

.PHONY: all runtime clean

all: $(GOAL) runtime

runtime: $(GOAL_RT_SHARED) $(GOAL_RT_STATIC)

# Make sure our build-directories are created
UNUSED := $(shell mkdir -p $(BUILDDIR)/src-cpp/rt $(BUILDDIR)/src-cpp/adt $(RUNTIME_BUILDDIR)/shared/src-cpp/rt $(RUNTIME_BUILDDIR)/static/src-cpp/rt)

-include $(DEPS)

SPEC_GENERATED_HEADERS := include/liboo/nodes.h src-cpp/gen_irnode.h
IR_SPEC_GENERATOR := spec/gen_ir.py
IR_SPEC_GENERATOR_DEPS := $(IR_SPEC_GENERATOR) spec/spec_util.py spec/filters.py
SPECFILE := spec/oo_nodes_spec.py

$(SOURCES): $(SPEC_GENERATED_HEADERS)

include/liboo/% : spec/templates/% $(IR_SPEC_GENERATOR_DEPS) $(SPECFILE)
	@echo GEN $@
	$(Q)$(IR_SPEC_GENERATOR) $(SPECFILE) $< > $@

src-cpp/% : spec/templates/% $(IR_SPEC_GENERATOR_DEPS) $(SPECFILE)
	@echo GEN $@
	$(Q)$(IR_SPEC_GENERATOR) $(SPECFILE) $< > $@

$(GOAL): $(OBJECTS)
	@echo '===> LD $@'
	$(Q)$(CC) -shared -o $@ $^ $(LFLAGS) $(LIBFIRM_LFLAGS)

$(GOAL_RT_SHARED): $(OBJECTS_RT_SHARED)
	@echo '===> LD $@'
	$(Q)$(TARGET_CC) -shared $(RT_LFLAGS) $(PIC_FLAGS) -o $@ $^ $(LFLAGS) $(LIBUNWIND_LFLAGS)

$(GOAL_RT_STATIC): $(OBJECTS_RT_STATIC)
	@echo '===> AR $@'
	$(Q)$(AR) -cru $@ $^

$(RUNTIME_BUILDDIR)/shared/%.o: %.c
	@echo '===> TARGET_CC $@'
	$(Q)$(TARGET_CC) $(CPPFLAGS) $(CFLAGS) $(RT_CFLAGS) $(PIC_FLAGS) -MMD -c -o $@ $<

$(RUNTIME_BUILDDIR)/static/%.o: %.c
	@echo '===> TARGET_CC $@'
	$(Q)$(TARGET_CC) $(CPPFLAGS) $(CFLAGS) $(RT_CFLAGS) -MMD -c -o $@ $<

$(BUILDDIR)/%.o: %.c
	@echo '===> CC $@'
	$(Q)$(CC) $(CPPFLAGS) $(CFLAGS) $(PIC_FLAGS) -MMD -c -o $@ $<

clean:
	rm -rf $(OBJECTS) $(OBJECTS_RT_SHARED) $(OBJECTS_RT_STATIC) $(GOAL) $(GOAL_RT_STATIC) $(GOAL_RT_SHARED) $(DEPS) $(DEPS_RT) $(RUNTIME_BUILDDIR) $(SPEC_GENERATED_HEADERS)

