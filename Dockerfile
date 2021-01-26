FROM ruby:alpine
RUN apk update && apk add --update build-base postgresql-dev nodejs tzdata
RUN gem install rails -v 6.1.1
WORKDIR /railsapp
ADD Gemfile Gemfile.lock /railsapp/
RUN bundle install
