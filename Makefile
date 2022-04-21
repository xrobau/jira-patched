JIRA_VERSION=8.22.2
JIRA_FILE=atlassian-jira-software-$(JIRA_VERSION)-x64.bin
JIRA_URL=https://product-downloads.atlassian.com/software/jira/downloads/$(JIRA_FILE)

setup: docker/fernflower.jar licence/licence.txt

.PHONY: build
build: .docker_build

.docker_build: docker/fernflower.jar $(wildcard docker/*)
	docker build --tag jira:${JIRA_VERSION} --build-arg JIRA_VERSION=$(JIRA_VERSION) --build-arg JIRA_FILE=$(JIRA_FILE) --build-arg JIRA_URL=$(JIRA_URL) docker/
	touch $@

docker/fernflower.jar: /tmp/fernflower.jar
	cp $< $@

# Not used any more
docker/master.tar.gz:
	wget https://github.com/binhnt-teko/jira-crack/archive/refs/heads/master.tar.gz -O $@

.PHONY: shell
shell: .docker_build
	docker run --rm -it -v $(shell pwd)/debug:/usr/local/debug --publish=8080:8080 jira:${JIRA_VERSION} /bin/bash

licence/licence.txt: licence/patched_licence.txt
	php processor.php -e $< -r $@

licence/patched_licence.txt: licence/raw_licence.txt
	sed -e '/^ServerID/d' -e '/^MaintenanceExpiryDate/d' -e '/^SEN=/a MaintenanceExpiryDate=2099-01-01' < $< > $@

licence/raw_licence.txt: licence/current.txt
	php processor.php -d $< -r $@

licence/current.txt:
	@mkdir -p licence/
	@echo "Copy-and-paste your existing licence into $@"
	@echo "You MUST have a Jira licence to permit reverse engineering"
	@echo "under section 47D of the copyright act"
	@exit 1

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


