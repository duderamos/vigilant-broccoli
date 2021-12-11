ARG BASE_VERSION=latest

FROM ruby:3.0.1-alpine3.13 AS base

ARG RAILS_ROOT=/app
ARG PACKAGES="tzdata postgresql-libs yarn nodejs"

WORKDIR $RAILS_ROOT

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache $PACKAGES

RUN addgroup -S appgroup \
    && adduser -S appuser -G appgroup

RUN mkdir -p $RAILS_ROOT && chown appuser:appgroup $RAILS_ROOT

USER appuser

############### Build step ###############
FROM ghcr.io/duderamos/vigilant-broccoli:base-${BASE_VERSION} AS build-env

ARG RAILS_ROOT=/app
ARG BUILD_PACKAGES="build-base curl-dev git"
ARG DEV_PACKAGES="postgresql-dev yaml-dev zlib-dev"

ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

USER root

RUN apk add --no-cache $BUILD_PACKAGES $DEV_PACKAGES

COPY Gemfile* ./

RUN bundle config --global frozen 1 \
    && bundle config --local path vendor/bundle \
    && bundle config deployment "true" \
    && bundle config without "development test" \
    && bundle install -j4 --retry 3 \
    && rm -rf vendor/bundle/ruby/3.0.0/cache/*.gem \
    && find vendor/bundle/ruby/3.0.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/3.0.0/gems/ -name "*.o" -delete

COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY . .

RUN set -a \
    && bundle exec rails assets:precompile \
    && bin/webpack

RUN rm -rf tmp/cache spec

RUN mkdir -p $RAILS_ROOT && chown appuser:appgroup $RAILS_ROOT

USER appuser

############### Dev step ###############
FROM ghcr.io/duderamos/vigilant-broccoli:base-${BASE_VERSION} AS dev

ARG RAILS_ROOT=/app
ARG BUILD_PACKAGES="build-base curl-dev git"
ARG DEV_PACKAGES="postgresql-dev yaml-dev zlib-dev"

ENV RAILS_ENV=development
ENV NODE_ENV=development
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

USER root

RUN apk add --no-cache $BUILD_PACKAGES $DEV_PACKAGES

COPY Gemfile* ${RAILS_ROOT}/

RUN bundle install -j4 --retry 3 \
    && bundle config --local path vendor/bundle \
    && bundle install

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000

CMD bin/rails server -b 0.0.0.0

############### Prod step ###############
FROM ghcr.io/duderamos/vigilant-broccoli:base-${BASE_VERSION} AS web

ARG RAILS_ROOT=/app
ENV RAILS_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

COPY --from=build-env $RAILS_ROOT $RAILS_ROOT

USER root

RUN chown -R appuser:appgroup $RAILS_ROOT \
    && chmod +x ./entrypoint.sh

USER appuser

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000

CMD bin/rails server -b 0.0.0.0
