# Makefile для сборки и создания .opa пакета

# Параметры
BUILD_PATH := $(realpath .)
MANIFEST := $(BUILD_PATH)/Manifest.xml
PKG_DIR := $(BUILD_PATH)/pkg
TEMP_DIR := $(BUILD_PATH)/temp
OUTPUT_DIR := $(BUILD_PATH)/bin

# Проверка существования Manifest.xml
check-manifest:
	@if [ ! -f "$(MANIFEST)" ]; then \
		echo "Manifest.xml not found at $(MANIFEST)"; \
		exit 1; \
	fi

# Извлечение данных из Manifest.xml
extract-info:
	@echo "Application Information:"
	@echo "----------------------------"
	@$(eval APPNAME := $(shell xmllint --xpath 'string(//Application/appname)' $(MANIFEST)))
	@$(eval APPID := $(shell xmllint --xpath 'string(//Application/appid)' $(MANIFEST)))
	@$(eval APPVERSION := $(shell xmllint --xpath 'string(//Application/appversion)' $(MANIFEST)))
	@$(eval APPSTATUS := $(shell xmllint --xpath 'string(//Application/appstatus)' $(MANIFEST)))
	@$(eval APPICON := $(shell xmllint --xpath 'string(//Application/appicon)' $(MANIFEST)))
	@$(eval MINVERSION := $(shell xmllint --xpath 'string(//Application/minversion)' $(MANIFEST)))
	@$(eval APIVER := $(shell xmllint --xpath 'string(//Application/apiver)' $(MANIFEST)))
	@echo "App Name: $(APPNAME)"
	@echo "App ID: $(APPID)"
	@echo "App Version: $(APPVERSION)"
	@echo "App Status: $(APPSTATUS)"
	@echo "App Icon: $(APPICON)"
	@echo "Minimal OptionBSD version: $(MINVERSION)"
	@echo "API Version: $(APIVER)"
	@echo

# Сборка для каждой архитектуры
build:
	@echo "Building $(BUILD_PATH)..."
	@$(eval PLATFORMS := $(shell xmllint --xpath '//Build/platform/text()' $(MANIFEST) | tr -s '\n' ' '))
	@$(eval BUILDER := $(shell xmllint --xpath 'string(//Build/builder)' $(MANIFEST)))
	@$(eval SRC := $(shell xmllint --xpath 'string(//Build/src)' $(MANIFEST)))
	@echo "Builder: $(BUILDER)"
	@echo "Source Directory: $(SRC)"
	@echo

	@for platform in $(PLATFORMS); do \
		echo "Building for platform: $$platform"; \
		if [ "$(BUILDER)" = "clang" ]; then \
			COMPILER="clang"; \
		else \
			COMPILER="gcc"; \
		fi; \
		TEMP_DIR="$(BUILD_PATH)/temp/$$platform"; \
		mkdir -p $$TEMP_DIR; \
		cp -r $(BUILD_PATH)/$$SRC/* $$TEMP_DIR; \
		$$COMPILER -o $$TEMP_DIR/main $$TEMP_DIR/*.c $(pkg-config --cflags --libs gtk+-3.0); \
		if [ $$? -eq 0 ]; then \
			OUTPUT_DIR="$(BUILD_PATH)/bin/$$platform"; \
			mkdir -p $$OUTPUT_DIR; \
			mv $$TEMP_DIR/main $$OUTPUT_DIR/; \
			echo "Build completed successfully for $$platform"; \
		else \
			echo "Build failed for $$platform"; \
		fi; \
		rm -rf $$TEMP_DIR; \
	done

# Создание .opa пакета
create-package:
	@echo "Creating package..."
	@mkdir -p $(PKG_DIR)
	@cp $(MANIFEST) $(PKG_DIR)/
	@cp -r $(BUILD_PATH)/bin $(PKG_DIR)/
	@cp -r $(BUILD_PATH)/res $(PKG_DIR)/

	@$(eval PACKAGE_NAME := $(APPNAME)-$(APPVERSION)-$(APPSTATUS).opa)
	@cd $(PKG_DIR) && zip -r $(BUILD_PATH)/$(PACKAGE_NAME) ./*
	@rm -rf $(PKG_DIR)

	@echo "Package $(PACKAGE_NAME) created successfully."

# Главная цель
all: check-manifest extract-info build create-package
