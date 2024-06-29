allow_k8s_contexts("red")

custom_build(
  'ghcr.io/abatilo/sok/slurmctld',
  'GITHUB_SHA=$EXPECTED_TAG docker buildx bake slurmctld --push',
  ['Dockerfile', 'docker-bake.hcl'],
  skips_local_docker=True,
  disable_push=True
)

k8s_yaml(kustomize('./manifests/'))
