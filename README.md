# Vigilant Broccoli

```
docker-compose build web-dev
docker-compose run --no-deps -u $(id -u) --rm --entrypoint "" web-dev rails new . --force -d postgresql -j esbuild -c tailwind --skip-test --skip-system-test
docker-compose run -u $(id -u) --rm web-dev rails db:drop db:create db:migrate
```
