SHELL=/bin/bash
# LAST_TAG_COMMIT = $(shell git rev-list --tags --max-count=1)
# LAST_TAG = $(shell git describe --tags $(LAST_TAG_COMMIT) )
# TAG_PREFIX = "v"
VERSION != grep -oP '^v\K(.+)$$' VERSION
include .env
git_user != git config user.name
nsname=http://$(NS_DOMAIN)/\#$(NAME)
title != echo $(TITLE)
include inc/*

.PHONY: default
default: clean compile-main build

.PHONY: clean
clean:
	@rm -rfv tmp &>/dev/null
	@rm -rfv build &>/dev/null
	@rm -rfv deploy &>/dev/null

.PHONY: compile-main
compile-main: content/${NAME}.xqm
	@echo '##[ $@  $< ]##'
	@mkdir -p tmp
	@bin/xQcompile $<

.PHONY: build
build: deploy/$(NAME).xar
	@echo '##[ $@ ]##'
	@bin/xQdeploy $<
	@bin/semVer $(VERSION) patch > VERSION
	@#touch unit-tests/t-$(NAME).xqm
	@#echo -n 'INFO: prepped for next build: ' && cat VERSION

.PHONY: test
test: unit-tests/t-$(NAME).xqm 
	@bin/xQcompile $<
	@prove -v bin/xQtest

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

remoteTag != git ls-remote -q --tags  | grep -oP 'v\d+\.\d+\.\d+' | sort | tail -1

.PHONY: reset-version
reset-version:
	@echo '##[ $@ ]##'
	@# git pull --tags
	@echo ' - get the latest pushed tag from remote and update VERSION'
	@bin/semVer $(remoteTag) patch  > VERSION
	@echo ' commit version and push '
	@git commit -m 'version update: $(shell cat VERSION )' VERSION
	@git push
	@travis open

.PHONY: release
release:
	@echo '##[ $@ ]##'
	@travis status | grep -oP 'passed'
	@[[ $(shell git tag | grep -c $$(cat VERSION)) -eq 0 ]] || (echo ' - all ready tagged'; false)
	@#$(if $(shell git status -s --porcelain),$(shell git commit -am 'tagged release prep'),)
	@#git push
	@#git tag v$(shell grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml)
	@#git push origin  v$(shell grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml)

# https://docs.travis-ci.com/user/deployment/releases
.PHONY: travis-setup-releases
travis-setup-releases:
	@echo '##[ $@ ]##'
	@gem install --user-install travis
	@travis setup releases
	@#travis encrypt TOKEN="$$(<../.myJWT)" --add

.PHONY: travis-setup
travis-setup:
	@echo '##[ $@ ]##'
	@gem install --user-install travis

.PHONY: gitLog
gitLog:
	@clear
	@git --no-pager log \
  -n 10\
 --pretty=format:'%Cred%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'

.PHONY: smoke
smoke: 
	@echo '##[ $@ ]##'
	@bin/xQcall 'newBase60:example()'

.PHONY: rec
rec:
	asciinema rec tmp/newBase60.cast --overwrite --title='grantmacken/newBase60 run `make test`  ' --command='make test --silent'

iPHONY: play
play:
	asciinema play tmp/newBase60.cast

.PHONY: upload
upload:
	asciinema upload tmp/newBase60.cast


.PHONY: up
up: clean
	@echo -e '##[ $@ ]##'
	@bin/exStartUp
	@touch VERSION && echo 'v0.0.1' > VERSION

.PHONY: down
down:
	@echo -e '##[ $@ ]##'
	@docker-compose down  --remove-orphans
