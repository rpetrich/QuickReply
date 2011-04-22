ifeq ($(shell [ -f ../framework/makefiles/common.mk ] && echo 1 || echo 0),0)
	all clean package install::
		git submodule update --init
		./framework/git-submodule-recur.sh init
		$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

HOME_DIR=/Users/gauravk92
FW_DEVICE_IP=${IPHONE}
SDKVERSION = 3.0
ROCK=1

# QuickReply.dylib (/Library/MobileSubstrate/DynamicLibraries)
TWEAK_NAME = QuickReply
QuickReply_OBJC_FILES = QRChooser.m
QuickReply_FRAMEWORKS = 
QuickReply_PRIVATE_FRAMEWORKS = 

ADDITIONAL_CFLAGS = -std=c99
ADDITIONAL_LDFLAGS = -L$(HOME_DIR)/usr/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/lib

ifeq ($ROCK,1)
	QuickReply_PRIVATE_FRAMEWORKS += IOKit
	ADDITIONAL_CFLAGS += -I$(HOME_DIR)/usr/SDKs/iPHONEOS${SDKVERSION}.sdk/usr/include -DROCK
	ADDITIONAL_LDFLAGS += -lcrypto -lrock -lrockextension 
endif

DEBUG=0

include $(FW_MAKEDIR)/common.mk
include $(FW_MAKEDIR)/tweak.mk

endif
