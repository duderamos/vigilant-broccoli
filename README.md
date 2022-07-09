# Vigilant Broccoli

- Copy `.env.sample` to `.env`
- Edit your variables accordingly in `.env`
- Review bootstrap script and update the `rails new` command as you wish
- Run bootstrap script `bin/bootstrap`
- Start database with `docker compose up -d postgres`
- Initilise the database with `bin/run rails db:drop db:create db:migrate`
- Start Rails server with `docker compose up web-dev`
