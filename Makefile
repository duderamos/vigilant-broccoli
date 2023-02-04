.PHONY: \
	.env \
	build-base \
	bootstrap \
	start-dev \
	start-puma \
	start-db \
	restart-dev \
	stop \
	down \
	run-command \
	list \
	help

dc = docker compose
dc_up = ${dc} up
dc_run = ${dc} run --rm
dc_run_no_deps = ${dc_run} --no-deps --entrypoint ""
bundle_install = ${dc_run_no_deps} web-dev bundle install
rails_new_args = ""
run_command = ""

cwd := $(shell basename $(shell pwd))

.env:
	test -s .env || { echo ".env does not exist! Exiting..."; exit 1; }

build-base: .env
	${dc} build base

bootstrap: .env
	${dc} build web-dev
	${bundle_install}
	${dc_run_no_deps} web-dev rails new . --force $(rails_new_args)
	test -s Procfile.dev && sed -i 's|rails server -p 3000$|rails server -p 3000 -b 0.0.0.0|g' Procfile.dev
	test ! -f Procfile.dev && echo "bundle exec rails server -p 3000 -b 0.0.0.0" > bin/dev
	${dc_up} -d postgresql
	${dc_run} bin/run rails db:drop db:create db:migrate

run-bundle-install: .env
	${bundle_install}

start-dev: start-puma

start-db:
	${dc_up} -d db

start-puma: start-db
	${dc_up} -d web-dev

restart-dev: stop start-dev

stop:
	${dc} down

down: stop

attach-puma: start-puma
	docker attach ${cwd}-web-dev-1

run-command:
	${dc_run} web-dev $(run_command)

list:
	@egrep '^[a-z\-]*:' Makefile | cut -d':' -f1 | sort

help: list
