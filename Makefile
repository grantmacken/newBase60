SHELL=/bin/bash
include .env
git_user != git config user.name
nsname=http://$(NS_DOMAIN)/\#$(NAME)
title != echo $(TITLE)

.PHONY: all
all: deploy

.PHONY: test
test: unit-tests/t-$(NAME).xqm 
	@bin/xQcompile test
	@prove -v bin/xQtest

.PHONY: up
up: 
	@echo -e '##[ $@ ]##'
	@bin/exStartUp

.PHONY: down
down:
	@echo -e '##[ $@ ]##'
	@docker-compose down

.PHONY: compile
compile: content/${NAME}.xqm up
	@echo '##[ $@  $< ]##'
	@bin/xQcompile

define repoXML
<meta xmlns="http://exist-db.org/xquery/repo">
  <description>$(NAME) lib created by $(git_user)</description>
  <author>$(git_user)</author>
 <website>https://github.com/$(git_user)/$(NAME)</website>
  <status>stable</status>
  <license>GNU-LGPL</license>
  <copyright>true</copyright>
  <type>library</type>
</meta>
endef

define expathPkgXML
<package xmlns="http://expath.org/ns/pkg"
  name="$(nsname)"
  abbrev="$(NAME)"
  spec="1.0"
  version="$(patsubst v%,%,$(VERSION))">
  <title>$(title)</title>
  <xquery>
   <namespace>$(nsname)</namespace>
   <file>$(NAME).xqm</file>
  </xquery>
</package>
endef

build/repo.xml: export repoXML:=$(repoXML)
build/repo.xml:
	@echo '##[ $@ ]##'
	@#echo "$${repoXML}" | tidy -q -xml -utf8 -e  --show-warnings no
	@#echo "$${repoXML}" | tidy -q -xml -utf8 -i --indent-spaces 1 --output-file $@
	@echo "$${repoXML}" > $@

build/expath-pkg.xml: export expathPkgXML:=$(expathPkgXML)
build/expath-pkg.xml:
	@echo '##[ $@ ]##'
	@#echo "$${expathPkgXML}" | tidy -q -xml -utf8 -e
	@#echo "$${expathPkgXML}" | tidy -q -xml -utf8 -i --indent-spaces 1 --output-file $@
	@echo "$${expathPkgXML}" > $@

build/content/$(NAME).xqm: content/$(NAME).xqm
	@echo '##[ $@ ]##'
	@mkdir -p $(dir $@)
	@$(MAKE) --silent compile
	@cp $< $@

deploy/$(NAME).xar: \
 build/repo.xml \
 build/expath-pkg.xml \
 build/content/$(NAME).xqm
	@echo '##[ $@ ]## '
	@cd build && zip $(abspath $@) -r .

.PHONY: build
build: compile
	@echo '##[ $@ ]##'
	@rm -fr build
	@rm -fr deploy
	@mkdir build deploy
	@$(MAKE) --silent deploy/$(NAME).xar

.PHONY: deploy
deploy: build
	@echo '##[ $@ ]##'
	@docker cp deploy/$(NAME).xar $(CONTAINER):/tmp
	@bin/xQdeploy
	@touch unit-tests/t-$(NAME).xqm
	@bin/semVer patch

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
	@git push origin   v$(shell grep -oP 'version="\K((\d+\.){2}\d+)' build/expath-pkg.xml)

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


.PHONY: rec
rec:
	asciinema rec tmp/newBase60.cast --overwrite --title='grantmacken/newBase60 run `make test`  ' --command='make test --silent'

iPHONY: play
play:
	asciinema play tmp/newBase60.cast

.PHONY: upload
upload:
	asciinema upload tmp/newBase60.cast
