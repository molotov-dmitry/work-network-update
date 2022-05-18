TARGET_UPDATE	:= network-update
TARGET_INIT		:= network-init
INSTALL_DIR		:= $(PREFIX)/usr/local/bin

.PHONY: all install uninstall

all:

$(INSTALL_DIR):
	mkdir -p $(INSTALL_DIR)

$(INSTALL_DIR)/$(TARGET_UPDATE): $(TARGET_UPDATE).sh | $(INSTALL_DIR)
	install $< $@
	
$(INSTALL_DIR)/$(TARGET_INIT): $(TARGET_INIT).sh | $(INSTALL_DIR)
	install $< $@

install: $(INSTALL_DIR)/$(TARGET_UPDATE) $(INSTALL_DIR)/$(TARGET_INIT)

uninstall:
	rm -f $(INSTALL_DIR)/$(TARGET_UPDATE) $(INSTALL_DIR)/$(TARGET_INIT)

