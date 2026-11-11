# Notes Container Release

`notes-web` is the CloudNotes web service: a small Flask app that uses PostgreSQL and Redis. This repository holds its Dockerfile, Docker Compose stack, and release scripts. Everything runs on **local Docker only**: no cloud account, no paid registry, no registry login, no real credentials.

## Before timed work

Fork `https://github.com/kalviumcommunity/notes-container-release`, clone your fork and create `fix/container-release`. Use Linux, macOS or WSL2, Bash, Python 3, Git, curl and running Docker Engine with Compose v2 supporting `--wait`. amd64/arm64 supported. Allow 2 CPUs, 4 GB free memory, 10 GB disk, internet for image/Python downloads and free host ports 8080/5050. Docker Desktop optional where free-use licence applies.

```bash
bash scripts/prerequisites.sh
```

Wait for `PREREQUISITES READY` before timing. Helper pulls Python/PostgreSQL/Redis/registry bases, builds supplied correct dependency stage and verifies real push/pull through temporary loopback registry, then removes it. Compose supplies actual task registry; no external setup needed. Dependency build cache is not an offline-build guarantee. No repair files are changed; do not start timer on setup errors or remove unknown resources. Capture initial broken checks before repairs. Submit genuine check output and repaired configuration in PDF; push only to your fork, no upstream PR.

## Layout

```text
app/app.py              # Flask app (do not edit)
app/requirements.txt    # Python dependencies (do not edit)
Dockerfile              # multi-stage image build
compose.yaml            # web + db (PostgreSQL) + redis + local registry
scripts/check-image.sh  # checks the image against the runtime design (do not edit)
scripts/publish.sh      # builds, tags, and publishes the image
```

## Application contract

- Listens on port `5000` inside the container. Compose maps it to `http://localhost:8080`.
- `GET /health` checks PostgreSQL and Redis on every request.
  - Both reachable: HTTP `200` with `"status": "ok"`, `"database": "connected"`, `"cache": "connected"`.
  - Either unreachable: HTTP `503` with `"status": "degraded"`.
- Reads `DATABASE_URL` and `REDIS_URL` from the environment. Compose supplies practice-only values.

## Intended design

1. **Runtime image.** Multi-stage build. The build stage installs dependencies. The runtime stage uses `python:3.12-slim`, copies the installed dependencies from the build stage and **only** the `app/` folder, and runs as a non-root user named `app`. The image is 300 MB or less.
2. **Compose networking.** Two networks: `frontend` and `backend`. `db` and `redis` are on `backend` only and are never published to the host. `web` is on both networks, so it reaches `db` and `redis` by service name. `web` starts only after `db` is healthy and `redis` has started.
3. **Release tagging and publishing.** Each release has a version, `1.0.0` for this release. `scripts/publish.sh` builds the image, tags it as both `localhost:5050/notes-web:1.0.0` and `localhost:5050/notes-web:latest`, and pushes **both** tags to the local registry. It never pushes to Docker Hub.

The local registry runs from `compose.yaml` on host port `5050` (container port `5000`). Port 5050 avoids the macOS AirPlay conflict on port 5000.

## Commands (run from the repository root)

Image check:

```bash
docker build -t notes-web:dev .
bash scripts/check-image.sh notes-web:dev
```

Compose stack:

```bash
docker compose up -d --build
docker compose ps
curl --retry 5 --retry-all-errors --retry-delay 2 --fail-with-body -i http://127.0.0.1:8080/health
```

Publish and verify:

```bash
bash scripts/publish.sh
curl http://localhost:5050/v2/notes-web/tags/list
docker pull localhost:5050/notes-web:1.0.0
```

Cleanup:

```bash
docker compose down
```

## Rules

- The repository has exactly three planted issues. Fix them so the intended design is met.
- Edit only `Dockerfile`, `compose.yaml`, and `scripts/publish.sh`.
- Do not edit `app/`, `scripts/check-image.sh`, or this README.
- Do not remove checks, publish `db` or `redis` ports, push to Docker Hub, or log in to any registry.
