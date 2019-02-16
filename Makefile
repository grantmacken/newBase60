SHELL=/bin/bash
include .env
git_user != git config user.name
nsname=http://$(NS_DOMAIN)/\#$(NAME)
title != echo $(TITLE)
include inc/repo.mk inc/expath-pkg.mk
.PHONY: all
all: build

.PHONY: test
test: unit-tests/t-$(NAME).xqm 
	@bin/xQcompile $<
	@prove -v bin/xQtest

.PHONY: clean
clean:
	@rm -rfv tmp
	@rm -rfv build
	@rm -rfv deploy

.PHONY: up
up: 
	@echo -e '##[ $@ ]##'
	@bin/exStartUp

.PHONY: down
down:
	@echo -e '##[ $@ ]##'
	@docker-compose down

.PHONY: compile-main
compile-main: content/${NAME}.xqm
	@echo '##[ $@  $< ]##'
	@mkdir -p tmp
	@bin/xQcompile $<

.PHONY: compile-test
compile-test: unit-tests/t-${NAME}.xqm
	@#' that will not compile unless ${NAME}.xqm is deployed '
	@echo '##[ $@  $< ]##'
	@mkdir -p tmp
	@bin/xQcompile $<

build/repo.xml: export repoXML:=$(repoXML)
build/repo.xml:
	@echo '##[ $@ ]##'
	@echo "$${repoXML}"
	@mkdir -p $(dir $@)
	@echo "$${repoXML}" > $@

build/expath-pkg.xml: export expathPkgXML:=$(expathPkgXML)
build/expath-pkg.xml:
	@echo '##[ $@ ]##'
	@echo "$${expathPkgXML}" 
	@mkdir -p $(dir $@)
	@echo "$${expathPkgXML}" > $@

build/content/$(NAME).xqm: content/$(NAME).xqm
	@echo '##[ $@ ]##'
	@mkdir -p $(dir $@)
	@cp $< $@

deploy/$(NAME).xar: \
 build/repo.xml \
 build/expath-pkg.xml \
 build/content/$(NAME).xqm
	@echo '##[ $@ ]## '
	@mkdir -p $(dir $@)
	@cd build && zip $(abspath $@) -r .

.PHONY: build
build: compile-main deploy/$(NAME).xar
	@echo '##[ $@ ]##'
	@bin/xQdeploy deploy/$(NAME).xar
	@bin/semVer patch
	@touch unit-tests/t-$(NAME).xqm

.PHONY: reset
reset:
	@echo '##[ $@ ]##'
	@git describe --abbrev=0 --tag
	@# git describe --tags $(git rev-list --tags --max-count=1)
	@echo 'revert .env VERSION to current tag' 
	@source .env; sed -i "s/^VERSION=$${VERSION}/VERSION=$(shell git describe --abbrev=0 --tag )/" .env

.PHONY: release
release:
	@echo '##[ $@ ]##'
	@echo -n "current latest tag: " 
	@git describe --abbrev=0 --tag &>/dev/null || git tag v0.0.1
	@# git describe --tags $(git rev-list --tags --max-count=1)
	@echo 'revert .env VERSION to current tag' 
	@source .env; sed -i "s/^VERSION=$${VERSION}/VERSION=$(shell git describe --abbrev=0 --tag )/" .env
	@echo -n ' - bump the version: ' 
	@bin/semVer patch
	@grep -oP '^VERSION=\K(.+)$$' .env
	@echo ' - do a build from the current tag' 
	@$(MAKE) --silent
	@#grep -oP '^VERSION=v\K(.+)$$' .env
	@#grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml
	@echo v$(shell grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml)
	@#git commit .env -m 'prepare new release version' &>/dev/null || true
	@#git push
	@git tag v$(shell grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml)
	@git push origin  v$(shell grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml)

# https://docs.travis-ci.com/user/deployment/releases
.PHONY: travis-setup-releases
travis-setup-releases:
	@echo '##[ $@ ]##'
	@travis setup releases
	@#travis encrypt TOKEN="$$(<../.myJWT)" --add 

.PHONY: gitLog
gitLog:
	@clear
	@git --no-pager log \
  -n 10\
 --pretty=format:'%Cred%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'

.PHONY: smoke
smoke: 
	@echo '##[ $@ ]##'
	@bin/xQcall 'newBase60:example()' \
 | grep -oP '^\s-\s(\w|-)(.+)$$'

.PHONY: rec
rec:
	asciinema rec tmp/newBase60.cast --overwrite --title='grantmacken/newBase60 run `make test`  ' --command='make test --silent'

iPHONY: play
play:
	asciinema play tmp/newBase60.cast

.PHONY: upload
upload:
	asciinema upload tmp/newBase60.cast
