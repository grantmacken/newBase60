# [A New Base 60 Encoding Decoding xQuery Library](https://github.com/grantmacken/newBase60)

The [New Base 60](http://tantek.pbworks.com/w/page/19402946/NewBase60)
numbering system was designed for URL shortening with a limited easy to read character set.

The New Base 60 is ideal for creating *archive* based URLS
 
Based on a date-time stamp
1. Date: year-month-day will convert to and from 3 chars
2. Time: hours:minutes:seconds will convert to and from 3 chars

The <b>newBase60</b> library provides function for handling 
dates and times to and from base60

Note: When using URL shorteners, you should also provide a 
[canonical link element](https://en.wikipedia.org/wiki/Canonical_link_element)
in your html documents if the document can be reached using the expanded archive URL

## Requirements

This repo contains some bash scripts, and uses common gnu utilities,
included in most nix based distros. 
 - git, grep, sed
 - make:   - to build and test
 - docker: - to run eXist
 - prove: - to run tests
 - curl:  - to make http request to eXist

Thats about it, in fact the build and tests,
occur in a simple stock travis (docker 'language c') setup.

## Repo Source Code Conventions

```
├── content
│   └── newBase60.xqm   - the xQuery library named after this repo name
└── unit-tests
    └── t-newBase60.xqm - same as above but prefixed with 't-'
```

These are the only source code file the remainder files are just scaffolding
put in place to build the deployable archive *xar*

## Repo Build Scaffolding

```
├── .env
├── docker-compose.yml
├── Makefile => run `make` calls bash scripts in bin
├── bin
│   ├── exStartUp
│   ├── semVer
│   ├── xQcompile
│   ├── xQdeploy
```

NOTE: If you haven't got the docker image it has to be downloaded first
You may want to use `make up` the first time to obtain the image.
If you are already running eXist container( or anything ) on port 8080 
stop it first. The container port is set in the .env file

## Repo Test Scaffolding

```
├── .env
├── docker-compose.yml
├── Makefile => run `make test` calls `prove -v bin/xQtest`
├── bin
│   ├── xQtest
```

## Makefile Targets

 1. `make` 
    - bring the eXist docker container up. 
    - compile check: see if ./content/newBase60.xqm can be compiled
    - build the archive xar ./build/*.xar
    - deploy library (as a xar archive) into running exist container
    - [![asciicast](https://asciinema.org/a/L1lZiY8q5lGnHwhZ35JR5S9vF.svg)](https://asciinema.org/a/L1lZiY8q5lGnHwhZ35JR5S9vF)
 2. `make test`  
    - upload unit-test library 
    - test and produce a 'ok, not ok' TAP report 
 3. `make release` 
    - set *version* to a bumped latest `git tag`
    - rebuild so *version* is based on this next version
    - create tagged commit 
    - push to origin

## [Built on Travis](https://travis-ci.org/grantmacken/newBase60)

 The build on Travis also uses the same Makefile to 
  - create and deploy into running eXist instance 
  - test the library 
 
 In addition, if the Travis sees a push tagged commit 
 it will create a downloadable release asset ( the xar file ),
 which will be available as github release.

 In the deploy section in the travis file, you can see 
 the deploy trigger only occurs on master branch
 when a tagged commit to master occurs.

In the deploy section in the travis file, you can also see 
the secret key is secret api-key. 

## [Latest Release](https://github.com/grantmacken/newBase60/releases/latest)

If all goes well, the build succeeds and the tests pass then a
release asset in the form of *xar* file will be available on github.

When this downloadable *xar* file become available a 
*webhook* is is triggered. Github will post a request,
containing the release details in the sent json body,
to my designated endpoint URL.

My server receives the request. After authenticating 
the request, the sever install and deploy the library to my production eXist server.

