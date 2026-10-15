# 🚀 Getting started with Strapi

Strapi comes with a full featured [Command Line Interface](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html) (CLI) which lets you scaffold and manage your project in seconds.

## 🧰 Setup

Before you start, install all dependencies and create `.env.local` file which is .gitignored used for local dev

```
yarn
cp .env.example .env.local
```

You need postgres running locally (with correct credentials & databse available). The default setup is below, you can override any of the variables by passing them in you `.env.local` file. The easiest way to get a postgres db with the right credentials up&running is via `docker-compose.yml` file in the root fo this repo (check the root README).

### Starting from empty database

While not recommended in this project, if you want to start from a clean slate, read (TODO - writing in progress on the doc site).

### Seeding the database

It's recommended that you don't start from an empty database, but instead seed with staging or production data. Ask in the internal Bratislava team or [follow the docs](https://bratislava.github.io/docs/recipes/load-strapi-db-in-local-dev). If you are an open-source contributor, note you do not need this setup for many of frontend-related changes. See the next.js project README.

We may provide a db dump as part of the project in the future - for now please contact the BA Innovations Team if you need it.


## Patches

We use [patch-package](https://github.com/ds300/patch-package) to slightly change the behaviour of some packages. See the `patches` folder for more details.

When updating these packages, please run also `patch-package`:
```
yarn patch-package @strapi/plugin-users-permissions
```

## Deployment

Deployed by [infrastructure-deployment-configuration](https://github.com/bratislava/infrastructure-deployment-configuration) (`clusters/<cluster>/applications/general-strapi`). A push to `master` deploys staging; `dev*`, `staging*` and `prod*` tags deploy that cluster.

Non-secret runtime env lives in `.env.deploy.<cluster>`, read at the image's commit. Secrets live in Passbolt under `/kubernetes/general-strapi`.

## On-demand revalidation

To implement on-demand revalidation, we need to add webhook url from strapi admin panel. The route of the url should be like below:

```
https://<host>/api/revalidate?secret=<STRAPI_REVALIDATE_SECRET_TOKEN>
```
