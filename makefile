ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
	all clean package install::
		git submodule update --init
		./framework/git-submodule-recur.sh init
		$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

TARGET_CC = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/llvm-gcc-4.2
TARGET_CXX = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/llvm-gcc-4.2
DEBUG=0
GO_EASY_ON_ME=1

SUBPROJECTS = QRChooser

# QuickReply.dylib (/Library/MobileSubstrate/DynamicLibraries)
TWEAK_NAME = quickreply4
quickreply4_TWEAK_VERSION = "1.6.5"
quickreply4_OBJC_FILES = QRLibrary.m QRView.m QRWindow.m QRController.m
quickreply4_FRAMEWORKS = UIKit CoreGraphics QuartzCore 
quickreply4_PRIVATE_FRAMEWORKS = ChatKit GraphicsServices AddressBook

ADDITIONAL_CFLAGS = -std=c99 -include ./Prefix.pch -D quickreply4_TWEAK_VERSION=$(quickreply4_TWEAK_VERSION)
quickreply4_INSTALL_PATH = /Library/QuickReply/

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
include framework/makefiles/aggregate.mk

update::
	ssh root@$(FW_DEVICE_IP) "rm -rf $(quickreply4_INSTALL_PATH)$(TWEAK_NAME).dylib"
	scp $(FW_OBJ_DIR_NAME)/$(TWEAK_NAME).dylib root@$(FW_DEVICE_IP):$(quickreply4_INSTALL_PATH)$(TWEAK_NAME).dylib
	ssh root@$(FW_DEVICE_IP) "killall -9 SpringBoard"

endif
