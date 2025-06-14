.DEFAULT_GOAL = help

SHELL = /usr/bin/env bash

# helpers ##############################################################

.PHONY: format check
format:  ## format all shell scripts
	find . -type f -name '*.sh' \
		-exec sed -i -E \
			-e 's/\$$([a-zA-Z_][a-zA-Z0-9_]*|[0-9]+)/$${\1}/g' \
			-e 's/([^[])\[ ([^]]+) \]/\1[[ \2 ]]/g' \
			{} + \
		-exec shfmt \
			--write \
			--simplify \
			--indent 4 \
			--case-indent \
			--space-redirects \
			{} +
check:  ## check all shell scripts
	find . \
		\! -path './install/src/*' \
		-type f -name '*.sh' \
		-exec shellcheck \
			--norc \
			--enable=all \
			--shell=bash \
			--severity=style \
			{} +

print-%:
	$(info $* = $($*))

help:  ## print this help message
	@awk 'BEGIN{w=0;n=0}{while(match($$0,/\\$$/)){sub(/\\$$/,"");getline nextLine;$$0=$$0 nextLine}if(/^[[:alnum:]_-]+:.*##.*$$/){n++;split($$0,cols[n],":.*##");l=length(cols[n][1]);if(w<l)w=l}}END{for(i=1;i<=n;i++)printf"\033[1m\033[93m%-*s\033[0m%s\n",w+1,cols[i][1]":",cols[i][2]}' $(MAKEFILE_LIST)
