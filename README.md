# Janus Gateway development with Docker

This repo contains development environment for convenient development to [Janus Gateway](https://github.com/meetecho/janus-gateway) core (don't mess with [Janus Conference](https://github.com/netology-group/janus-conference) plugin).

Janus Gateway is being maintained by [Meetecho](https://github.com/meetecho) and sometimes we send pull requests in C for them. For that purpose we have a [fork](https://github.com/netology-group/janus-gateway) however we must not include our development environment (dockerfiles, configs, etc.) in those PRs so we store it here in a separate repo and the fork repo is mounted as a git submodule.

## How to make a PR to Janus Gateway

Say, you need to make changes in the Janus Gateway codebase.

1. Clone this repo and `cd` to it:

```bash
git clone git@github.com:netology-group/janus-gateway-dev.git
cd janus-gateway-dev
```

2. Copy `docker/janus.plugin.conference.environment.sample` as `janus.plugin.conference.environment` and fill in actual values.

3. Add Meetecho's repo as upstream to the submodule:

```bash
cd janus-gateway
git remote add upstream https://github.com/meetecho/janus-gateway.git
```

4. Fetch the latest changes from the upstream, merge them to the fork's master branch and push to start from the latest version:

```bash
git fetch upstream
git merge upstream/master
git push origin master
```

5. Create a new branch:

```bash
git checkout -b my-feature
```

6. Make your changes in the C codebase.

7. `cd` to the repo's root and run `docker-compose` to build and start Janus Gateway with your changes + Janus Conference plugin along with VerneMQ broker + MQTT Gateway plugin:

```bash
cd ..
export COMPOSE_FILE=docker/docker-compose.yml
docker-compose up
```

8. If everything compiled and started properly test your feature and basic Janus Conference scenarios manually.
**WARNING:** Janus Conference plugin may be outdated in this repo. You may need to update the version in `docker/develop.dockerfile`.

9. Commit and push your changes into the fork repository:

```bash
cd janus-gateway
git add .
git commit -m "Add some awesome stuff"
git push origin my-feature
```

10. Open the [fork repo](https://github.com/netology-group/janus-gateway) on GitHub and create a pull request to the Meetecho's repo.

11. If you can't wait for the PR to be merged you can temporarily switch to the fork repo in [Janus Conference](https://github.com/netology-group/janus-conference). For that change [Dockerfile](https://github.com/netology-group/janus-conference/blob/master/docker/Dockerfile) and [develop.dockerfile](https://github.com/netology-group/janus-conference/blob/master/docker/develop.dockerfile) by changing `https://github.com/meetecho/janus-gateway` to `https://github.com/netology-group/janus-gateway` and setting `JANUS_GATEWAY_COMMIT` to your branch's head.

12. When [Lorenzo](https://github.com/lminiero) from Meetecho merges the PR you should update `JANUS_GATEWAY_COMMIT` to the latest SHA1 from Meetecho's repo master branch and switch back to that repo if you have switched to the fork in the previous step. Build and test it again before pushing/deploying because other commits might been made in Janus Gateway that could break some things.
