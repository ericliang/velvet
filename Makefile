REPO		?= velvet
PKG_NAME        ?= velvet
PKG_REVISION    ?= $(shell git describe --tags)
PKG_VERSION	?= $(shell git describe --tags | tr - .)
PKG_ID           = $(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD        = 1
BASE_DIR         = $(shell pwd)
ERLANG_BIN       = $(shell dirname $(shell which erl))
REBAR           ?= $(BASE_DIR)/rebar
OVERLAY_VARS    ?=

VSN := $(shell erl -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), init:stop().' | grep 'R' | sed -e 's,R\(..\)B.*,\1,')
NEW_HASH := $(shell expr $(VSN) \>= 16)

.PHONY: rel deps test

all: deps compile

compile:
ifeq ($(NEW_HASH),1)
	@(./rebar compile -Dnew_hash)
else
	@(./rebar compile)
endif

deps:
	@./rebar get-deps

clean:
	@./rebar clean

distclean: clean
	@./rebar delete-deps
	@rm -rf $(PKG_ID).tar.gz

test: all
ifeq ($(NEW_HASH),1)
	@(./rebar skip_deps=true -Dnew_hash eunit)
else
	@./rebar skip_deps=true eunit
endif

APPS = kernel stdlib sasl erts ssl tools os_mon runtime_tools crypto inets \
	xmerl webtool eunit syntax_tools compiler
PLT = $(HOME)/.stanchion_dialyzer_plt

check_plt: compile
	dialyzer --check_plt --plt $(PLT) --apps $(APPS) \
		deps/*/ebin ebin

build_plt: compile
	dialyzer --build_plt --output_plt $(PLT) --apps $(APPS) \
		deps/*/ebin ebin

dialyzer: compile
	@echo
	@echo Use "'make check_plt'" to check PLT prior to using this target.
	@echo Use "'make build_plt'" to build PLT prior to using this target.
	@echo
	@sleep 1
	dialyzer -Wno_return -Wunmatched_returns --plt $(PLT) deps/*/ebin ebin

cleanplt:
	@echo
	@echo "Are you sure?  It takes about 1/2 hour to re-build."
	@echo Deleting $(PLT) in 5 seconds.
	@echo
	sleep 5
	rm $(PLT)
