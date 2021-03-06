####### Makefile for "BioSig for C/C++" #####################
###
###  Copyright (C) 2006-2015 Alois Schloegl <alois.schloegl@ist.ac.at>
###  This file is part of the "BioSig for C/C++" repository
###  (biosig4c++) at http://biosig.sf.net/
###
##############################################################

##### Target: GNU/Linux
#
## make && make install    build and install libbiosig, but no other tools.
#             libbiosig is a prerequisite for building all the other tools below.
#
## make save2gdf   - makes converter
## make biosig_fhir   - makes converter for fhir-binary template
## make install_save2gdf   - installs converter
## make install_mma 	installs biosig's sload for Mathematica in $PREFIX/share/biosig/mathematica
## make install_mex 	installs mexbiosig for Matlab in $PREFIX/share/biosig/mex
#
## make mex4o      - makes mexSLOAD, mexSOPEN for Octave (requires Octave-headers)
## make mex4m      - makes mexSLOAD, mexSOPEN for Matlab (requires Matlab, mex -setup must be configured)
## make mexw32     - makes mexSLOAD.mexw32, mexSOPEN.mexw32 (requires that mingw32, gnumex libraries from Matlab/Win32)
## make mexw64     - makes mexSLOAD.mexw64, mexSOPEN.mexw64 (requires that mce-w32, gnumex libraries from Matlab/Win64)
## make mex        - mex4o, mex4m, mexw32, mexw64 combined
## make biosig4python - makes python interface (requires Python)
## make biosig4java - makes Java interface (experimental)
## make biosig4php - makes PHP interface (experimental)
## make biosig4perl - makes perl interface (experimental)
## make biosig4ruby - makes ruby interface (experimental)
## make biosig4tcl - makes tcl/tk interface (experimental)
##
## make win32 and make win64 are obsolete. save2gdf.exe, and libbiosig.{a,dll} for windows can now be built
## with the mingw-cross-compiler environment (mxe.cc).
##    git clone https://github.com/schloegl/mxe.git
##    make biosig
## should do what you want. Please note, that win32mma does now also rely that libbiosig is built with MXE.
## Make sure that CROSS or CROSS64 is properly defined when running `make`
##
## ???
## make sigviewer  - makes sigviewer

##### Target: Win32
## make win32      - makes save2gdf.exe,libbiosig.lib,libbiosig.dll, for MSWindows, requires MinGW
## make mexw32 mex/mexSLOAD.mexw32   - requires MinGW32 and GNUMEX libraries from Matlab/Win32
## make win32/sigviewer.exe 	- requires sources of SigViewer, and MinGW32 (mex: make suitesparse zlib qt )

##### Target: Win64
## make win64      - makes save2gdf.exe,libbiosig.lib,libbiosig.dll, for MSWindows, requires MinGW
## make mexw64 mex/mexSLOAD.mexw64   - requires MCE-W64 and GNUMEX libraries from Matlab/Win64
## make win64/sigviewer.exe 	- requires sources of SigViewer and MCE-W64, make suitesparse zlib qt 

##### Target: MacOSX w/ homebrew
## make install_homebrew	installs libbiosig and save2gdf
	# requires: brew tap homebrew/dupes
	#	    brew install libiconv

###############################
# whether dynamic or static linking is used, can be controlled with
# LIBEXT. Setting it to 'a' links statically, 'so' links dynamically
#
LIBEXT        = a
#LIBEXT	      = so
###############################

### User-specified options: its likely you want to change this
# settings for cross compiler: tested with MXE and mce-w64 with make suitesparse zlib qt ; 
CROSS   = $(HOME)/src/mxe.github.schloegl/usr/bin/i686-w64-mingw32.static
## local MXE
ifeq "$(wildcard $(CROSS)-gcc)" ""
CROSS   = $(HOME)/src/mxe.master/usr/bin/i686-w64-mingw32.static
endif
ifeq "$(wildcard $(CROSS)-gcc)" ""
CROSS         = $(shell pwd)/../mxe/usr/bin/i686-w64-mingw32.static
endif
ifeq "$(wildcard $(CROSS)-gcc)" ""
CROSS         = /usr/local/src/mxe/usr/bin/i686-w64-mingw32.static
endif

CROSS64       = $(HOME)/src/mxe.github.schloegl/usr/bin/x86_64-w64-mingw32.static
ifeq "$(wildcard $(CROSS64)-gcc)" ""
CROSS64       = $(HOME)/src/mxe.master/usr/bin/x86_64-w64-mingw32.static
endif
ifeq "$(wildcard $(CROSS64)-gcc)" ""
CROSS64       = $(HOME)/src/mxe.master/usr/bin/x86_64-w64-mingw32.static
endif

# settings for mex files
MEX_OPTION    = -largeArrayDims # turn on for 64 bit Matlab, otherwise empty
# directory for sources of sigviewer
PathToSigViewer = ../sigviewer
PathToSigViewerWIN32 = ../sigviewer4win32
PathToSigViewerWIN64 = ../sigviewer4win64

#CFLAGS       += -std=gnu11
CFLAGS       += -fstack-protector -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -pipe -fPIC -fno-builtin-memcmp -O2 -Wno-unused-result
CFLAGS       += -Wno-deprecated
CFLAGS       += -D_GNU_SOURCE
CFLAGS       += -D_XOPEN_SOURCE=700
CFLAGS       += -D_DEFAULT_SOURCE
CXXFLAGS      = $(CFLAGS)

CFLAGS += "lib/libbiosig.a"
CFLAGS += "lib/libcholmod.a"
CFLAGS += "lib/libsuitesparseconfig.a"
CFLAGS += -lz
CFLAGS += "lib/libiconv.a"

## TARGET dependencies
ifeq (,$(TARGET))
	CC      ?= gcc
	CXX     ?= g++
	AR      := ar rcs
	PKGCONF := pkg-config
	PREFIX  ?= /usr/local
ifneq (Darwin,$(shell uname))
	LFLAGS  += -Wl,-z,relro,-z,now
endif
else ifeq (intel,$(TARGET))
	CC      := /opt/intel/bin/icc
	CXX     := /opt/intel/bin/icc
	LD      := /opt/intel/bin/xild
	AR      := /opt/intel/bin/xiar crs
	PREFIX  ?= /usr/local
else 
	prefix  := $(subst /bin/,/,$(dir $(shell which $(TARGET)-gcc)))
	PREFIX	?= $(dir $(dir $(prefix)))$(TARGET)
	CC      := $(TARGET)-gcc
	CXX     := $(TARGET)-g++
	LD      := $(TARGET)-ld
	AR      := $(TARGET)-ar rcs
	PKGCONF := $(TARGET)-pkg-config
	ifneq (,$(findstring mingw,$(TARGET)))
		## add gnulib's getlogin
		SOURCES += win32/getlogin.c win32/getline.c win32/getdelim.c
		OBJECTS += getlogin.o getline.o getdelim.o
		CFLAGS  += -I.
		LIBS    += -lssp
		LDLIBS  += -liconv -liberty -lws2_32
		BINEXT   = .exe
	endif
endif

ifeq (Darwin,$(shell uname))
	## Homebrew:
	##	brew install gawk
	##	brew install gnu-tar
	##	brew install homebrew/dupes/libiconv
	##	brew install homebrew/science/suite-sparse
	##
	TAR	       = gtar
	LD	       = ld
	CFLAGS        += -I/usr/local/opt/libiconv/include
	LDLIBS        += -L/usr/local/opt/libiconv/lib/ -liconv -lstdc++
	LDFLAGS       += -dylib -arch x86_64 -macosx_version_min 10.10
	DLEXT          = dylib
	FULLDLEXT      = ${BIOSIG_VERSION}.dylib
	SONAME_PREFIX  = -install_name # the last space character is crucial
	SONAME_POSTFIX = .${MAJOR_VERSION}.${MINOR_VERSION}.$(DLEXT)
	prefix        ?= /usr/local

else ifneq (,$(findstring MINGW, $(shell uname)))
	## add gnulib's getlogin
	SOURCES += win32/getlogin.c win32/getline.c win32/getdelim.c
	OBJECTS += getlogin.o getline.o getdelim.o
	## exclude conflicting definition of sopen from mingw's io.h
	CC  = gcc
	CXX = g++
	CFLAGS  += -I.
	CFLAGS  += -pipe -fPIC -D_REENTRANT -D=BUILD_DLL
	LDFLAGS += -shared
	TAR	 = tar
	LD	 = $(CXX)
	DLEXT    = dll
	FULLDLEXT      = ${MAJOR_VERSION}${MINOR_VERSION}.dll
	SONAME_PREFIX  = -Wl,-soname=
	SONAME_POSTFIX = ${MAJOR_VERSION}${MINOR_VERSION}.$(DLEXT)
	LIBS    += -lssp
	LDLIBS  += -liconv -lws2_32 -Wl,-subsystem,windows
	prefix  :=

else
	TAR	       = tar
	LD	       = $(CXX)
	LDFLAGS       += -shared
	DLEXT          = so
	FULLDLEXT      = so.${BIOSIG_VERSION}
	SONAME_PREFIX  = -Wl,-soname=
	SONAME_POSTFIX = .$(DLEXT).${MAJOR_VERSION}.${MINOR_VERSION}
	prefix        ?= /usr/local
endif

DEFINES_ALL   = #-D=NDEBUG

DEFINES      += $(DEFINES_ALL)
#DEFINES      += -D=WITH_SON 
#DEFINES      += -D=WITHOUT_SCP_DECODE
#DEFINES      += -D=WITH_TIMESTAMPEVENT
#DEFINES      += -D=WITH_TIMESTAMPCHANNEL

ifeq (,$(findstring MINGW, $(shell uname)))
             ### MXE_OCTAVE does not provid ZLIB
DEFINES      += -D=WITH_ZLIB
endif

DEFINES      += -D=WITH_PTHREAD
#DEFINES      += -D=WITH_CURL
DEFINES      += -D=__4HAERTEL__
DEFINES      += -D=WITH_FAMOS
DEFINES      += -D=WITH_FIFF
DEFINES      += -D=WITH_CHOLMOD
DEFINES      += -D=WITHOUT_NETWORK
#DEFINES      += -D=WITH_SCP3
#DEFINES      += -D=WITH_HDF
#DEFINES      += -D=WITH_MATIO
#DEFINES      += -D=WITH_LIBXML2 
DEFINES      += -D=WITH_FEF
#DEFINES      += -D=WITH_PDP
#DEFINES      += -D=WITH_DCMTK
#DEFINES      += -D=WITH_DICOM
#DEFINES      += -D=WITH_GDCM
#DEFINES      += -D=WITH_GSL
#DEFINES      += -D=WITH_EEPROBE
#DEFINES      += -D=WITH_TDMS
DEFINES      += -D=WITH_ATF
#DEFINES      += -D=WITH_AVI
#DEFINES      += -D=WITH_RIFF
#DEFINES      += -D=WITH_WAV
#DEFINES      += -D=WITH_NEV
DEFINES      += -D=MAKE_EDFLIB


ifneq (,$(findstring WITH_GDCM, $(DEFINES)))
  INCPATH    += -I$(wildcard /usr/include/gdcm-2*/)
  LDLIBS     += -lgdcmCommon -lgdcmDSED -lgdcmMEXD -lgdcmMSFF -lgdcmDICT -lgdcmIOD
endif
ifneq (,$(findstring WITH_ZLIB, $(DEFINES)))
  LDLIBS     += -lz
endif
ifneq (,$(findstring WITH_PTHREAD, $(DEFINES)))
  LDLIBS     += -lpthread
endif

ifneq (,$(findstring WITH_CHOLMOD, $(DEFINES)))
  LDLIBS     += -lcholmod
ifeq (Darwin,$(shell uname))
  ## homebrew requires this in addition to cholmod
  LDLIBS     += -lsuitesparseconfig
endif
endif

ifneq (,$(findstring WITH_LIBXML2, $(DEFINES)))
  LDLIBS     += -lxml2
endif
ifneq (,$(findstring WITH_CURL, $(DEFINES)))
  LDLIBS     += -lcurl
endif
ifneq (,$(findstring WITH_HDF, $(DEFINES)))
  LDLIBS     += -lhdf5
endif
ifneq (,$(findstring WITH_DCMTK, $(DEFINES)))
  LDLIBS     += -ldcmdata -loflog -lofstd
endif
ifneq (,$(findstring WITH_MATIO, $(DEFINES)))
  LDLIBS     += -lmatio
endif
ifneq (,$(findstring stack-protector, $(CFLAGS)))
ifneq (,$(findstring CYGWIN, $(shell uname)))
  LDLIBS     += -lssp -liconv
endif 
ifneq (,$(findstring MINGW, $(shell uname)))
  LDLIBS     += -lssp -liconv
endif
endif

LIBS         += $(LDLIBS)

DELETE        = rm -f
COPY          = cp -f
DATA_DIR      = data/
DATA_DIR_CFS  = $(HOME)/L/data/test/cfs/
TEMP_DIR      = test/
SED           = sed
VERBOSE	     := -V0

##########################################################
## set Matlab and Octave variables
ifeq (undefined,$(origin MATLABDIR))
  ifeq (Darwin,$(shell uname))
    MATLABDIR := $(shell find /Applications/MATLAB* -name bin -type d -depth 1 2>/dev/null | head -1)
  else
    MATLABDIR ?= $(shell find /usr/local/MATLAB* -maxdepth 2 -name bin -type d 2>/dev/null | head -1)
  endif
endif

ifeq (,$(MATLABDIR))
  #$(warning MATLABDIR is not defined)
else
  MEX         = $(MATLABDIR)/mex
  MEX_EXT    := $(shell $(MATLABDIR)/mexext)
endif


# use environment variable to define OCTAVE_VERSION
#   e.g. export OCTAVE_VERSION=-3.6.2
# Octave - global install  (e.g. from debian package)
#OCTAVE_VERSION = 
# Octave - local install (e.g. compiled from sources) 
#OCTAVE_VERSION = -3.6.1

OCT           := mkoctfile$(OCTAVE_VERSION)
##########################################################

##########################################################
## set variables for Python
SWIG           := swig
PYTHON         ?= python
PYTHONVER      := $(shell $(PYTHON) -c "import sys; print(sys.version[:3])")
NUMPY_INC      := $(shell $(PYTHON) -c "import numpy.distutils.misc_util as mu; print(' -I'.join(mu.get_numpy_include_dirs()))")
PYTHON_INCPATH := /usr/include/python$(PYTHONVER)/
PYTHON_LIB     := python$(PYTHONVER)

 
##########################################################
## set variables for MinGW Crosscompiler: compile on linux binaries for windows
##
PathToMinGW   = $(dir $(CROSS))..$(nondir $(CROSS))
PathToMinGW64 = $(dir $(CROSS64))..$(nondir $(CROSS64))

MinGWCC      = $(CROSS)-gcc
MinGWCXX     = $(CROSS)-g++
MinGWDEF     = $(DEFINES) 
MinGWCFLAGS  = -pipe -fPIC  -D_REENTRANT -D=BUILD_DLL $(MinGWDEF) -Iwin32 -I$(PathToMinGW)/include/
MinGWLIBS    = win32/libbiosig.a -L$(PathToMinGW)/lib/ $(LDLIBS) # static
MinGWLINK    = $(MinGWCXX)

MinGW64CC      = $(CROSS64)-gcc
MinGW64CXX     = $(CROSS64)-g++
MinGW64CFLAGS  = -pipe -fPIC -O2 -D_REENTRANT -D=BUILD_DLL $(MinGWDEF) -Iwin64 -I$(PathToMinGW64)/include/
MinGW64LIBS    = win64/libbiosig.a -L$(PathToMinGW64)/lib/ $(LDLIBS) # static
MinGW64LINK    = $(MinGW64CXX)
##########################################################

# Versioning
MAJOR_VERSION  := $(word 3, $(shell grep '\#define BIOSIG_VERSION_MAJOR' biosig.h))
MINOR_VERSION  := $(word 3, $(shell grep '\#define BIOSIG_VERSION_MINOR' biosig.h))
STEPPING       := $(word 3, $(shell grep '\#define BIOSIG_PATCHLEVEL' biosig.h))
BIOSIG_VERSION := ${MAJOR_VERSION}.${MINOR_VERSION}.${STEPPING}
TODAY          := $(shell date +%Y%m%d)

####### External directory
ifneq (`ls -l extern |wc -l`,1)
  EXTERN  = extern
else
  EXTERN  = ../biosig4matlab/doc
endif

####### Output directory
OBJ	      = ./obj
INC	      = $(DESTDIR)$(PREFIX)/include
BIN	      = $(DESTDIR)$(PREFIX)/bin
LIB	      = $(DESTDIR)$(PREFIX)/lib
SHARE	      = $(DESTDIR)$(PREFIX)/share

####### Files
SOURCES      += biosig.c \
		t210/sopen_cfs_read.c \
		t210/sopen_heka_read.c \
		t210/sopen_igor.c \
		t210/sopen_scp_read.c \
		t210/sopen_tdms_read.c \
		t210/sopen_famos_read.c \
		t210/sopen_abf_read.c \
		t210/sopen_alpha_read.c \
		t210/sopen_axg_read.c \
		t210/scp-decode.cpp \
		t220/sopen_scp_write.c \
		t220/crc4scp.c \
		t230/sopen_hl7aecg.cpp \
		t240/sopen_fef_read.c \
		test0/sandbox.c \
		xgethostname.c \
		gdftime.c \
		mdc_ecg_codes.c \
		physicalunits.c \
		biosig-network.c \
		save2gdf.c \
		biosig_client.c \
		biosig_server.c

ifeq (,$(findstring WITH_LIBXML2, $(DEFINES)))
  ## TinyXML is used when built without libxml2 	
  SOURCES    +=	XMLParser/tinyxml.cpp \
		XMLParser/tinyxmlparser.cpp \
		XMLParser/tinyxmlerror.cpp \
		XMLParser/tinystr.cpp 
endif

OBJECTS      += \
		crc4scp.o \
		biosig.o \
		sopen_cfs_read.o \
		sopen_heka_read.o \
		sopen_igor.o \
		sopen_scp_read.o \
		sopen_abf_read.o \
		sopen_alpha_read.o \
		sopen_axg_read.o \
		sopen_scp_write.o \
		sopen_hl7aecg.o \
		biosig-network.o \
		gdftime.o \
		mdc_ecg_codes.o \
		physicalunits.o \
		sandbox.o \
		xgethostname.o

MinGWOBJECTS  = \
		win32/crc4scp.obj \
		win32/biosig.obj \
		win32/getlogin.obj \
		win32/sopen_cfs_read.obj \
		win32/sopen_heka_read.obj \
		win32/sopen_igor.obj \
		win32/sopen_scp_read.obj \
		win32/sopen_abf_read.obj \
		win32/sopen_alpha_read.obj \
		win32/sopen_axg_read.obj \
		win32/sopen_scp_write.obj \
		win32/sopen_hl7aecg.obj \
		win32/biosig-network.obj \
		win32/gdftime.obj \
		win32/physicalunits.obj \
		win32/sandbox.obj \
		win32/xgethostname.obj

ifneq (,$(findstring WITH_FAMOS, $(DEFINES)))
  OBJECTS      += sopen_famos_read.o
endif
ifneq (,$(findstring WITH_FAMOS, $(MinGWDEF)))
  MinGWOBJECTS += win32/sopen_famos_read.obj
endif

ifneq (,$(findstring WITH_FEF, $(DEFINES)))
  OBJECTS      += sopen_fef_read.o
endif
ifneq (,$(findstring WITH_FEF, $(MinGWDEF)))
  MinGWOBJECTS += win32/sopen_fef_read.obj
endif

ifneq (,$(findstring WITH_FEF, $(DEFINES)))
  OBJECTS      += sopen_tdms_read.o
endif
ifneq (,$(findstring WITH_FEF, $(MinGWDEF)))
  MinGWOBJECTS += win32/sopen_tdms_read.obj
endif

ifeq (,$(findstring WITHOUT_SCP_DECODE, $(DEFINES)))
  OBJECTS      += scp-decode.o
endif
ifeq (,$(findstring WITHOUT_SCP_DECODE, $(MinGWDEF)))
  MinGWOBJECTS += win32/scp-decode.obj
endif

ifeq (,$(findstring WITH_LIBXML2, $(DEFINES)))
  ## TinyXML is used when built without libxml2 	
  OBJECTS    += tinyxml.o tinyxmlparser.o tinyxmlerror.o tinystr.o 
endif
ifeq (,$(findstring WITH_LIBXML2, $(DEFINES)))
  ## TinyXML is used when built without libxml2 	
  MinGWOBJECTS += win32/tinyxml.obj win32/tinyxmlparser.obj win32/tinyxmlerror.obj win32/tinystr.obj 
endif


MinGW64OBJECTS  = $(patsubst win32/%.obj, win64/%.obj, $(MinGWOBJECTS))

LIB_OBJECTS = libbiosig.a libbiosig2.a libgdf.a libgdftime.a libphysicalunits.a libbiosig.$(DLEXT) libbiosig2.$(DLEXT) libgdf.$(DLEXT) libgdftime.$(DLEXT) libphysicalunits.$(DLEXT)

first: $(IO_H_FILE2) lib
tools: save2gdf${BINEXT} pu${BINEXT} biosig_fhir${BINEXT}
all:   first mex4o biosig4python sigviewer win32 win64 win32/sigviewer.exe win64/sigviewer.exe #biosig_client biosig_server mma java tcl perl php ruby #sigviewer 

.PHONY : libbiosig lib

libbiosig lib: $(LIB_OBJECTS)

#############################################################
#	Compilation: Implicit, default rules
#############################################################

vpath %.c ./:./t210:./t220:./test0:./src:./mma

vpath %.cpp ./:./t210:./t230:./XMLParser:./mex

.SUFFIXES: .o .c .cpp .cc .cxx .C


%.o: t240/%.c biosig.h biosig-dev.h gdftime.h physicalunits.h
	$(CC) -c $(DEFINES) $(CFLAGS) -I t240 $(INCPATH) -o "$@" "$<"

%.c: %.h biosig.h biosig-dev.h gdftime.h physicalunits.h

%.cpp: %.h  biosig.h biosig-dev.h gdftime.h physicalunits.h

%.o: %.c
	$(CC) -c $(DEFINES) $(CFLAGS)  $(INCPATH) -o "$@" "$<"

%.o : win32/%.c
	$(CC) -c $(DEFINES) $(CFLAGS)  $(INCPATH) -o "$@" "$<"

%.o: %.cpp  biosig.h biosig2.h biosig-dev.h
	$(CXX) -c $(DEFINES) $(CXXFLAGS) $(INCPATH) -o "$@" "$<"

sandbox.o: test0/sandbox.c  biosig.h biosig-dev.h
	$(CXX) -c $(DEFINES) $(CXXFLAGS) $(INCPATH) -o "$@" "$<"


win32/%.obj: t240/%.c  biosig-dev.h biosig.h 
	$(MinGWCC) -c $(DEFINES) $(MinGWCFLAGS) -I t240 -o "$@" "$<"
win32/%.obj: %.c
	$(MinGWCC) -c $(DEFINES) $(MinGWCFLAGS) -o "$@" "$<"
win32/%.obj: %.cpp
	$(MinGWCXX) -c $(DEFINES) $(MinGWCFLAGS) -o "$@" "$<"

win32/%.obj: win32/%.c 
	$(MinGWCC) -c $(DEFINES) $(MinGWCFLAGS) -I win32 -o "$@" "$<"


win64/%.obj: t240/%.c  biosig-dev.h biosig.h 
	$(MinGW64CC) -c $(DEFINES) $(MinGW64CFLAGS) -I t240 -o "$@" "$<"
win64/%.obj: %.c
	$(MinGW64CC) -c $(DEFINES) $(MinGW64CFLAGS) -o "$@" "$<"
win64/%.obj: %.cpp
	$(MinGW64CXX) -c $(DEFINES) $(MinGW64CFLAGS) -o "$@" "$<"

win64/%.obj: win32/%.c 
	$(MinGW64CC) -c $(DEFINES) $(MinGW64CFLAGS) -I win32 -o "$@" "$<"



#############################################################
#	eventcodes and units: conversion from ascii to C code
#############################################################

biosig.o win32/biosig.obj win64/biosig.obj: eventcodes.i eventcodegroups.i 11073-10102-AnnexB.i biosig.c biosig.h biosig-dev.h

physicalunits.o win32/physicalunits.obj win64/physicalunits.obj: units.i physicalunits.h 

eventcodes.i eventcodegroups.i : $(EXTERN)/eventcodes.txt
	gawk -f eventcodes.awk "$<"

units.i : $(EXTERN)/units.csv
	awk -f units.awk "$<" > "$@"

11073-10102-AnnexB.i : $(EXTERN)/11073-10102-AnnexB.txt
	awk -f annotatedECG.awk "$<" > "$@"


#############################################################
#	Compilation: exceptions, explicit rules
#############################################################

gdf.o: biosig.c biosig-dev.h biosig.h eventcodes.i units.i 11073-10102-AnnexB.i
	$(CC) -c -D=ONLYGDF -D=WITHOUT_NETWORK $(DEFINES) $(CFLAGS) $(INCPATH) -o "$@" "$<"

#getlogin_r.o: win32/getlogin_r.c
#	$(CC) -c $(DEFINES) $(CFLAGS) $(INCPATH) -o "$@" "$<"

########### WIN32 ##################

win32/gdf.obj: biosig.c biosig-dev.h biosig.h
	$(MinGWCC) -c -D=ONLYGDF $(DEFINES) $(MinGWCFLAGS) -o "$@" "$<"

$(PathToSigViewerWIN32): 
	svn co https://sigviewer.svn.sourceforge.net/svnroot/sigviewer/trunk ../sigviewer4win32

$(PathToSigViewerWIN32)/src/src.pro: $(PathToSigViewerWIN32)
	svn up -r 557 ../sigviewer4win32

win32/sigviewer.exe: win32/libbiosig.a win32/libbiosig.dll
	#-$(COPY) ../biosig/doc/eventcodes.txt $(PathToSigViewerWIN32)/src/
	-$(DELETE) $(PathToSigViewerWIN32)/extern/include/*.h
	-$(COPY) biosig.h physicalunits.h $(PathToSigViewerWIN32)/extern/include
	-$(DELETE) $(PathToSigViewerWIN32)/extern/lib/lib*
	-$(COPY) win32/libbiosig.a $(PathToSigViewerWIN32)/extern/lib
	$(SED) -i 's|\([[:space:]]*-lbiosig\)\([ #\\]*\)$$|\1 -lcholmod -lz -lcurl \2|' $(PathToSigViewerWIN32)/src/src.pro
	echo 0.5.2-v${BIOSIG_VERSION} > $(PathToSigViewerWIN32)/src/version.txt
	-(cd $(PathToSigViewerWIN32)/src; $(CROSS)-qmake; make)
	#-(cd $(PathToSigViewerWIN32); svn revert -R .; svn up -r 557; patch -p0 <../biosig4c++/patches/patch_sigviewer_0.5.2.diff; cd src; $(CROSS)-qmake; $(MAKE);)
	-$(COPY) $(PathToSigViewerWIN32)/bin/release/sigviewer.exe win32/sigviewer.exe

########### WIN64 ##################

win64/gdf.obj: biosig.c biosig-dev.h biosig.h
	$(MinGW64CC) -c -D=ONLYGDF $(DEFINES) $(MinGW64CFLAGS) -o "$@" "$<"

$(PathToSigViewerWIN64): 
	svn co https://sigviewer.svn.sourceforge.net/svnroot/sigviewer/trunk ../sigviewer4win64

$(PathToSigViewerWIN64)/src/src.pro: $(PathToSigViewerWIN64) 
	svn up -r 557 ../sigviewer4win64

win64/sigviewer.exe: win64/libbiosig.a win64/libbiosig.dll 
	#-$(COPY) ../biosig/doc/eventcodes.txt $(PathToSigViewerWIN64)/src/
	-$(DELETE) $(PathToSigViewerWIN64)/extern/include/*.h
	-$(COPY) biosig.h physicalunits.h $(PathToSigViewerWIN64)/extern/include
	-$(DELETE) $(PathToSigViewerWIN64)/extern/lib/lib*
	-$(COPY) win64/libbiosig.a $(PathToSigViewerWIN64)/extern/lib
	$(SED) -i 's|\([[:space:]]*-lbiosig\)\([ #\\]*\)$$|\1 -lcholmod -lz -lcurl\2|' $(PathToSigViewerWIN64)/src/src.pro
	echo 0.5.2-v${MAJOR_VERSION}.${MINOR_VERSION}.${STEPPING} > $(PathToSigViewerWIN64)/src/version.txt
	-(cd $(PathToSigViewerWIN64)/src; $(CROSS64)-qmake; make)
	#-(cd $(PathToSigViewerWIN64); svn revert -R .; svn up -r 557; patch -p0 <../biosig4c++/patches/patch_sigviewer_0.5.2.diff; cd src; $(CROSS64)-qmake; $(MAKE);)
	-$(COPY) $(PathToSigViewerWIN64)/bin/release/sigviewer.exe win64/sigviewer.exe


#############################################################
#	other language bindings (on Linux)
#############################################################

ifdef SWIG_BIOSIG4PYTHON
## this is the deprecated, swig-based interface definition
biosig4python : python/_biosig.so python/biosig.py python/_biosig2.so python/biosig2.py

python/biosig.py python/swig_wrap.cxx: python/biosig.i
	$(SWIG) -python  -I/usr/include/python$(PYTHONVER)/ -I$(NUMPY_INC) -o python/swig_wrap.cxx python/biosig.i
python/_biosig.so : python/swig_wrap.cxx  libbiosig.$(LIBEXT)
	$(CXX) -c $(DEFINES) $(CXXFLAGS) -I$(PYTHON_INCPATH) -I$(NUMPY_INC) python/swig_wrap.cxx -o python/swig_wrap.o
	$(CXX) -shared python/swig_wrap.o $(LFLAGS) $(LIBS) -lbiosig -lphysicalunits -l$(PYTHON_LIB) -o python/_biosig.so
python/biosig2.py python/biosig2_wrap.cxx: python/biosig2.i
	$(SWIG) -python  -I/usr/include/python$(PYTHONVER)/ -I$(NUMPY_INC) -o python/biosig2_wrap.cxx python/biosig2.i
python/_biosig2.so : python/biosig2_wrap.cxx  libbiosig2.$(LIBEXT)
	$(CXX) -c $(DEFINES) $(CXXFLAGS) -I$(PYTHON_INCPATH) -I$(NUMPY_INC) python/biosig2_wrap.cxx -o python/biosig2_wrap.o
	$(CXX) -shared python/biosig2_wrap.o $(LFLAGS) $(LIBS) -lbiosig2 -l$(PYTHON_LIB) -o python/_biosig2.so

python: libbiosig.$(LIBEXT) libbiosig2.$(LIBEXT) python/biosig.i python/biosig2.i
	$(MAKE) -C python 
else
## biosig4python based on module extensions
python:
	(cd  python && $(PYTHON) setup.py build)

install_python: libbiosig.$(LIBEXT) libbiosig2.$(LIBEXT)
	(cd  python && $(PYTHON) setup.py install)

endif


java: libbiosig.$(LIBEXT) java/biosig.i
	$(MAKE) -C java 
perl: libbiosig.$(LIBEXT) perl/biosig.i
	$(MAKE) -C perl 
php: libbiosig.$(LIBEXT) php/biosig.i
	$(MAKE) -C php 


ruby/biosig_wrap.c: ruby/biosig.i
	(cd ruby && swig -ruby biosig.i)
ruby/Makefile: ruby/extconf.rb
	ruby -C ruby extconf.rb
biosig4ruby ruby: libbiosig.$(LIBEXT) ruby/Makefile ruby/biosig_wrap.c
	$(MAKE) -C ruby 


tcl: libbiosig.$(LIBEXT) tcl/biosig.i
	$(MAKE) -C tcl 


#############################################################
#	WIN32 - BUILD
#############################################################

# libraries are built in MXE

## save2gdf, pdp2gdf, pu
win32/%.exe: %.c
	$(MinGWCXX) $(DEFINES) $(MinGWCFLAGS) "$<" $(MinGWLIBS) -o "$@"

win32: mexw32 win32mma



#############################################################
#	WIN64 - BUILD
#############################################################

# Libraries are build in MXE

## save2gdf, pdp2gdf, pu
win64/%.exe: %.c
	$(MinGW64CXX) $(DEFINES) $(MinGW64CFLAGS) "$<" $(MinGW64LIBS) -o "$@"

win64: mexw64



#############################################################
#	GNU/Linux - BUILD
#############################################################

t240/libcnsfef.a:
#	$(MAKE) -C t240 regen		#
	$(MAKE) -C t240 libcnsfef.a CC=$(CC) AR='$(AR)'	# generate t240/*.o files

libbiosig.${FULLDLEXT}: $(OBJECTS) biosig.o t240/libcnsfef.a
	$(LD) ${SONAME_PREFIX}libbiosig${SONAME_POSTFIX} $(OBJECTS) t240/*.o $(LDFLAGS) $(LIBS) -o "$@"

libbiosig2.${FULLDLEXT}: $(OBJECTS)  biosig2.o t240/libcnsfef.a
	$(LD) ${SONAME_PREFIX}libbiosig2${SONAME_POSTFIX} $(OBJECTS) biosig2.o t240/*.o $(LDFLAGS) $(LIBS) -o "$@"

libgdf.${FULLDLEXT}: gdf.o getlogin.o gdftime.o physicalunits.o
	$(LD) ${SONAME_PREFIX}libgdf${SONAME_POSTFIX} $? $(LDFLAGS) $(LIBS) -o "$@"

libgdftime.${FULLDLEXT}: gdftime.o
	$(LD) ${SONAME_PREFIX}libgdftime${SONAME_POSTFIX} $? $(LDFLAGS) $(LIBS) -o "$@"
libphysicalunits.${FULLDLEXT}: physicalunits.o
	$(LD) ${SONAME_PREFIX}libgdftime${SONAME_POSTFIX} $? $(LDFLAGS) $(LIBS) -o "$@"

%.${DLEXT}: %.${FULLDLEXT}
	ln -sf "$(*F).${FULLDLEXT}"	"$(*F)${SONAME_POSTFIX}"
	ln -sf "$(*F)${SONAME_POSTFIX}"	"$@"

libphysicalunits.a: physicalunits.o
	-$(DELETE) "$@"
	$(AR) "$@" "$<"
libphysicalunits.def: physicalunits.o
	$(CXX) -o libphysicalunits.dll -s -shared -fPIC "$<" $(LIBS) -Wl,--subsystem,windows,--output-def,libphysicalunits.def,--out-implib,libphysicalunits.dll.a

libgdftime.a: gdftime.o
	-$(DELETE) "$@"
	$(AR) "$@" "$<"
libgdftime.def: gdftime.o
	$(CC) -o libgdftime.dll -s -shared -fPIC "$@" -Wl,--subsystem,windows,--output-def,libgdftime.def,--out-implib,libgdftime.dll.a

libgdf.a: gdf.o getlogin.o gdftime.o physicalunits.o
	-$(DELETE) "$@"
	$(AR) "$@" gdf.o getlogin.o gdftime.o physicalunits.o
libgdf.def: gdf.o getlogin.o gdftime.o physicalunits.o
	$(CXX) -s -shared -fPIC -o libgdf.dll gdf.o getlogin.o gdftime.o physicalunits.o $(LIBS) -Wl,--subsystem,windows,--output-def,libgdf.def,--out-implib,libgdf.dll.a

libbiosig.a: $(OBJECTS) t240/libcnsfef.a libbiosig.pc
	-$(DELETE) libbiosig.a
	$(AR) libbiosig.a $(OBJECTS) t240/*.o
libbiosig.def: $(OBJECTS) t240/libcnsfef.a libbiosig.pc
	$(CXX) -o libbiosig.dll -s -shared -fPIC  $(OBJECTS) t240/libcnsfef.a $(LIBS) -Wl,--subsystem,windows,--output-def,libbiosig.def,--out-implib,libbiosig.dll.a

libbiosig.pc :
	mkdir -p pkgconfig
	echo "# Defines libbiosig.pc"       > "$@"
	echo "prefix=$(PREFIX)"             >>"$@"
	echo "exec_prefix=$(PREFIX)"        >>"$@"
	echo "libdir=$(PREFIX)/lib"         >>"$@"
	echo "includedir=$(PREFIX)/include" >>"$@"
	echo                                >>"$@"
	echo "Name: libbiosig"		    >>"$@"
	echo "Description: Biosig library"  >>"$@"
	echo "Version: ${MAJOR_VERSION}.${MINOR_VERSION}.${STEPPING}" >>"$@"
	echo "URL: http://biosig.sf.net"    >>"$@"
	echo "Libs: -L$(LIB) -lbiosig $(LDLIBS)"  >>"$@"
	#echo "Libs.private: -liconv"  >>"$@"
	echo "Cflags: $(DEFINES) -I$(INC)" >>"$@"

libbiosig2.a: $(OBJECTS) biosig2.o t240/libcnsfef.a
	-$(DELETE) libbiosig2.a
	$(AR) libbiosig2.a $(OBJECTS) biosig2.o t240/*.o
libbiosig2.def: $(OBJECTS) biosig2.o t240/libcnsfef.a
	$(LD) -o libbiosig2.dll -s -shared -fPIC  $(OBJECTS) biosig2.o t240/libcnsfef.a $(LIBS) -Wl,--subsystem,windows,--output-def,libbiosig2.def,--out-implib,libbiosig2.dll.a


## save2gdf, pdp2gdf
%${BINEXT}: %.c
	$(CXX) $(DEFINES) $(CXXFLAGS) "$<" $(shell $(PKGCONF) --libs libbiosig) -o "$@"
	#$(CXX) $(DEFINES) $(CXXFLAGS) "$<" -L. libbiosig.a -lz -lcholmod -o "$@"

pu${BINEXT} : pu.c physicalunits.o
	$(CC) $(DEFINES) $(CFLAGS) $^  $(shell $(PKGCONF) --libs libbiosig) -o "$@"

biosig_fhir${BINEXT}: biosig_fhir.c
	$(CC) $(DEFINES) $(CFLAGS) $^ -lb64 $(shell $(PKGCONF) --libs libbiosig) -lstdc++ -o "$@"

bscs: biosig_client{BINEXT} biosig_server{BINEXT} sandbox.o biosig.o
biosig_client${BINEXT}: biosig_client.c libbiosig.$(LIBEXT) biosig-network.o
	$(CXX) $(DEFINES) $(CXXFLAGS) biosig_client.c biosig-network.o libbiosig.$(LIBEXT) $(LFLAGS) $(LIBS) -o "$@"

biosig_server${BINEXT}: biosig_server.c libbiosig.$(LIBEXT) biosig-network.o
	$(CXX) $(DEFINES) $(CXXFLAGS) biosig_server.c biosig-network.o libbiosig.$(LIBEXT) $(LFLAGS) $(LIBS) -o "$@"


#############################################################
#	MathLink interface to Mathematica
#############################################################

mmaall: mma/sload.tm mma/sload.c
	$(MAKE) -C mma CROSS=$(CROSS) CROSS64=$(CROSS64) LDLIBS="$(LDLIBS) -liconv" all

mma : mma/sload.exe

mma/sload.exe: mma/sload.tm mma/sload.c
	$(MAKE) -C mma CROSS=$(CROSS) CROSS64=$(CROSS64) LDLIBS="$(LDLIBS) -liconv" mma

win32mma: mma/sload.tm mma/sload.c
	$(MAKE) -C mma CROSS=$(CROSS) LDLIBS="$(LDLIBS) -liconv" win32mma

win64mma: mma/sload.tm mma/sload.c
	$(MAKE) -C mma CROSS64=$(CROSS64) LDLIBS="$(LDLIBS) -liconv" win64mma


#############################################################
#	MEX-files for Octave and Matlab
#############################################################

# include directory for Win32-Matlab include
W32MAT_INC = $(HOME)/bin/win32/Matlab/R2010b/extern/include/ -I../win32
W64MAT_INC = $(HOME)/bin/win64/Matlab/R2010b/extern/include/ -I../win64
# path to GNUMEX libraries, available from here http://sourceforge.net/projects/gnumex/
GNUMEX   = $(HOME)/bin/win32/gnumex
GNUMEX64 = $(HOME)/bin/win64/gnumex

mex/mexSOPEN.cpp : mex/mexSLOAD.cpp
	echo "#define mexSOPEN" > mex/mexSOPEN.cpp
	cat mex/mexSLOAD.cpp >> mex/mexSOPEN.cpp

MEX_OBJECTS = mex/mexSLOAD.cpp mex/mexSOPEN.cpp mex/mexSSAVE.cpp

mex4o: $(patsubst mex/%.cpp, mex/%.mex, $(MEX_OBJECTS))
oct: $(patsubst mex/%.cpp, mex/%.oct, $(MEX_OBJECTS))
mexw32: $(patsubst mex/%.cpp, mex/%.mexw32, $(MEX_OBJECTS))
mexw64: $(patsubst mex/%.cpp, mex/%.mexw64, $(MEX_OBJECTS))

ifdef MEX_EXT
mex: mex4o mex4m mexw32 mexw64
mex4m: $(patsubst mex/%.cpp, mex/%.$(MEX_EXT), $(MEX_OBJECTS))

ifneq (Darwin,$(shell uname))
mex/%.$(MEX_EXT): mex/%.cpp
	$(MEX) $(MEX_OPTION) $(DEFINES) "$<" $(shell $(PKGCONF) --libs libbiosig) -output "$@"
else
mex/%.$(MEX_EXT): mex/%.cpp
	## $(MEX) $(MEX_OPTION) $(DEFINES) "$<" $(shell $(PKGCONF) --libs libbiosig) -o "$@"
	$(MEX) $(DEFINES) -outdir mex "$<" libbiosig.dylib
endif
	-$(COPY) $@ ../biosig4matlab/t200_FileAccess/

else
mex: mex4o mexw32 mexw64
endif

mex/%.mex: mex/%.cpp
	$(OCT) $(DEFINES) -v -g --mex "$<" -Wl,-rpath,$(shell pwd) -I./ -L./ -lbiosig $(LIBS) -o "$@"
	-$(COPY) $@ ../biosig4matlab/t200_FileAccess/

mex/%.oct: mex/%.cpp
	$(OCT) $(DEFINES) "$<" -Wl,-rpath,$(shell pwd) -I./ -L./ -lbiosig $(LIBS) -o "$@"
	-$(COPY) $@ ../biosig4matlab/t200_FileAccess/

mex/%.mexw32: mex/%.cpp Makefile biosig.h biosig-dev.h
	## $(CROSS)-g++ is used instead of $(CXX), so it can be called from biosig as well as mxe. 
	$(CROSS)-g++ -shared $(GNUMEX)/mex.def -DMATLAB_MEX_FILE $(DEFINES) -x c++  \
		-I$(W32MAT_INC) -O2 -o "$@" -L$(GNUMEX) -s "$<" -llibmx -llibmex -lbiosig -liconv -lssp $(LDLIBS) -lws2_32
	-$(COPY) $@ ../biosig4matlab/t200_FileAccess/

mex/%.mexw64: mex/%.cpp Makefile biosig.h biosig-dev.h
	$(CROSS64)-g++ -shared $(GNUMEX64)/mex.def -DMATLAB_MEX_FILE $(DEFINES) -x c++  \
		-I$(W64MAT_INC) -O2 -o "$@" -L$(GNUMEX64) -s "$<" -llibmx -llibmex -lbiosig -liconv -lssp $(LDLIBS) -lws2_32
	-$(COPY) $@ ../biosig4matlab/t200_FileAccess/

mexbiosig: mex/mexbiosig-$(BIOSIG_VERSION).src.tar.gz

mex/mexbiosig-$(BIOSIG_VERSION).src.tar.gz: mex/*.cpp
	$(eval $@_TMP := $(shell mktemp -d /tmp/biosig.XXXXXX)/mexbiosig-$(BIOSIG_VERSION))
	echo "$($@_TMP) generated";
	$(shell mkdir -p $($@_TMP)/doc/)
	$(shell mkdir -p $($@_TMP)/inst/)
	$(shell mkdir -p $($@_TMP)/src/)
	cp mex/README $($@_TMP)/doc/
	sed -e 's#^Version.*$$#Version: $(BIOSIG_VERSION)#g' -e 's#^Date.*$$#Date: '$(shell date +%Y-%m-%d)'#g' mex/DESCRIPTION > $($@_TMP)/DESCRIPTION
	cp LICENSE $($@_TMP)/COPYING
	cp mex/mex*.cpp mex/Makefile $($@_TMP)/src/
	### TODO
	#touch $($@_TMP)/src/mex{SOPEN,SLOAD,SSAVE}.m
	echo "mexSLOAD mexSOPEN mexSSAVE" > $($@_TMP)/INDEX
	$(TAR) cvfz "$@" $($@_TMP)/../mexbiosig-$(BIOSIG_VERSION)
	-(cp "$@" ~/L/public_html/biosig/prereleases/ )
	-rm -rf $(shell dirname $($@_TMP) )

#############################################################
#	SigViewer
#############################################################

sigviewer: $(PathToSigViewer)/bin/sigviewer 
	$(COPY) $(PathToSigViewer)/bin/release/sigviewer bin/sigviewer-$(TODAY)
	ln -sf sigviewer-$(TODAY) bin/sigviewer 

$(PathToSigViewer): 
	svn co https://sigviewer.svn.sourceforge.net/svnroot/sigviewer/trunk ../sigviewer

$(PathToSigViewer)/src/src.pro: $(PathToSigViewer) 
	svn up -r 557 ../sigviewer

$(PathToSigViewer)/bin/sigviewer: libbiosig.$(LIBEXT) biosig.h
	-$(DELETE) $(PathToSigViewer)/extern/include/*
	-$(COPY) biosig.h physicalunits.h $(PathToSigViewer)/extern/include
	-$(DELETE) $(PathToSigViewer)/extern/lib/lib*
	-$(COPY) libbiosig.a $(PathToSigViewer)/extern/lib
	$(SED) -i 's|\([[:space:]]*-lbiosig\)\([ #\\]*\)$$|\1 $(LDLIBS) \2|' $(PathToSigViewer)/src/src.pro
	echo 0.5.2-v${BIOSIG_VERSION} > $(PathToSigViewer)/src/version.txt
	(cd $(PathToSigViewer)/src; qmake; $(MAKE);)
	#-(cd $(PathToSigViewer); svn revert -R .; svn up -r 557; patch -p0 <../biosig4c++/patches/patch_sigviewer_0.5.2.diff; cd src; qmake; $(MAKE);)
	-$(COPY) $(PathToSigViewer)/bin/release/sigviewer bin/sigviewer

docs: 	docs/save2gdf.txt  docs/mexSLOAD.txt
	asciidoc -d manpage docs/save2gdf.txt
	asciidoc -d manpage docs/mexSLOAD.txt


# for backward compatibility
save2scp: save2gdf
save2aecg: save2gdf


#############################################################
#	APPLICATIONS: TTL2TRIG, FLOWMON
#############################################################

###	TTL2TRIG
bin/ttl2trig : src/ttl2trig.c gdf.o physicalunits.o
	$(CXX) -D=WITH_BIOSIG $(DEFINE) $(CFLAGS) "$^" -Wall -Wextra -lasound -o "$@"

###	FLOWMON
flowmon.o: src/flowmon2.c 
	$(CC)  -c $(DEFINES) $(CFLAGS) -o "$@" "$<"
        
bin/flowmon: flowmon.o gdf.o physicalunits.o
	$(CC) "$^" -lpthread -lm -o "$@"


#############################################################
#	INSTALL and DE-INSTALL
#############################################################

.PHONY: clean distclean install remove install_sigviewer asc bin testscp testhl7 testbin test test6 zip

distclean: clean
	-$(DELETE) -r autom4te.cache
	-$(DELETE) aclocal.m4 config.guess config.h config.h.in config.log config.sub config.status depcomp missing stamp-h1
	-$(DELETE) Makefile.am doc/Makefile.am mex/Makefile.am python/Makefile.am
	-$(DELETE) install-sh ltmain.sh
	-$(DELETE) *.lib
	-$(DELETE) *.so *.dylib
	-$(DELETE) *.so.*
	-$(DELETE) mex/mexSOPEN.cpp
	-$(DELETE) libbiosig.pc
	-$(DELETE) t5.scp t6.scp save2gdf gztest test_scp_decode biosig_server biosig_client
	-$(DELETE) t?.[bge]df* t?.hl7* t?.scp* t?.cfw* t?.gd1* t?.*.gz *.fil $(TEMP_DIR)t1.* $(DATA_DIR)t1.*
	-$(DELETE) python/swig_wrap.* python/biosig.py* python/_biosig.so python/biosig2.py* python/_biosig2.so
	-$(DELETE) python/*_wrap.*
	-$(DELETE) QMakefile
	-$(DELETE) igor/libIgor.a
	-$(DELETE) win32/*.a win32/*.lib win32/libbiosig.* win32/*.obj win32/*.exe
	-$(DELETE) win64/*.a win64/*.lib win64/libbiosig.* win64/*.obj win64/*.exe
	-$(DELETE) -rf win32/zlib
	-$(DELETE) mex/*.o mex/*.obj mex/*.o64 mex/core mex/octave-core mex/*.oct mex/*~ mex/*.mex* 
	-$(MAKE) -C java clean
	-$(MAKE) -C matlab clean
	-$(MAKE) -C mma clean
	-$(MAKE) -C php clean
	-$(MAKE) -C perl clean
	-$(MAKE) -C ruby clean
	-$(MAKE) -C tcl clean

clean:
	-$(DELETE) *~
	-$(DELETE) *.a
	-$(DELETE) *.def
	-$(DELETE) *.dll
	-$(DELETE) *.dll.a
	-$(DELETE) *.i
	-$(DELETE) *.o
	-$(DELETE) *.so *.dylib
	-$(DELETE) *.so.*
	-$(DELETE) *.mex*
	-$(DELETE) *.oct
	-$(DELETE) libbiosig.pc
	-$(DELETE) $(TEMP_DIR)t1.*
	-$(DELETE) python/biosig.py* _biosig.so python/biosig2.py* _biosig2.so
	-$(DELETE) python/swig_wrap.* python/biosig2_wrap.*
	-$(DELETE) win32/*.exe win32/*.o* win32/*.lib win32/*.a
	-$(DELETE) win64/*.exe win64/*.o* win64/*.lib win64/*.a
	-$(DELETE) t240/*.o*
	-$(DELETE) t240/libcnsfef.a
	-$(DELETE) libbiosig.* libbiosig2.*
	-$(DELETE) pdp2gdf save2gdf pu
	-$(DELETE) mex/*.o mex/*.obj mex/*.o64 mex/core mex/octave-core mex/*.oct mex/*~ mex/*.mex* 
	-$(MAKE) -C java clean
	-$(MAKE) -C matlab clean
	-$(MAKE) -C mma clean
	-$(MAKE) -C php clean
	-$(MAKE) -C perl clean
	-$(MAKE) -C ruby clean
	-$(MAKE) -C tcl clean

install_sigviewer: sigviewer
	install $(PathToSigViewer)/bin/release/sigviewer $(BIN)

install_ttl2trig: bin/ttl2trig
	install bin/ttl2trig $(BIN)

install_headers: biosig-dev.h biosig.h biosig2.h gdftime.h physicalunits.h
	install -d 			$(INC)
	install $?		    	$(INC)

install_libbiosig.a: libbiosig.a libbiosig2.a libphysicalunits.a libgdftime.a
	install -d 			$(LIB)/pkgconfig/
	install $?			$(LIB)
	install libbiosig.pc		$(LIB)/pkgconfig/

install_libbiosig.$(DLEXT): libbiosig2.$(FULLDLEXT) libbiosig.$(FULLDLEXT) libphysicalunits.$(DLEXT) libgdftime.$(DLEXT) libbiosig.pc
	install -d 			$(LIB)/pkgconfig/
	install libbiosig.pc		$(LIB)/pkgconfig/
	install $?			$(LIB)

install: install_libbiosig.$(DLEXT) install_libbiosig.a install_headers
	ln -sf $(LIB)/libbiosig2.${FULLDLEXT}	$(LIB)/libbiosig2${SONAME_POSTFIX}
	ln -sf $(LIB)/libbiosig.${FULLDLEXT}	$(LIB)/libbiosig${SONAME_POSTFIX}
	ln -sf $(LIB)/libbiosig2${SONAME_POSTFIX}	$(LIB)/libbiosig2.${DLEXT}
	ln -sf $(LIB)/libbiosig${SONAME_POSTFIX}	$(LIB)/libbiosig.${DLEXT}

install_tools: pu${BINEXT} save2gdf${BINEXT} biosig_fhir${BINEXT} doc/save2gdf.1 install
	install -d 			$(BIN)
	install save2gdf${BINEXT}	$(BIN)
	install heka2itx  		$(BIN)
	install save2aecg 		$(BIN)
	install save2scp  		$(BIN)
	install pu${BINEXT}		$(BIN)
	install biosig_fhir${BINEXT}	$(BIN)
	mkdir -p  			$(DESTDIR)$(prefix)/share/man/man1
	install doc/*.1  		$(DESTDIR)$(prefix)/share/man/man1
	#install libbiosig.man 		$(DESTDIR)$(prefix)/share/
	#$(MAKE)  install_sigviewer
	#$(MAKE)  install_octave

uninstall_tools:
	${RM} $(BIN)/save2gdf${BINEXT}
	${RM} $(BIN)/pu${BINEXT}
	${RM} $(BIN)/heka2itx
	${RM} $(BIN)/save2aecg
	${RM} $(BIN)/save2scp
	${RM} $(BIN)/biosig_fhir${BINEXT}
	${RM} $(DESTDIR)$(prefix)/share/man/man1/pu.1
	${RM} $(DESTDIR)$(prefix)/share/man/man1/save2gdf.1
	${RM} $(DESTDIR)$(prefix)/share/man/man1/heka2itx.1

### Install mexbiosig for Octave
install_mexbiosig install_octave: mex/mexbiosig-$(BIOSIG_VERSION).src.tar.gz
	PKG_CONFIG_LIBDIR=$(LIB)/pkgconfig octave$(VERSION) --eval "pkg install $<"

uninstall_mexbiosig:
	PKG_CONFIG_LIBDIR=$(LIB)/pkgconfig octave$(VERSION) --eval "pkg uninstall mexbiosig"

### Install mexbiosig for Matlab and Octave
install_mex: mex4m mex4o
	mkdir -p $(SHARE)/biosig/mex
	install mex/mex*.mex*	$(SHARE)/biosig/mex
	@echo "  mexBiosig for Matlab is installed in $(SHARE)/biosig/mex";
	@echo "  Usage: Start Matlab and addpath ";
	@echo "\taddpath(\"$(SHARE)/biosig/mex)";
	@echo "\tmexSLOAD";

uninstall_mex:
	${RM} $(SHARE)/biosig/mex/*
	cd $(SHARE) && rmdir -p biosig/mex

### Install Biosig for Mathematica
install_mma : mma/sload.exe
	mkdir -p $(SHARE)/biosig/mathematica
	install mma/sload.exe	$(SHARE)/biosig/mathematica/
	@echo "  Biosig for Mathematica is installed in $(SHARE)/biosig/mathematica/sload.exe";
	@echo "  Usage: Start Mathematica and run";
	@echo "\tlink=Install[\"$(SHARE)/biosig/mathematica/sload.exe\"];";
	@echo "\t?sload";

uninstall_mma:
	${RM} $(SHARE)/biosig/mathematica/sload.exe
	cd $(SHARE) && rmdir -p biosig/mathematica

uninstall remove: uninstall_mexbiosig uninstall_tools
	-$(DELETE) $(BIN)/ttl2trig
	#-$(DELETE) $(BIN)/rec2bin
	#-$(DELETE) $(BIN)/bin2rec
	-$(DELETE) $(BIN)/sigviewer
	-$(DELETE) $(BIN)/eventcodes.txt
	-$(DELETE) $(INC)/biosig.h
	-$(DELETE) $(INC)/biosig-dev.h
	-$(DELETE) $(INC)/biosig2.h
	-$(DELETE) $(INC)/gdftime.h
	-$(DELETE) $(INC)/physicalunits.h
	-$(DELETE) $(LIB)/libbiosig.*
	-$(DELETE) $(LIB)/libbiosig2.*
	-$(DELETE) $(LIB)/libphysicalunits.*
	-$(DELETE) $(LIB)/libgdftime.*
	-$(DELETE) $(LIB)/pkgconfig/libbiosig.pc


#############################################################
#	Testing
#############################################################
testtms: $(DATA_DIR)t1.scp
#	./save2gdf -V8 ~/data/test/tms32/small_test.float32.log
	./save2gdf -f=TMSi $(DATA_DIR)t1.scp $(TEMP_DIR)t2.log
	cat $(TEMP_DIR)t2.log

fetchdata: $(TEMP_DIR)scp/redred/PFE103.scp  $(TEMP_DIR)Osas2002plusQRS.edf $(DATA_DIR)Newtest17-2048.bdf $(DATA_DIR)2003-12\ Schema/example/Example\ aECG.xml

$(TEMP_DIR)scp/redred/PFE103.scp:
	# scp example data sets
	#wget  -q -P$(DATA_DIR) http://www.openecg.net/ECGsamples.zip
	#wget  -q -P$(DATA_DIR) http://www.openecg.net/ECGsamplesc.zip
	unzip -u $(DATA_DIR)ECGsamples.zip "scp*.zip" -d $(TEMP_DIR)
	unzip -u $(DATA_DIR)ECGsamplesc.zip "scp*.zip" -d $(TEMP_DIR)
	mkdir -p $(TEMP_DIR)scp/high
	mkdir -p $(TEMP_DIR)scp/highc
	mkdir -p $(TEMP_DIR)scp/redred
	mkdir -p $(TEMP_DIR)scp/redredc
	unzip -u $(TEMP_DIR)scp_high.zip -d $(TEMP_DIR)scp/high
	unzip -u $(TEMP_DIR)scp_highc.zip -d $(TEMP_DIR)scp/highc
	unzip -u $(TEMP_DIR)scp_redred.zip -d $(TEMP_DIR)scp/redred
	unzip -u $(TEMP_DIR)scp_redredc.zip -d $(TEMP_DIR)scp/redredc
	rm -rf $(TEMP_DIR)ECGsamples*.zip
	rm -rf $(TEMP_DIR)scp*.zip

$(DATA_DIR)t1.scp: $(TEMP_DIR)scp/redred/PFE103.scp
	$(COPY) "$<" "$@"
	touch "$@"

#"$(DATA_DIR)aECG Release 1 Schema and Example.zip":
$(DATA_DIR)2003-12\ Schema/example/Example\ aECG.xml:
	# HL7aECG example data set
	wget -q -P$(DATA_DIR) https://www.hl7.org/documentcenter/public/wg/rcrim/annecg/aECG%20Release%201%20Schema%20and%20Example.zip
	unzip -u $(DATA_DIR)"aECG Release 1 Schema and Example.zip" -d $(DATA_DIR)

$(TEMP_DIR)t1.hl7: $(DATA_DIR)2003-12\ Schema/example/Example\ aECG.xml
	$(COPY) "$<" "$@"
	#rm -rf "$(TEMP_DIR)aECG Release 1 Schema and Example.zip"
	#rm -rf "$(TEMP_DIR)2003-12 Schema"

$(TEMP_DIR)Osas2002plusQRS.edf:
	# EDF+ example data set
	wget -q -P$(TEMP_DIR) http://www.edfplus.info/downloads/files/osas.zip
	unzip -u "$(TEMP_DIR)osas.zip"  -d $(TEMP_DIR)

$(DATA_DIR)t1.edf: $(TEMP_DIR)Osas2002plusQRS.edf
	$(COPY) "$<" "$@"
	touch "$@"

asc: save2gdf
	./save2gdf -f=ASCII t0.xxx $(TEMP_DIR)t1.asc

bin: save2gdf
	./save2gdf -f=BIN t0.xxx $(TEMP_DIR)t1.bin

testjson: save2gdf  $(DATA_DIR)t1.edf
	./save2gdf -JSON t0.xxx |tee $(TEMP_DIR)t1.xxx.json
	./save2gdf -JSON  $(TEMP_DIR)t1.edf |tee $(TEMP_DIR)t1.edf.json

testbin: save2gdf $(DATA_DIR)t1.edf
	./save2gdf -f=BIN $(DATA_DIR)t1.edf $(TEMP_DIR)t1.hdr
	./save2gdf -f=BIN $(TEMP_DIR)t1.hdr $(TEMP_DIR)t2.hdr
	./save2gdf -f=GDF $(TEMP_DIR)t2.hdr $(TEMP_DIR)t2.gdf

testedf: save2gdf $(TEMP_DIR)Osas2002plusQRS.edf
	./save2gdf -f=GDF $(TEMP_DIR)Osas2002plusQRS.edf $(TEMP_DIR)Osas2002plusQRS.gdf

testscp: $(DATA_DIR)t1.scp save2gdf
	# test converting SCP data
	./save2gdf -f=HL7 "$<" $(TEMP_DIR)t1.scp.hl7
	./save2gdf -f=GDF $(TEMP_DIR)t1.scp.hl7 $(TEMP_DIR)t1.scp.hl7.gdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.scp.hl7.gdf $(TEMP_DIR)t1.scp.hl7.gdf.scp
	./save2gdf -f=GDF $(TEMP_DIR)t1.scp.hl7.gdf.scp $(TEMP_DIR)t1.scp.hl7.gdf.scp.gdf
	./save2gdf -f=HL7 $(TEMP_DIR)t1.scp.hl7.gdf.scp.gdf $(TEMP_DIR)t1.scp.hl7.gdf.scp.gdf.hl7
	./save2gdf -f=SCP $(TEMP_DIR)t1.scp.hl7.gdf.scp.gdf.hl7 $(TEMP_DIR)t1.scp.hl7.gdf.scp.gdf.hl7.scp
	./save2gdf -f=GDF "$<" $(TEMP_DIR)t1.scp.gdf
	./save2gdf -f=HL7 $(TEMP_DIR)t1.scp.gdf $(TEMP_DIR)t1.scp.gdf.hl7
	./save2gdf -f=SCP $(TEMP_DIR)t1.scp.gdf.hl7 $(TEMP_DIR)t1.scp.gdf.hl7.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.scp.gdf.hl7.scp $(TEMP_DIR)t1.scp.gdf.hl7.scp.hl7
	./save2gdf -f=GDF $(TEMP_DIR)t1.scp.gdf.hl7.scp.hl7 $(TEMP_DIR)t1.scp.gdf.hl7.scp.hl7.gdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.scp.gdf.hl7.scp.hl7.gdf $(TEMP_DIR)t1.scp.gdf.hl7.scp.hl7.gdf.scp

testscp2: $(DATA_DIR)t1.scp
	find test/scp -iname '*.scp' -exec ./save2gdf -V0 {} /dev/null \;

testscp3: $(DATA_DIR)t1.scp
	find test/scp -iname '*.scp' -exec ./save2gdf -f=SCP3 -V0 {} {}.scp3  \;

testhl7: $(TEMP_DIR)t1.hl7 save2gdf
	# test converting HL7aECG data
	./save2gdf -f=GDF "$<" $(TEMP_DIR)t1.hl7.gdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.hl7.gdf $(TEMP_DIR)t1.hl7.gdf.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.hl7.gdf.scp $(TEMP_DIR)t1.hl7.gdf.scp.hl7
	./save2gdf -f=SCP $(TEMP_DIR)t1.hl7.gdf.scp.hl7 $(TEMP_DIR)t1.hl7.gdf.scp.hl7.scp
	./save2gdf -f=GDF $(TEMP_DIR)t1.hl7.gdf.scp.hl7.scp $(TEMP_DIR)t1.hl7.gdf.scp.hl7.scp.gdf
	./save2gdf -f=HL7 $(TEMP_DIR)t1.hl7.gdf.scp.hl7.scp.gdf $(TEMP_DIR)t1.hl7.gdf.scp.hl7.scp.gdf.hl7
	./save2gdf -f=SCP "$<" $(TEMP_DIR)t1.hl7.scp
	./save2gdf -f=GDF $(TEMP_DIR)t1.hl7.scp $(TEMP_DIR)t1.hl7.scp.gdf
	./save2gdf -f=HL7 $(TEMP_DIR)t1.hl7.scp.gdf $(TEMP_DIR)t1.hl7.scp.gdf.hl7
	./save2gdf -f=GDF $(TEMP_DIR)t1.hl7.scp.gdf.hl7 $(TEMP_DIR)t1.hl7.scp.gdf.hl7.gdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.hl7.scp.gdf.hl7.gdf $(TEMP_DIR)t1.hl7.scp.gdf.hl7.gdf.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.hl7.scp.gdf.hl7.gdf.scp $(TEMP_DIR)t1.hl7.scp.gdf.hl7.gdf.scp.hl7

test: $(DATA_DIR)t1.scp save2scp save2aecg save2gdf
	# biosig4python
	# includes test for on-the-fly compression and decompression
	./save2gdf -z  $(DATA_DIR)t1.scp        $(TEMP_DIR)t1.scp.gdf
	./save2gdf -f=SCP -z 	$(DATA_DIR)t1.scp        $(TEMP_DIR)t1.scp.scp
	./save2gdf -f=HL7 -z	$(DATA_DIR)t1.scp        $(TEMP_DIR)t1.scp.hl7
	./save2gdf 	$(TEMP_DIR)t1.scp.gdf.gz $(TEMP_DIR)t1.scp.gdf.gdf
	./save2gdf 	$(TEMP_DIR)t1.scp.scp.gz $(TEMP_DIR)t1.scp.scp.gdf
	./save2gdf 	$(TEMP_DIR)t1.scp.hl7.gz $(TEMP_DIR)t1.scp.hl7.gdf
	./save2gdf -f=SCP 	$(TEMP_DIR)t1.scp.gdf.gz $(TEMP_DIR)t1.scp.gdf.scp
	./save2gdf -f=SCP 	$(TEMP_DIR)t1.scp.scp.gz $(TEMP_DIR)t1.scp.scp.scp
	./save2gdf -f=SCP 	$(TEMP_DIR)t1.scp.hl7.gz $(TEMP_DIR)t1.scp.hl7.scp
	./save2gdf -f=HL7	$(TEMP_DIR)t1.scp.gdf.gz $(TEMP_DIR)t1.scp.gdf.hl7
	./save2gdf -f=HL7	$(TEMP_DIR)t1.scp.scp.gz $(TEMP_DIR)t1.scp.scp.hl7
	./save2gdf -f=HL7	$(TEMP_DIR)t1.scp.hl7.gz $(TEMP_DIR)t1.scp.hl7.hl7
	# python test0/test.py

zip: $(DATA_DIR)t1.scp save2gdf
	# test for on-the-fly compression and decompression
	# on-the-fly compression of output file
	./save2gdf -z -f=GDF $(DATA_DIR)t1.scp $(TEMP_DIR)t1.gdf
	./save2gdf -z -f=GDF1 $(DATA_DIR)t1.scp $(TEMP_DIR)t1.gd1
	./save2gdf -z -f=EDF $(DATA_DIR)t1.scp $(TEMP_DIR)t1.edf
	./save2gdf -z -f=BDF $(DATA_DIR)t1.scp $(TEMP_DIR)t1.bdf
	./save2gdf -z -f=SCP $(DATA_DIR)t1.scp $(TEMP_DIR)t1.scp
	./save2gdf -z -f=CFWB $(DATA_DIR)t1.scp $(TEMP_DIR)t1.cfw
	./save2gdf -z -f=MFER $(DATA_DIR)t1.scp $(TEMP_DIR)t1.mwf
	./save2gdf -z -f=HL7 $(DATA_DIR)t1.scp $(TEMP_DIR)t1.hl7

	gzip -c $(DATA_DIR)t1.scp >$(TEMP_DIR)t1.scp.gz
	# on-the-fly decompression of input file
	./save2gdf -f=GDF $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.hl7
	./save2gdf -f=MFER $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.mwf
	./save2gdf -f=CFWB $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t1.cfw

test6: $(DATA_DIR)t1.scp save2gdf
	$(COPY) $(DATA_DIR)t1.scp $(TEMP_DIR)t0.xxx
	#test7: $(DATA_DIR)t1.edf save2gdf
	#$(COPY) $(DATA_DIR)t1.edf $(TEMP_DIR)t0.xxx
	./save2gdf -z -f=GDF1 $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.gd1
	./save2gdf -z -f=GDF $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.gdf
	./save2gdf -z -f=EDF $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.edf
	./save2gdf -z -f=BDF $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.bdf
	./save2gdf -z -f=SCP $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.scp
	./save2gdf    -f=HL7 $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.hl7   # -z not supported for HL7
	gzip -f $(TEMP_DIR)t1.hl7
	./save2gdf -z -f=CFWB $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.cfw
	./save2gdf -z -f=MFER $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.mwf
	./save2gdf -f=BVA $(TEMP_DIR)t0.xxx $(TEMP_DIR)t1.bva
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.hl7
	./save2gdf -f=CFWB $(TEMP_DIR)t1.gd1.gz $(TEMP_DIR)t2.gd1.cfw
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.hl7
	./save2gdf -f=CFWB $(TEMP_DIR)t1.gdf.gz $(TEMP_DIR)t2.gdf.cfw
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.hl7
	./save2gdf -f=CFWB $(TEMP_DIR)t1.edf.gz $(TEMP_DIR)t2.edf.cfw
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.hl7
	./save2gdf -f=CFWB $(TEMP_DIR)t1.bdf.gz $(TEMP_DIR)t2.bdf.cfw
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.hl7
	./save2gdf -f=CFWB $(TEMP_DIR)t1.scp.gz $(TEMP_DIR)t2.scp.cfw
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.hl7
	./save2gdf -f=CFWB $(TEMP_DIR)t1.hl7.gz $(TEMP_DIR)t2.hl7.cfw
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.cfw.gz $(TEMP_DIR)t2.cfw.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.cfw.gz $(TEMP_DIR)t2.cfw.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.cfw.gz $(TEMP_DIR)t2.cfw.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.cfw.gz $(TEMP_DIR)t2.cfw.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.cfw.gz $(TEMP_DIR)t2.cfw.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.cfw.gz $(TEMP_DIR)t2.cfw.hl7
	./save2gdf -f=GDF1 $(TEMP_DIR)t1.mwf.gz $(TEMP_DIR)t2.mwf.gd1
	./save2gdf -f=GDF $(TEMP_DIR)t1.mwf.gz $(TEMP_DIR)t2.mwf.gdf
	./save2gdf -f=EDF $(TEMP_DIR)t1.mwf.gz $(TEMP_DIR)t2.mwf.edf
	./save2gdf -f=BDF $(TEMP_DIR)t1.mwf.gz $(TEMP_DIR)t2.mwf.bdf
	./save2gdf -f=SCP $(TEMP_DIR)t1.mwf.gz $(TEMP_DIR)t2.mwf.scp
	./save2gdf -f=HL7 $(TEMP_DIR)t1.mwf.gz $(TEMP_DIR)t2.mwf.hl7

$(DATA_DIR)Newtest17-2048.bdf : $(DATA_DIR)BDFtestfiles.zip
	unzip -u "$<" -d $(DATA_DIR)

testbdf : $(DATA_DIR)Newtest17-2048.bdf
	./save2gdf -V4 "$<" | awk '/(NoChannels|NRec|Fs|Events\/Annotations):/ { print $$2 } '

testpybdf : $(DATA_DIR)Newtest17-2048.bdf
	$(PYTHON) < python/demo2.py
ifdef SWIG_BIOSIG4PYTHON
	$(PYTHON) python/demo.py $(TEMP_DIR)*-256.bdf
	$(PYTHON) python/example.py $(TEMP_DIR)*-256.bdf 256 && \
	$(PYTHON) python/example.py $(TEMP_DIR)*-2048.bdf 2048
endif

$(DATA_DIR)BDFtestfiles.zip :
	wget -P$(DATA_DIR) http://www.biosemi.com/download/BDFtestfiles.zip

.PHONY: stat 
stat: 
	@echo 'TODO/FIXME:  ';
	@grep -ri '\bTODO\b'  *.c *.h *.i t210/*.c t210/*.h |grep -v '\.svn' |wc -l;
	@grep -ri '\bFIXME\b' *.c *.h *.i t210/*.c t210/*.h |grep -v '\.svn' |wc -l;

test_physicalunits : units.i physicalunits.c physicalunits.h
	gcc -D=TEST_PHYSDIMTABLE_PERFORMANCE -D=WITH_PTHREAD physicalunits.c -o test_physicalunits
	./test_physicalunits
	@echo '--- end of test_physicalunits ---'


testcfs : $(DATA_DIR_CFS) save2gdf 
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/Actions.CFS
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/example.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/Leak.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/NAME_0AA.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/SCANexam.CFS
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/TEST.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)BaseDemo/TRIAL0AA.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)100118s1AB.dat
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)100121s1AF.dat
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)Signal/1_23456.000.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)Signal/1_23456.001.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)Signal/1_23456.002.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)Signal/1_23456.LAST.cfs
	-./save2gdf $(VERBOSE) $(DATA_DIR_CFS)/1617K2AA.DAT

