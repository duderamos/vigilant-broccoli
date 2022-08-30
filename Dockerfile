ARG BASE_VERSION=latest
ARG IMAGE_NAME
ARG RUBY_VERSION=3.0.2-alpine3.13

FROM ruby:${RUBY_VERSION} AS base

ARG RAILS_ROOT=/app
ARG RUNTIME_PACKAGES="tzdata postgresql-libs"

WORKDIR $RAILS_ROOT

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache $RUNTIME_PACKAGES

RUN addgroup -S appgroup \
    && adduser -S appuser -G appgroup

RUN mkdir -p $RAILS_ROOT && chown appuser:appgroup $RAILS_ROOT

USER appuser

############### Build step ###############
FROM ${IMAGE_NAME}:base-${BASE_VERSION} AS build-env

ARG RAILS_ROOT=/app
ARG BUILD_PACKAGES="build-base curl-dev git"
ARG DEV_PACKAGES="postgresql-dev yaml-dev zlib-dev yarn nodejs"

ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

USER root

RUN apk add --no-cache $BUILD_PACKAGES $DEV_PACKAGES

USER appuser

COPY --chown=appuser:appgroup Gemfile* .

RUN bundle config --global frozen 1 \
    && bundle config --local path vendor/bundle \
    && bundle config deployment "true" \
    && bundle config without "development test" \
    && bundle install --retry 3 \
    && rm -rf vendor/bundle/ruby/*/cache/*.gem \
    && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

COPY --chown=appuser:appgroup package.json yarn.lock .

RUN yarn install --frozen-lockfile

COPY --chown=appuser:appgroup . .

RUN set -a \
    && bundle exec rails assets:precompile \
    && yarn run build \
    && yarn run build:css

RUN rm -rf tmp/cache spec node_modules

############### Dev step ###############
FROM ${IMAGE_NAME}:base-${BASE_VERSION} AS dev

ARG RAILS_ROOT=/app
ARG BUILD_PACKAGES="build-base curl-dev git"
ARG DEV_PACKAGES="postgresql-dev yaml-dev zlib-dev yarn nodejs bash"

ENV RAILS_ENV=development
ENV NODE_ENV=development

USER root

RUN apk add --no-cache $BUILD_PACKAGES $DEV_PACKAGES

USER appuser

ENTRYPOINT ["./entrypoint.sh"]

############### Prod step ###############
FROM ${IMAGE_NAME}:base-${BASE_VERSION} AS web

ARG RAILS_ROOT=/app
ENV RAILS_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

COPY --chown=appuser:appgroup --from=build-env $RAILS_ROOT $RAILS_ROOT

USER root

RUN chown -R appuser:appgroup $RAILS_ROOT \
    && chmod +x ./entrypoint.sh

USER appuser

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000

CMD bin/rails server -b 0.0.0.0
