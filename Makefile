JIRA_VERSION=8.22.2
JIRA_FILE=atlassian-jira-software-$(JIRA_VERSION)-x64.bin
JIRA_URL=https://product-downloads.atlassian.com/software/jira/downloads/$(JIRA_FILE)

VOLUMES=-v $(shell pwd)/debug:/usr/local/debug -v /usr/local/jira:/var/atlassian/jira

.PHONY: help
help:
	@echo "Run 'make build' to create the patched Jira"
	@echo "Run 'make start' to start it. When prompted for your licence,"
	@echo "run 'make licence' to create it."
	@echo ""
	@echo "  ** Note that you MUST HAVE AN EXISTING LICENCE! **"
	@echo "  This simply extends your 'valid until' time so you can download"
	@echo "  and use Jira releases that have fixed security vulnerabilities"
	@echo "  that you are unable to use currently"
	@echo ""

.PHONY: licence
licence: licence/licence.txt
	@echo "If you want to regenerate the licence, delete everything in licence"
	@echo -e "Licence to paste into Jira:\n"
	@cat $<
	@echo -e "\n"

.PHONY: setup
setup: /usr/local/jira docker/fernflower.jar

.PHONY: build
build: .docker_build

.docker_build: setup $(wildcard docker/*)
	docker build --tag jira:${JIRA_VERSION} --build-arg JIRA_VERSION=$(JIRA_VERSION) --build-arg JIRA_FILE=$(JIRA_FILE) --build-arg JIRA_URL=$(JIRA_URL) docker/
	touch $@

docker/fernflower.jar: /tmp/fernflower.jar
	cp $< $@

# Not used any more
docker/master.tar.gz:
	wget https://github.com/binhnt-teko/jira-crack/archive/refs/heads/master.tar.gz -O $@

.PHONY: start
start: .docker_build
	@[ "$(shell docker ps -q -f name=jira)" ] && echo "Jira already running" || docker run -d $(VOLUMES) --publish=8080:8080 --name jira jira:${JIRA_VERSION}

.PHONY: stop
stop:
	docker rm -f jira || :

debug: stop .docker_build
	docker run -it --rm $(VOLUMES) --name jira-debug jira:${JIRA_VERSION} /bin/bash

.PHONY: shell
shell: start
	docker exec -it jira /bin/bash

licence/licence.txt: licence/patched_licence.txt
	php processor.php -e $< -r $@

licence/serverid.txt:
	@read -p "Enter ServerID as prompted: " x && echo $$x > $@

licence/patched_licence.txt: licence/raw_licence.txt licence/serverid.txt
	sed \
		-e '/^ServerID/d' \
		-e '/^MaintenanceExpiryDate/d' \
		-e '/^SEN=/a ServerID=$(shell cat licence/serverid.txt)' \
		-e '/^SEN=/a MaintenanceExpiryDate=2099-01-01' \
		< $< > $@

licence/raw_licence.txt: licence/current.txt
	php processor.php -d $< -r $@

licence/current.txt:
	@mkdir -p licence/
	@echo "Copy-and-paste your existing licence into $@"
	@echo "You MUST have a Jira licence to permit reverse engineering"
	@echo "under section 47D of the copyright act"
	@exit 1

/usr/local/jira:
	mkdir $@
	chmod 777 $@

jar: fernflower.jar

.fernflower_docker_build: $(wildcard fernflower/*)
	docker build --tag fernflower fernflower/
	touch $@

.PHONY: ffshell
ffshell: .fernflower_docker_build
	docker run --rm -it fernflower:latest /bin/bash

fernflower.jar: /tmp/fernflower.jar

/tmp/fernflower.jar: .fernflower_docker_build
	docker run --rm -v /tmp:/tmp -it fernflower:latest cp /usr/local/fernflower/build/libs/fernflower.jar /tmp


