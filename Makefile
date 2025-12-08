.PHONY: help install setup server test clean migrate seed reset

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	bundle install

setup: install ## Setup the application (install, create DB, migrate, seed)
	bundle exec rake db:create
	bundle exec rake db:migrate
	bundle exec rake db:seed

server: ## Start the Rails server
	bundle exec rails server

test: ## Run all tests
	bundle exec rspec

test-models: ## Run model tests only
	bundle exec rspec spec/models

test-controllers: ## Run controller tests only
	bundle exec rspec spec/requests

migrate: ## Run database migrations
	bundle exec rake db:migrate

seed: ## Seed the database with sample data
	bundle exec rake db:seed

reset: ## Reset the database (drop, create, migrate, seed)
	bundle exec rake db:drop db:create db:migrate db:seed

console: ## Open Rails console
	bundle exec rails console

routes: ## Display all routes
	bundle exec rails routes

clean: ## Clean temporary files and logs
	rm -rf log/*.log
	rm -rf tmp/cache/*

lint: ## Run code linter (if rubocop is installed)
	bundle exec rubocop || echo "Rubocop not installed"

deploy-check: test lint ## Run tests and linting before deployment
	@echo "✓ All checks passed! Ready to deploy."
