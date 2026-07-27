# DevOps

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flask service packaged as a container, provisioned locally with Terraform, deployable to
Kubernetes, and scanned by CodeQL and Dependabot on every push.

The subject of this repository is the delivery path, not the application. The service is
deliberately small so that the container, infrastructure and pipeline definitions stay
readable and reviewable.

## Layout

```
app.py                        Flask application factory and health endpoints
Dockerfile                    Container image, runs gunicorn as an unprivileged user
versions.tf                   Terraform and provider version constraints
variables.tf                  Input variables with validation
main.tf                       Network, image and container resources
outputs.tf                    Resolved image, network and host endpoints
k8s/deployment.yaml           Deployment and Service manifests
tests/test_app.py             Unit tests for the HTTP surface
.github/workflows/ci.yml      Tests, Terraform validation, image build
.github/workflows/security.yml CodeQL static analysis
docs/architecture.html        Standalone architecture diagram
```

## Running locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

pytest -q
python3 app.py
```

The development server binds to `127.0.0.1:5000`. Containers run under gunicorn instead;
see the `CMD` in the Dockerfile.

## Endpoints

| Path       | Purpose                                    |
| ---------- | ------------------------------------------ |
| `/`        | Service name and version                   |
| `/healthz` | Liveness probe, used by Docker and Kubernetes |
| `/readyz`  | Readiness probe                            |

## Container

```bash
docker build -t devops-app:latest .
docker run --rm -p 8080:5000 devops-app:latest
```

The image runs as UID 1001, installs no build toolchain, and declares a `HEALTHCHECK`
against `/healthz`.

## Terraform

Terraform drives the local Docker daemon: it builds the image, creates a dedicated bridge
network, and runs the container with a healthcheck attached. Image rebuilds are triggered
by content hashes of `Dockerfile`, `app.py` and `requirements.txt`.

```bash
terraform init
terraform plan
terraform apply
```

Adjust `replicas`, `host_port` or `image_tag` through variables rather than editing
resources:

```bash
terraform apply -var replicas=3 -var host_port=9000
```

## Kubernetes

```bash
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/devops-app
```

The Deployment runs three replicas with liveness and readiness probes, a read-only root
filesystem, all capabilities dropped, and a surge-only rolling update so no replica is
taken down before its replacement is ready.

## Security scanning

CodeQL runs on push, on pull request, and weekly. Dependabot opens pull requests for
outdated Python dependencies. Secret scanning is enabled at the repository level.

## Scope and limitations

- Terraform targets the local Docker daemon, not a cloud provider. There is no remote
  state backend, so state is local and not suitable for shared use.
- The image is built locally and never pushed to a registry. The Kubernetes manifests
  therefore assume a node that already holds `devops-app:latest`, such as kind or minikube,
  and use `imagePullPolicy: IfNotPresent`.
- The `LoadBalancer` Service requires a cluster that can provision one. On a local cluster
  use `kubectl port-forward` instead.
- The service holds no state and has no backing datastore, so readiness returns static
  success. Extend `/readyz` when dependencies are added.
