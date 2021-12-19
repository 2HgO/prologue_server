export PWD=$(shell pwd)

.PHONY: app
app:
	@docker-compose up app mongo

.PHONY: docs
docs:
	@docker-compose up docs
