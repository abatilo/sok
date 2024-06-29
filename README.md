# sok

Learning how to run Slurm on Kubernetes.

The intention of this repo is to experiment with building, and deploying Slurm
on Kubernetes. This is strictly an educational repository for me to learn in.

## Building the docker images

I'm working on an M2 Macbook Pro. Even using the Docker desktop rosetta
emulation, I have been unable to successfully simulate a native linux/amd64
build for the debian packages for Slurm. As such, I've resorted to using a
remote buildkit agent to build the images. I'm doing so using the Kubernetes
driver since I have an EKS cluster that I use for development.

```
⇒  docker buildx create --name remote-buildkit-agent --bootstrap --use --driver kubernetes --driver-opt requests.cpu=8 --driver-opt requests.memory=16Gi --driver-opt limits.memory=16Gi
```

I've actually written more about remote buildkit agents on my newsletter. You
can find the full length post
[here](https://www.sliceofexperiments.com/p/a-comprehensive-guide-for-the-fastest).
