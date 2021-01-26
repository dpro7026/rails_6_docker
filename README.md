# Rails 6 with Docker Compose

## Prerequisites

Requires `Docker` and `Docker-compose` installed on your environment.<br/>
You can use the `install_docker_compose.sh` script to setup your environment.

## Installing & Running

Installation uses Docker Compose:

```
docker-compose build
docker-compose up
docker-compose run railsapp rails db:create
```
<strong>Note: Running on AWS Cloud9 additionally requires running the following 2 scripts</strong>
<br/>
Expose the port 3000 to be publicly accessible:
```
./cloud9.sh
```
And get the URL:
```
./get_url.sh
```

## Stopping the App

```
docker-compose down
```

## Step-by-step of Development

### Create the Rails App in a Docker Container
Create a `Dockerfile` containing a small image of ruby, add additional packages and install Rails 6.1.1:
```
FROM ruby:alpine
RUN apk update && apk add --update build-base postgresql-dev nodejs tzdata
RUN gem install rails -v 6.1.1
```
Describe the 2 services (railsapp and postgres) by creating a `docker-compose.yml` containing:
```
version: '3'

services:
  postgres:
    container_name: postgres
    image: postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      PGDATA: /data/postgres
    networks:
      - common-network
    volumes:
       - postgres:/data/postgres
    restart: unless-stopped

  railsapp:
    container_name: railsapp
    build: .
    working_dir: /railsapp
    image: dprovest/rails_recipe:latest
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    ports:
      - 3000:3000
    expose:
      - 3000
    depends_on:
      - postgres
    networks:
      - common-network
    volumes:
      - ./:/railsapp
    restart: on-failure

networks:
  common-network:
    driver: bridge

volumes:
  railsapp:
  postgres:

```
Build the image and then create the rails skeleton app (skipping Javascript files):
```
docker-compose build railsapp
docker-compose run railsapp rails new --database=postgresql -J .
```
Update the `Dockerfile` to copy over the `Gemfile` and `Gemfile.lock` and install the gems:

```
WORKDIR /railsapp
ADD Gemfile Gemfile.lock /railsapp/
RUN bundle install
```
Now build the updated `Dockerfile` and start up the app:
```
docker-compose build
docker-compose up
```
Configure the database by replacing the contents of `config/database.yml` with:
```
default: &default
  adapter: postgresql
  encoding: unicode
  host: postgres
  username: postgres
  password: postgres
  pool: 5

development:
  <<: *default
  database: railsapp_development

test:
  <<: *default
  database: railsapp_test
```
Start the web app (using the daemon):
```
docker-compose up -d
```
Finally create the database:
```
docker-compose run railsapp rails db:create
```
Visit *localhost:3000* and see the Hello World Rails app is running.</br>
Note: To stop the app use `docker-compose down` and restart it with `docker-compose up`</br>

## Authors

**David Provest** - [LinkedIn](https://www.linkedin.com/in/davidjprovest/)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
