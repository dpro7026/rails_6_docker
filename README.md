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

### Add RSpec Testing Framework for TDD
Add to the `Gemfile` into the group :development, :test do:
```
# Testing framework
gem 'rspec-rails'
```
Re-build the container after updating `Gemfile`:
```
docker-compose build
```
Generate the RSpec configuration:
```
docker-compose run railsapp rails generate rspec:install
```
Ensure the correct version of RSpec is used:
```
docker-compose run railsapp bundle binstubs rspec-core
```

Create a new folder `spec/features` and 3 new files:
`create_survey_spec.rb`, `delete_survey_spec.rb` and `edit_survey_spec.rb`.</br>
Let's begin TDD by adding a test scenario to `create_survey_spec.rb`:
```
require "rails_helper"

RSpec.feature "Creating Survey" do
  scenario "A user creates a new survey" do
    visit "/"

    click_link "New Survey"
    fill_in "Title", with: "What is your fave Pokemon?"
    fill_in "Field 1", with: "Bulbasaur"
    fill_in "Field 2", with: "Squirtle"
    fill_in "Field 3", with: "Charmander"
    click_button "Create Survey"

    expect(page).to have_content("Survey has been created")
    expect(page.current_path).to eq(surveys_path)
  end
end
```
To ensure test code coverage we add to the `Gemfile`:
```
group :test do
  ...
  # Code coverage
  gem 'simplecov', require: false
end
```
We don't want to upload the coverage reports to Git, so add to `.gitignore`:
```
#Ignore coverage files
coverage/*
```
At the top of `spec/spec_helper.rb`:
```
require 'simplecov'
SimpleCov.start 'rails' do
  # These filters are excluded from results
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/test/'
  add_filter do |source_file|
    source_file.lines.count < 5
  end
end
```
Now when you run RSpec you will see the code coverage and generate a report in the coverage folder.</br>
Let's use Brakeman for static analysis by adding to the `Gemfile`:
```
group :development do
  ...
  # Static security vulnerability analysis
  gem 'brakeman'
end
```
Now re-build:
```
docker-compose build
```
To run RSpec:
```
docker-compose run railsapp rspec
```
To run Brakeman and store it's report in our coverage folder:
```
docker-compose run railsapp brakeman -o coverage/brakeman_report
```
To view SimpleCov report:
```
open coverage/index.html
```

## Authors

**David Provest** - [LinkedIn](https://www.linkedin.com/in/davidjprovest/)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details