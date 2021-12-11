# Vigilant Broccoli

```
docker-compose build web-dev
docker-compose run --no-deps -u $(id -u) --rm web-dev rails new . --force -d postgresql
docker-compose run --no-deps -u $(id -u) --rm web-dev rails db:drop db:create db:migrate
```
