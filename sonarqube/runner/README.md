# The SonarQube runner

A self-hosted GitHub Actions runner that sits next to the SonarQube server, in the server's compose
project. The server is on a LAN and GitHub cannot reach it. The runner can: it connects out to GitHub
over HTTPS and waits there for a job (a long-poll), so nothing has to reach in. A job it takes runs on
this host and reaches the server by its service name, `http://sonarqube:9000`.

It is registered once, on the organization, so every private repository of `eggs-gd` can use it.
A job asks for it with `runs-on: [self-hosted, sonar]`.

## What the host needs

- Docker in the LXC container: `nesting=1` (and `keyctl=1`) in its features. The server already
  needs it.
- `vm.max_map_count` of at least 524288, set on the Proxmox host: the server's Elasticsearch needs it.
- Memory for the server and a job at once: 3–4 GB for SonarQube and PostgreSQL, 2–3 GB for a job at
  its peak (Go tests with `-race`, the front's tests, the scanner).
- 20–30 GB of free disk. The volume starts with a copy of the runner's files from the image (about
  1 GB with the image itself), then grows with a checkout per repository, the Go and Node toolchains,
  and the Go, npm and scanner caches. A disk that fills while the volume is first copied leaves it
  half made (`./run.sh: no such file or directory`): remove the volume and start again.

## Set up

1. Put this folder next to the server's `compose.yml` as `runner/`, and include it there:

   ```yaml
   include:
     - runner/compose.yml
   ```

2. Give the runner the server's analysis token: in SonarQube, **My Account → Security → Generate
   Tokens**, of the type *Global Analysis Token*. Put it in `runner/.env`, readable by root alone:

   ```bash
   printf 'SONAR_TOKEN=%s\n' '<the token>' > runner/.env && chmod 600 runner/.env
   ```

   The runner passes it to its jobs, with the server's address (`SONAR_HOST_URL`, set in
   `compose.yml`). It never goes to GitHub.

3. Get a registration token: **Organization settings → Actions → Runners → New self-hosted runner**.
   It is good for one hour and one registration.

4. Register, once, **from the server's folder** — the one with its `compose.yml`, not `runner/`.
   Compose names a project after the folder it runs in: from `runner/` it would be another project,
   with a volume of its own that the running service never sees.

   ```bash
   docker compose run --rm runner ./config.sh --unattended --replace \
     --url https://github.com/eggs-gd --token <the token> \
     --name sonarqube-runner --labels sonar
   ```

   The registration stays in the volume. The token is not needed again.

5. Start it:

   ```bash
   docker compose up -d --build runner
   ```

   After a change to `runner/.env`, recreate it the same way: a restart keeps the old environment.

   It shows as **Idle** under the organization's runners.

6. In **Organization settings → Actions → Runner groups → Default**, keep public repositories
   **not allowed**. A public repository's pull request could run its code on this host.

## Keeping it

- The runner updates itself when GitHub releases a new version. The image's version only matters
  for the first start.
- When the machine is down, jobs for it wait in the queue, for up to 24 hours. Then they fail. A job
  on this runner is not a required check, so nothing waits on it to merge.
- One runner takes one job at a time.
- To unregister: **Organization settings → Actions → Runners → the runner → Remove**, then remove
  the volume (`docker volume rm <project>_runner_home`).
- A repository of a personal account cannot use an organization's runner. It needs a runner of
  its own: a second service in this file with its own volume, registered on that repository.
