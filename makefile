.DEFAULT_GOAL := help

## 変えるところ
SERVICE:=isuports.service

## 定数

MYSQL_SLOW_LOG:=/var/log/mysql/mysql-slow.log
NGINX_LOG:=/var/log/nginx/access.log
NGINX_ERROR_LOG:=/var/log/nginx/error.log

ALP_LOG:=alp.txt
DIGEST_LOG:=digest.txt

## Common

restart: ## Restart all
	@git pull
	@make -s nginx-restart
	@make -s db-restart
	@make -s app-restart

report: ## Generate monitoring report
	@make -s alp
	@make -s digest

restart-1: ## Restart for Server 1
	@make -s restart

restart-2: ## Restart for Server 2
	@make -s restart

restart-3: ## Restart for Server 3
	@make -s restart

## App

app-restart: ## Restart Server
	@sudo systemctl daemon-reload
	@sudo systemctl restart $(SERVICE)
	@echo 'Restart service'

app-log: ## Tail server log
	@sudo journalctl -f -u -n10 $(SERVICE)

## Nginx

nginx-restart: ## Restart nginx
	@sudo cp /dev/null $(NGINX_LOG)
	@sudo cp nginx.conf /etc/nginx/
	@echo 'Validate nginx.conf'
	@sudo nginx -t
	@sudo systemctl restart nginx
	@echo 'Restart nginx'

nginx-log: ## Tail nginx access.log
	@sudo tail -f $(NGINX_LOG)

nginx-error-log: ## Tail nginx error.log
	@sudo tail -f $(NGINX_ERROR_LOG)

## Alp

alp: ## Run alp
	@sudo alp ltsv --file $(NGINX_LOG) --sort sum --reverse --matching-groups 'api/player/competition/[a-z0-9]+/ranking, /api/player/player/[a-z0-9]+, /api/organizer/competition/[a-z0-9]+/score,  /api/organizer/competition/[a-z0-9]+/finish,  /api/organizer/player/[a-z0-9]+/disqualified ' > $(ALP_LOG)
	@./dispost -f $(ALP_LOG)

## DB

db-restart: ## Restart mysql
	@sudo cp /dev/null $(MYSQL_SLOW_LOG)
	@sudo cp my.cnf /etc/mysql/
	@sudo systemctl restart mysql
	@echo 'Restart mysql'

digest: ## Analyze mysql-slow.log by pt-query-digest
	@sudo pt-query-digest $(MYSQL_SLOW_LOG) > $(DIGEST_LOG)
	@./dispost -f $(DIGEST_LOG)

## etc

.PHONY: log
log: ## Tail journalctl
	@sudo journalctl -f

.PHONY: help
help:
	@grep -E '^[a-z0-9A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
