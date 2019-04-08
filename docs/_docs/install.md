---
title: Installation
nav_order: 7
---

## RubyGems

Install jets via RubyGems.

    gem install jets

## Prerequisites and Dependencies

### Ruby

Jets uses Ruby 2.5, and code written with patch variants of it should also work.

### Yarn

For apps with HTML pages, jets uses [webpacker](https://github.com/rails/webpacker) to compile assets, which requires yarn.  [Node version manager](https://github.com/creationix/nvm), nvm, is recommended if you want to manage node versions.

    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
    # note follow the instructions after the curl command to source nvm
    nvm install 8.10.0 # please check AWS Lambda for the latest node runtime
    nvm alias default node # sets the default version

Once node is installed, install yarn with:

    npm install -g yarn

You can use any version of yarn that works with webpacker.

## Database

By default, when you run a `jets new` command, Jets calls `bundle install` and attempts to install the `mysql2` gem. If you want to use PostgreSQ, run `jets new --database=postgresql`. Make sure that you have mySQL or PostgreSQL installed beforehand.

If you don't need an ORM database adapter, or want to use another database, use the `jets new --no-database` option. You can subsequently add any datastore adapter gem to the Gemfile and run `bundle install`.

Here are the instructions to install MySQL and PostgreSQL:

### MySQL

    brew install mysql # macosx
    yum install -y mysql-devel # amazonlinux2 and redhat variants
    apt-get install -y libmysqlclient-dev # ubuntu and debian variants

### PostgreSQL

    brew install postgresql # macosx
    yum install -y postgresql-devel # amazonlinux2 and redhat variants
    apt-get install libpq-dev # ubuntu and debian variants

### AWS CLI

The AWS CLI is not required but is strongly recommended so that you can make use of AWS Profiles. You can install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) via pip.

    pip install awscli --upgrade --user

Then [configure it](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

    aws configure

{% include prev_next.md %}