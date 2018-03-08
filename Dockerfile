FROM debian:8.9
LABEL maintainer="labbsr0x"

# Declare Arguments
ARG NODE_VERSION
ARG METEOR_RELEASE
ARG METEOR_EDGE
ARG USE_EDGE
ARG NPM_VERSION
ARG FIBERS_VERSION
ARG ARCHITECTURE
ARG SRC_PATH

# Set the environment variables (defaults where required)
ENV BUILD_DEPS="wget curl bzip2 build-essential python git ca-certificates gcc-4.9"
ENV GOSU_VERSION=1.10
ENV NODE_VERSION ${NODE_VERSION:-v4.8.4}
ENV METEOR_RELEASE ${METEOR_RELEASE:-1.4.4.1}
ENV USE_EDGE ${USE_EDGE:-false}
ENV METEOR_EDGE ${METEOR_EDGE:-1.5-beta.17}
ENV NPM_VERSION ${NPM_VERSION:-4.6.1}
ENV FIBERS_VERSION ${FIBERS_VERSION:-1.0.15}
ENV ARCHITECTURE ${ARCHITECTURE:-linux-x64}
ENV SRC_PATH ${SRC_PATH:-./}
ENV METEOR_PROFILE=100
ENV METEOR_LOG=debug

RUN \
    # Add non-root user ldap
    useradd --user-group --system -m ldap && \
    \
    # OS dependencies
    apt-get update -y && apt-get install -y --no-install-recommends ${BUILD_DEPS} && \
    \
    # Gosu installation
    GOSU_ARCHITECTURE="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${GOSU_ARCHITECTURE}" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${GOSU_ARCHITECTURE}.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -R "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    \
    # Download nodejs
    wget https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-${ARCHITECTURE}.tar.gz && \
    wget https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc && \
    \
    # Verify nodejs authenticity
    grep ${NODE_VERSION}-${ARCHITECTURE}.tar.gz SHASUMS256.txt.asc | shasum -a 256 -c - && \
    export GNUPGHOME="$(mktemp -d)" && \

    # Try other key servers if ha.pool.sks-keyservers.net is unreachable
    # Code from https://github.com/chorrell/docker-node/commit/2b673e17547c34f17f24553db02beefbac98d23c
    # gpg keys listed at https://github.com/nodejs/node#release-team
    # and keys listed here from previous version of this Dockerfile
    for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done && \
    gpg --verify SHASUMS256.txt.asc && \
    rm -R "$GNUPGHOME" SHASUMS256.txt.asc && \
    \
    # Install Node
    tar xvzf node-${NODE_VERSION}-${ARCHITECTURE}.tar.gz && \
    rm node-${NODE_VERSION}-${ARCHITECTURE}.tar.gz && \
    mv node-${NODE_VERSION}-${ARCHITECTURE} /opt/nodejs && \
    ln -s /opt/nodejs/bin/node /usr/bin/node && \
    ln -s /opt/nodejs/bin/npm /usr/bin/npm && \
    \
    # Install Node dependencies
    npm install -g npm@${NPM_VERSION} && \
    npm install -g node-gyp && \
    npm install -g fibers@${FIBERS_VERSION} && \
    \
    # Change user to ldap and install meteor
    cd /home/ldap/ && \
    chown ldap:ldap --recursive /home/ldap && \
    curl https://install.meteor.com -o ./install_meteor.sh && \
    sed -i "s|RELEASE=.*|RELEASE=${METEOR_RELEASE}\"\"|g" ./install_meteor.sh && \
    echo "Starting meteor ${METEOR_RELEASE} installation...   \n" && \
    chown ldap:ldap ./install_meteor.sh && \
    \
    # Check if opting for a release candidate instead of major release
    if [ "$USE_EDGE" = false ]; then \
    gosu ldap:ldap sh ./install_meteor.sh; \
    else \
    gosu ldap:ldap git clone --recursive --depth 1 -b release/METEOR@${METEOR_EDGE} git://github.com/meteor/meteor.git /home/ldap/.meteor; \
    fi; \
    \
    # Get additional packages
    mkdir -p /home/ldap/app/packages && \
    chown ldap:ldap --recursive /home/ldap && \
    cd /home/ldap/app/packages && \
    cd /home/ldap/.meteor && \
    gosu ldap:ldap /home/ldap/.meteor/meteor -- help;

WORKDIR /home/ldap/app

RUN ln -s /home/ldap/.meteor/meteor /usr/local/bin/meteor



COPY \
    src/.meteor/.finished-upgraders \
    src/.meteor/.id \
    src/.meteor/packages \
    src/.meteor/platforms \
    src/.meteor/release \
    src/.meteor/versions \
    .meteor/

RUN \
    groupmod -g 1000 ldap && \
    usermod -u 1000 ldap && \
    usermod -g 1000 ldap && \
    chown -R ldap:ldap /home/ldap && \
    chmod g+s /home/ldap && \
    gosu ldap /home/ldap/.meteor/meteor build --directory /home/ldap/app_build

COPY src/package.json /home/ldap/app/package.json
RUN meteor npm install --save @babel/runtime

ENV PORT=3000
EXPOSE $PORT

RUN \
    chown ldap:ldap --recursive .meteor

USER ldap
CMD ["/home/ldap/.meteor/meteor", "run", "--verbose"]