FROM node:26-alpine AS base

FROM base AS build-base
# vips-dev/build-base only needed if sharp or better-sqlite3 fall back to a source build
RUN apk add --no-cache build-base python3 vips-dev
WORKDIR /build
COPY ./package.json ./package-lock.json ./.npmrc ./

FROM build-base AS install-prod
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

FROM build-base AS build
WORKDIR /build/app
COPY ./ .
RUN --mount=type=cache,target=/root/.npm \
    npm ci \
 && npm run build

FROM base AS app-base
RUN apk add --no-cache vips tini
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
COPY --chown=node:node --from=build /build/app/node_modules ./node_modules
CMD [ "npm", "run", "develop" ]

FROM app-base AS prod
COPY --chown=node:node --from=build /build/app/favicon.ico /build/app/package.json /build/app/package-lock.json /build/app/tsconfig.json ./
COPY --chown=node:node --from=install-prod /build/node_modules ./node_modules
COPY --chown=node:node --from=build /build/app/config ./config
COPY --chown=node:node --from=build /build/app/public ./public
COPY --chown=node:node --from=build /build/app/dist ./dist
CMD [ "strapi", "start" ]
