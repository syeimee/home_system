FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    libjemalloc2 \
    libyaml-dev \
    pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
