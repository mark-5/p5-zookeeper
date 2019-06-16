ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
COMPOSE = docker-compose -f $(ROOT)docker-compose.yml

default: build

$(ROOT)Dockerfile: $(ROOT)Dockerfile.PL
	$(ROOT)Dockerfile.PL

build: $(ROOT)Dockerfile
	$(COMPOSE) build code && $(COMPOSE) up -d zookeeper

shell: build
	$(COMPOSE) run --rm code /bin/bash

test: build
	$(COMPOSE) run --rm code /bin/sh -c 'perl Makefile.PL && make test TEST_VERBOSE=1'

clean:
	$(COMPOSE) down
	rm $(ROOT)Dockerfile

realclean: clean
	$(COMPOSE) down --rmi local --volumes --remove-orphans

