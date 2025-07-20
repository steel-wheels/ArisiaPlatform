# install_xc.mk

PROJECT_NAME	?= ArisiaPlatform
DERIVED_BASE	= $(HOME)/build/derived-data/
PRODUCT_PATH	= Build/Products/Release

all: install_xc

clean:
	(cd $(DERIVED_BASE) && rm -rf $(PROJECT_NAME)_macOS)
	(cd $(DERIVED_BASE) && rm -rf $(PROJECT_NAME)_iOS)
	(cd $(DERIVED_BASE) && rm -rf $(PROJECT_NAME)_iOS_sim)
	(cd $(HOME)/Library/Frameworks && rm -rf $(PROJECT_NAME).xcframework)

install_xc: install_osx install_ios install_ios_sim
	(cd $(HOME)/Library/Frameworks ; rm -rf $(PROJECT_NAME).xcframework)
	xcodebuild -create-xcframework \
	  -framework $(DERIVED_BASE)/$(PROJECT_NAME)_macOS/$(PRODUCT_PATH)/$(PROJECT_NAME).framework \
	  -framework $(DERIVED_BASE)/$(PROJECT_NAME)_iOS/$(PRODUCT_PATH)-iphoneos/$(PROJECT_NAME).framework \
	  -framework $(DERIVED_BASE)/$(PROJECT_NAME)_iOS_sim/$(PRODUCT_PATH)-iphonesimulator/$(PROJECT_NAME).framework \
	  -output $(HOME)/Library/Frameworks/$(PROJECT_NAME).xcframework

install_osx: dummy
	xcodebuild build \
	  -scheme $(PROJECT_NAME)_macOS \
	  -project $(PROJECT_NAME).xcodeproj \
	  -destination="generic/platform=macOS" \
	  -configuration Release \
 	  -derivedDataPath $(DERIVED_BASE)/$(PROJECT_NAME)_macOS \
	  -sdk macosx \
 	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 	  SKIP_INSTALL=NO \
 	  ONLY_ACTIVE_ARCH=NO

install_ios: dummy
	xcodebuild build \
	  -scheme $(PROJECT_NAME)_iOS \
	  -project $(PROJECT_NAME).xcodeproj \
	  -destination="generic/platform=iOS" \
	  -configuration Release \
	  -derivedDataPath $(DERIVED_BASE)/$(PROJECT_NAME)_iOS \
	  -sdk iphoneos \
	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	  SKIP_INSTALL=NO \
	  ONLY_ACTIVE_ARCH=NO

install_ios_sim: dummy
	xcodebuild build \
	  -scheme $(PROJECT_NAME)_iOS \
	  -project $(PROJECT_NAME).xcodeproj \
	  -destination="generic/platform=iOS Simulator" \
	  -configuration Release \
	  -derivedDataPath $(DERIVED_BASE)/$(PROJECT_NAME)_iOS_sim \
	  -sdk iphonesimulator \
	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	  SKIP_INSTALL=NO \
	  ONLY_ACTIVE_ARCH=NO

dummy:

