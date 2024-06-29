variable "GITHUB_SHA" { default = "latest" }
variable "SLURM_VERSION" { default = "24.05.1" }

group "default" {
  targets = [
    "slurm",
  ]
}

target "slurm" {
  matrix = {
    app = [
      { name = "slurmdbd",  },
      { name = "slurmctld", },
      { name = "slurmd",    },
      { name = "login",     },
    ]
  }

  name = "${app.name}"
  args = {
    SLURM_VERSION = "${SLURM_VERSION}"
  }
  target = "${app.name}"
  output = [
    "type=image,name=ghcr.io/abatilo/sok/${app.name}:${GITHUB_SHA},rewrite-timestamp=true,oci-mediatypes=true,compression=zstd,compression-level=22,force-compression=true",
  ]
  tags = [
    "ghcr.io/abatilo/sok/${app.name}:${GITHUB_SHA}"
  ]

  cache-from = ["type=registry,ref=ghcr.io/abatilo/sok/${app.name}:buildcache"]
  cache-to = ["type=registry,ref=ghcr.io/abatilo/sok/${app.name}:buildcache,mode=max"]
}
