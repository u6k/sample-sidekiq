# Sidekiqサンプル _(sample-sidekiq)_

[![GitHub tag](https://img.shields.io/github/tag/u6k/sample-sidekiq.svg)](https://github.com/u6k/sample-sidekiq/releases)
[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

> Sidekiqのサンプル。

## Install

Dockerを使用します。あらかじめインストールしておいてください。

```
$ sudo docker version
Client:
 Version:       18.03.0-ce
 API version:   1.37
 Go version:    go1.9.4
 Git commit:    0520e24
 Built: Wed Mar 21 23:10:06 2018
 OS/Arch:       linux/amd64
 Experimental:  false
 Orchestrator:  swarm

Server:
 Engine:
  Version:      18.03.0-ce
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.9.4
  Git commit:   0520e24
  Built:        Wed Mar 21 23:08:35 2018
  OS/Arch:      linux/amd64
  Experimental: false
```

他のソフトウェアは、全てDockerコンテナ内でインストールするので、ホストPCにインストールする必要はありません。

## Development

まっさらの状態からSidekiqのワーカーを実行するまでの手順を説明します。

### Railsプロジェクトを作成

Railsプロジェクトを作成します。RubyがインストールされているPCであれば `rails new .` で済みますが、ここではrubyコンテナの中でRailsプロジェクトを作成します。

まず、rubyコンテナを起動します。

```
$ sudo docker run --rm -it -v $(pwd):/var/myapp -w /var/myapp ruby bash
```

`-v` オプションで、カレント・フォルダをコンテナ内の `/var/myapp` フォルダに割り当てます。そして `-w` オプションで、コンテナ起動直後の作業フォルダを `/var/myapp` フォルダに設定しています。

Ruby on Railsをインストールします。

```
# gem install rails
```

カレント・フォルダにRailsプロジェクトを作成します。

```
# rails new .
```

作成したら、 `ls` でファイルを確認してみます。ファイルを確認したら、 `Ctrl-d` でコンテナからログアウトします。

### Gemfileに `sidekiq` を追加

Sidekiqはgemで提供されているので、 `Gemfile` ファイルに追加します。

```
gem 'sidekiq'
```

また、 `Gemfile` ファイルの余計なコメント行を削除します。結果、次のように修正します(バージョンは当サンプル作成時期により異なります)。

```
$ cat Gemfile
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

gem 'rails', '~> 5.2.0'
gem 'sqlite3'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'sidekiq'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
```

### Dockerコンテナ化

`rails` コマンドを使用したり動作確認するため、早々にDockerコンテナ化します。

簡単にSidekiqを使用したコンテナ構造を説明すると、次のように構成します。ちなみに、今回はRailsアプリケーションが使用するDBとしてSQLiteを指定しているため、DBコンテナは構成しません。

TODO: コンテナ構造をコンポーネント図で説明

まず、アプリケーション用コンテナの `Dockerfile` ファイルを作成します。

```
$ cat Dockerfile
FROM ruby:2.5

RUN apt-get update && \
    apt-get install -y \
        nodejs && \
    apt-get clean

VOLUME /var/myapp
WORKDIR /var/myapp

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
```

次に、上図で説明したコンテナ構造を構成するため、 `docker-compose.yml` ファイルを作成します。

```
$ cat docker-compose.yml
version: '3'

services:
  app:
    build: .
    environment:
      - "RAILS_ENV=development"
      - "REDIS_URL=redis://redis:6379"
    volumes:
      - ".:/var/myapp"
    ports:
      - "3000:3000"
    depends_on:
      - "redis"
  worker:
    build: .
    environment:
      - "RAILS_ENV=development"
      - "REDIS_URL=redis://redis:6379"
    volumes:
      - ".:/var/myapp"
    depends_on:
      - "redis"
    command: sidekiq
  redis:
    image: redis:4.0
    volumes:
      - "redis:/data"
    command: redis-server --appendonly yes

volumes:
  redis:
    driver: local
```

手順が間違えていなければ、イメージをビルドして、Railsアプリケーションを起動することができます。試しに、動作確認してみます。

イメージをビルドします。

```
$ sudo docker-compose build
```

コンテナを起動します。

```
$ sudo docker-compose up -d
```

Webブラウザで http://localhost:3000 を開くか `curl` コマンドでGETリクエストすると、Welcomeページが表示されます。

TODO: 作成手順を説明する。

## Links

TODO: 参照先リンク

## Maintainer

- u6k
  - [Blog](https://blog.u6k.me)
  - [GitHub](https://github.com/u6k)
  - [Qiita](http://qiita.com/u6k)
  - [Twitter](https://twitter.com/u6k_yu1)
  - [Facebook](https://www.facebook.com/yuuichi.naono)

## Contribute

ライセンスの範囲内でご自由にご利用ください。

## License

[MIT License](https://github.com/u6k/sample-sidekiq/blob/master/LICENSE)
