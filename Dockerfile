FROM resin/armv7hf-debian-qemu

RUN [ "cross-build-start" ]

RUN apt-get update \
    && apt-get upgrade -y

RUN apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev libssl-dev libgdbm-dev libc6-dev git

SHELL ["/bin/bash", "-c"]

ENV HOME="/root"
ENV NODE_VERSION=11.1.0

RUN wget https://www.openssl.org/source/openssl-1.1.1c.tar.gz \
    && tar xzf openssl-1.1.1c.tar.gz \
    && cd openssl-1.1.1c \
    && ./config --prefix=$HOME \
    && make \
    && make install

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh | bash

RUN [[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh \
    nvm install ${NODE_VERSION} \
    && nvm use v${NODE_VERSION} \
    && nvm alias default v${NODE_VERSION}

ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

RUN wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz \
    && tar xzf Python-3.7.3.tgz \
    && cd Python-3.7.3 \
    && ./configure --prefix=$HOME --with-openssl=/root LDFLAGS="-Wl,-rpath=/root/lib -L/root/lib" \
    && make \
    && make install

ENV PATH="/root/bin:${PATH}"

RUN ln -s /root/bin/python3 /root/bin/python \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python get-pip.py \
    && pip install --upgrade pip

RUN python -m pip install pipenv

RUN apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN mkdir -p /home/theia \
    && mkdir -p /home/project
WORKDIR /home/theia

RUN cd /opt \
    && wget https://yarnpkg.com/latest.tar.gz \
    && tar zvxf latest.tar.gz

ENV PATH="/opt/yarn-v1.22.5/bin:${PATH}"

ARG version=latest
ADD $version.package.json ./package.json
ARG GITHUB_TOKEN
RUN yarn --cache-folder ./ycache && rm -rf ./ycache && \
    NODE_OPTIONS="--max_old_space_size=16344" yarn theia build ; \
    yarn theia download:plugins
EXPOSE 3000
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins
ENTRYPOINT [ "yarn", "theia", "start", "/home/project", "--hostname=0.0.0.0" ]

RUN [ "cross-build-end" ]  