# The organization's self-hosted GitHub Actions runner for the SonarQube analysis: the official
# runner image and the few tools the analysis jobs call. Go, Node and the scanner come from the jobs'
# own setup actions, into the runner's home (a volume), and stay cached there.
FROM ghcr.io/actions/actions-runner:2.338.2

USER root
RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates git make unzip \
	&& rm -rf /var/lib/apt/lists/*
USER runner

CMD ["./run.sh"]
