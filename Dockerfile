FROM node:20.20-alpine AS base
# node 20.20 bundles npm 10.8.2; min-release-age in .npmrc needs npm >= 11.10.0
RUN npm install -g npm@11.21.0 \
 && npm cache clean --force

FROM base AS build-base
RUN apk update \
 && apk add --no-cache build-base \
                       gcc \
                       autoconf \
                       automake \
                       zlib-dev \
                       libpng-dev \
                       vips-dev
# sharp 0.32 cannot compile against the libvips/musl shipped with the Alpine
# releases node 20 images use, so use sharp's prebuilt libvips instead.
ENV SHARP_IGNORE_GLOBAL_LIBVIPS=1
WORKDIR /build
COPY ./package.json ./package-lock.json ./.npmrc ./
# Uncomment if you need any to apply any patches
# COPY patches ./patches
# copy any installation files for Strapi plugins you want to build. For example:
# COPY src/plugins/<package-name>/package.json src/plugins/<package-name>/package-lock.json ./src/plugins/<package-name>
# Or leave empty (do not add anyting) if you don't have any custom plugins (most likely ./plugins directory)

FROM build-base AS install-prod
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --fetch-timeout=600000

FROM install-prod AS build
WORKDIR /build/app
COPY ./ .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --fetch-timeout=600000 \
 && npm run build

FROM base AS app-base
RUN apk add --no-cache vips-dev \
                       tini
RUN mkdir -p /home/node/app \
 && chown node:node /home/node/app
USER node
WORKDIR /home/node/app
# Adds strapi cli to the PATH
ENV PATH=/home/node/app/node_modules/.bin:$PATH
ENV NODE_ENV=production
EXPOSE 1337
ARG GIT_COMMIT="undefined"
ENV GIT_COMMIT=$GIT_COMMIT
LABEL org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.source="https://github.com/bratislava/general-strapi" \
      org.opencontainers.image.licenses="EUPL-1.2"
ENTRYPOINT [ "/sbin/tini", "--" ]

FROM app-base AS dev
ENV NODE_ENV=development
COPY --chown=node:node --from=build /build/node_modules ./node_modules
CMD [ "npm", "run", "develop" ]

FROM app-base AS prod
COPY --chown=node:node --from=build /build/app/favicon.ico /build/package.json /build/package-lock.json /build/app/tsconfig.json ./
COPY --chown=node:node --from=install-prod /build/node_modules ./node_modules
COPY --chown=node:node --from=build /build/app/config ./config
COPY --chown=node:node --from=build /build/app/public ./public
COPY --chown=node:node --from=build /build/app/dist ./dist
# COPY to final image any built Strapi plugins. In this stage you will *ONLY* need
# - plugins/<name>/package-lock.json
# - plugins/<name>/package.json
# - plugins/<name>/dist/
# - plugins/<name>/*.js
# Or leave empty (do not add anyting) if you don't have any custom plugins (most likely ./plugins directory)
CMD [ "strapi", "start" ]
