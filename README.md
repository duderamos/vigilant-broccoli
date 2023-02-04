# Vigilant Broccoli

- Copy `.env.sample` to `.env`
- Edit your variables accordingly in `.env`
- Build base image `make build-base`
- Run bootstrap with default Rails new args `make boostrap`
- Or run bootstrap with custom Rails new args `make bootstrap rails_new_args="--skip-tests"`
- Start database with `make start-db`
- Initilise the database with `bin/run rails db:drop db:create db:migrate`
- Start Rails server with `make start-dev`
