PREFIX ?= $(HOME)/.local
LABEL = dev.tmm.ghostty-navigator
PLIST = $(HOME)/Library/LaunchAgents/$(LABEL).plist

.PHONY: build
build:
	@mkdir -p $(PREFIX)/bin $(PREFIX)/share/ghostty-navigator.nvim
	@swiftc -O -o $(PREFIX)/bin/ghostty-navigator.nvim ghostty-navigator.swift -framework Cocoa
	@if [ ! -f $(PLIST) ]; then \
		echo '<?xml version="1.0" encoding="UTF-8"?>' > $(PLIST); \
		echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(PLIST); \
		echo '<plist version="1.0"><dict>' >> $(PLIST); \
		echo '  <key>Label</key><string>$(LABEL)</string>' >> $(PLIST); \
		echo '  <key>ProgramArguments</key><array><string>$(PREFIX)/bin/ghostty-navigator.nvim</string></array>' >> $(PLIST); \
		echo '  <key>KeepAlive</key><true/>' >> $(PLIST); \
		echo '  <key>StandardErrorPath</key><string>$(PREFIX)/share/ghostty-navigator.nvim/stderr.log</string>' >> $(PLIST); \
		echo '  <key>StandardOutPath</key><string>$(PREFIX)/share/ghostty-navigator.nvim/stdout.log</string>' >> $(PLIST); \
		echo '</dict></plist>' >> $(PLIST); \
	fi
	@launchctl stop $(LABEL) 2>/dev/null; launchctl start $(LABEL) 2>/dev/null || launchctl load $(PLIST) 2>/dev/null || true
	@echo "ghostty-navigator.nvim: compiled and restarted"

.PHONY: uninstall
uninstall:
	@launchctl stop $(LABEL) 2>/dev/null || true
	@launchctl unload $(PLIST) 2>/dev/null || true
	@rm -f $(PLIST)
	@rm -f $(PREFIX)/bin/ghostty-navigator.nvim
	@rm -rf $(PREFIX)/share/ghostty-navigator.nvim
	@echo "ghostty-navigator.nvim: uninstalled"
