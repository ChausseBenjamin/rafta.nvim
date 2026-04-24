.PHONY: setup test clean
.ONESHELL:

TMP_DIR := $(or $(TMPDIR),/tmp)

# Will create a tmpdir every time make is called (even make setup)
# but I don't care. It's just a folder.
TEST_DIR := $(shell mktemp -d -p $(TMP_DIR) rafta-test.XXXXXX)


setup:
	@echo "PREPARING SANDBOX PATH: $(TEST_DIR)"
	rm -rf assets/src assets/parser.so
	mkdir -p "$(TEST_DIR)/config" "$(TEST_DIR)/data"

test: setup
	# Will allows the sandbox to retrieve packages offline
	# by retrieving from my local config instead of cloning urls
	export HOST_XDG_DATA_HOME="$$XDG_DATA_HOME"
	# Overwrite nvim dirs for a clean slate
	export XDG_DATA_HOME="$(TEST_DIR)/data"
	export XDG_CONFIG_HOME="$(TEST_DIR)/config"
	export NVIM_LOG_FILE="$(TEST_DIR)/config/nvim.log"
	# Override Git config to allow cloning from partial repos offline
	export GIT_CONFIG_COUNT=2
	export GIT_CONFIG_KEY_0=remote.origin.promisor
	export GIT_CONFIG_VALUE_0=false
	export GIT_CONFIG_KEY_1=remote.origin.partialclonefilter
	export GIT_CONFIG_VALUE_1=
	nvim --headless -u scripts/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.lua' }"

clean:
	rm -rf $(TMP_DIR)/rafta-test.*
