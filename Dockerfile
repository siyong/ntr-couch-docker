# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

FROM ubuntu:14.04

ENV COUCHDB_VERSION 2.1.1
ENV MAVEN_VERSION 3.5.2
ENV DEBIAN_FRONTEND noninteractive
ENV MAVEN_HOME /usr/share/maven

RUN mkdir /couchdb && groupadd -r couchdb && useradd -d /couchdb -g couchdb couchdb

RUN apt-get update -y \
  && apt-get install -y apt-utils \
  && apt-get install -y --no-install-recommends \
  python \
  build-essential \
  apt-transport-https \
  gcc \
  g++ \
  libcurl4-openssl-dev \
  libicu-dev \
  libmozjs185-dev \
  make \
  libmozjs185-1.0 \
  libnspr4 libnspr4-0d libnspr4-dev \
  openssl \
  curl \
  ca-certificates \
  git \
  pkg-config \
  wget \
  libicu52 \
  python-sphinx \
  # texlive-base \
  # texinfo \
  # texlive-latex-extra \
  # texlive-fonts-recommended \
  # texlive-fonts-extra \
  libwxgtk2.8-0 \
  openjdk-7-jdk \
  procps
  
RUN wget -nv  http://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_18.1-1~ubuntu~precise_amd64.deb
RUN dpkg -i esl-erlang_18.1-1~ubuntu~precise_amd64.deb

# install maven
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g grunt-cli

# get couchdb source
RUN mkdir /usr/src/couchdb && cd /usr/src/couchdb \
  && git clone https://github.com/siyong/couchdb . \
  && git checkout 350f5919685c82e821bb69110fd21fa4d7e101b9

# compile and install couchdb
RUN cd /usr/src/couchdb \
  && ./configure -c --disable-docs \
  && make release \
  && mv /usr/src/couchdb/rel/couchdb /couchdb


# get, compile and install clouseau
RUN mkdir /clouseau && chown -R couchdb:couchdb /clouseau /couchdb

USER couchdb
RUN cd /clouseau \
  && git clone https://github.com/siyong/clouseau . \
  && mvn -D maven.test.skip=true install

USER root

# Cleanup build detritus
RUN apt-get purge -y --auto-remove apt-transport-https \
  gcc \
  g++ \
  libcurl4-openssl-dev \
  libicu-dev \
  libmozjs185-dev \
  make \
  && rm -rf /var/lib/apt/lists/* /usr/src/couchdb*

COPY ./config/local.ini /couchdb/etc/local.d/
COPY ./config/vm.args /couchdb/etc/
RUN chown -R couchdb:couchdb /couchdb/etc/local.d/ /couchdb/etc/vm.args

RUN mkdir /couchdb/data
VOLUME ["/couchdb/data"]

EXPOSE 5984

WORKDIR /couchdb

COPY ./start-couchdb /couchdb/
RUN chmod +x /couchdb/start-couchdb
COPY ./start-clouseau /couchdb/
RUN chmod +x /couchdb/start-clouseau
# COPY ./karma /couchdb/
# RUN chmod +x /couchdb/karma

# Setup directories and permissions
RUN chown -R couchdb:couchdb /couchdb

USER couchdb

RUN mkdir /clouseau/target/clouseau1
VOLUME ["/clouseau/target/clouseau1"]

ENTRYPOINT ["/couchdb/bin/couchdb"]
