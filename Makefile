#
# Makefile fragment for Linux 2.6
# Broadcom 802.11abg Networking Device Driver
#
# Copyright (C) 2015, Broadcom Corporation. All Rights Reserved.
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# $Id: Makefile_kbuild_portsrc 580354 2015-08-18 23:42:37Z $

# Its so old we only care about this now
export LINUXVER_GOODFOR_CFG80211 := "TRUE"
export LINUXVER_WEXT_ONLY := "FALSE"
export APICHOICE := "PREFER_CFG80211"
export APIFINAL := "CFG80211"

#Check GCC version so we can apply -Wno-date-time if supported.  GCC >= 4.9
empty:=
space:= $(empty) $(empty)
GCCVERSIONSTRING := $(shell expr `$(CC) -dumpversion`)
#Create version number without "."
GCCVERSION := $(shell expr `echo $(GCCVERSIONSTRING)` | cut -f1 -d.)
GCCVERSION += $(shell expr `echo $(GCCVERSIONSTRING)` | cut -f2 -d.)
GCCVERSION += $(shell expr `echo $(GCCVERSIONSTRING)` | cut -f3 -d.)
# Make sure the version number has at least 3 decimals
GCCVERSION += 00
# Remove spaces from the version number
GCCVERSION := $(subst $(space),$(empty),$(GCCVERSION))
# Crop the version number to 3 decimals.
GCCVERSION := $(shell expr `echo $(GCCVERSION)` | cut -b1-3)
GE_49 := $(shell expr `echo $(GCCVERSION)` \>= 490)

ccflags-y :=

ifeq ($(APIFINAL),CFG80211)
  ccflags-y += -DUSE_CFG80211
  $(info Using CFG80211 API)
endif

ifeq ($(APIFINAL),WEXT)
  ccflags-y += -DUSE_IW
  $(info Using Wireless Extension API)
endif

obj-m              += wl.o

wl-objs            :=
wl-objs            += src/shared/linux_osl.o
wl-objs            += src/wl/sys/wl_linux.o
wl-objs            += src/wl/sys/wl_iw.o
wl-objs            += src/wl/sys/wl_cfg80211_hybrid.o

ccflags-y          += -I$(src)/src/include -I$(src)/src/common/include
ccflags-y          += -I$(src)/src/wl/sys -I$(src)/src/wl/phy -I$(src)/src/wl/ppr/include
ccflags-y          += -I$(src)/src/shared/bcmwifi/include
#ccflags-y          += -DBCMDBG_ASSERT -DBCMDBG_ERR
ifeq "$(GE_49)" "1"
ccflags-y          += -Wno-date-time
endif

ldflags-y          := $(src)/lib/wlc_hybrid.o_shipped

KBASE              ?= /lib/modules/`uname -r`
KBUILD_DIR         ?= $(KBASE)/build
MDEST_DIR          ?= $(KBASE)/kernel/drivers/net/wireless

# Cross compile setup.  Tool chain and kernel tree, replace with your own.
CROSS_TOOLS        = /path/to/tools
CROSS_KBUILD_DIR   = /path/to/kernel/tree

# Rel. commit "objtool: Always fail on fatal errors" (Josh Poimboeuf, 31 Mar 2025)
# This is a *ugly* hack to disable objtool during the final processing of wl.o.
# Since is embeds the proprietary blob (wlc_hybrid.o_shipped), objtool can't
# process it, as it does not follow the requirements of current kernels,
# including support for critical security features. As of Linux v6.15+, it causes
# a build error. Disable it, at your own risk. Note the MIT license applies:
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
wl.o: override objtool-enabled =

all:
	KBUILD_NOPEDANTIC=1 make -C $(KBUILD_DIR) M=`pwd`

cross:
	KBUILD_NOPEDANTIC=1 make CROSS_COMPILE=${CROSS_TOOLS} -C $(CROSS_KBUILD_DIR) M=`pwd`

clean:
	KBUILD_NOPEDANTIC=1 make -C $(KBUILD_DIR) M=`pwd` clean

install:
	install -D -m 755 wl.ko $(MDEST_DIR)
