# 🐳 Calico Archive Script

This script automates the process of mirroring [Project Calico](https://projectcalico.org/) container images to your own Docker Hub namespace and rewrites the standalone manifest YAML to use the archived versions.

This script is particularly useful for long-term archiving, air-gapped deployments, or scenarios where you need full control over Calico container images. More recently, the Calico project has been shifting toward an Operator-based installation model, which is less convenient compared to the simplicity of a single YAML manifest that can be applied directly using `kubectl apply -f file.yaml`.

---

## ✅ Features

- Downloads the latest Calico manifest
- Copies all referenced images (multi-arch supported) to your Docker Hub namespace using [`crane`](https://github.com/google/go-containerregistry)
- Rewrites the manifest YAML to use your copied image paths
- Works on macOS and Linux (cross-platform `sed` handling)

---

## 📦 Requirements

- [`crane`](https://github.com/google/go-containerregistry#installation)
- `curl`
- `sed` (cross-platform supported)
- `grep`
- Docker login (`docker login`)

---

## 🔧 Usage

### Basic

```bash
./calico_archive.sh <version> <dockerhub_user>
```

### Example

```bash
./calico_archive.sh 3.25 spurin
```

---

## 📂 Output

When run, the script creates:

- `calico-<version>-original.yaml`: the unmodified manifest from Calico
- `calico-<version>-archived.yaml`: a version of the manifest with image references updated to point to your Docker Hub account

---

## 💡 Example Output

```bash
📥 Downloading Calico manifest from: https://docs.projectcalico.org/manifests/calico.yaml
🔍 Extracting image references...
📦 Copying images to Docker Hub repo: docker.io/spurin/calico
➡️  docker.io/calico/cni:v3.25.0 → docker.io/spurin/calico:cni-v3.25.0
➡️  docker.io/calico/node:v3.25.0 → docker.io/spurin/calico:node-v3.25.0
➡️  docker.io/calico/kube-controllers:v3.25.0 → docker.io/spurin/calico:kube-controllers-v3.25.0
✍️  Updating archived manifest with new image paths...

✅ Archival complete!
  Original manifest: calico-3.25-original.yaml
  Archived manifest: calico-3.25-archived.yaml
```

---

## 📝 Notes

- You must **create the Docker Hub repository manually first** (e.g. `spurin/calico`).
- Ensure you're logged in via `docker login` as the user who owns the repository.
- If using 2FA, generate a [Personal Access Token](https://hub.docker.com/settings/security) for CLI auth.

---

## 👷 Example Crane Install (macOS with Homebrew)

```bash
brew install crane
```

---

## 📜 License

MIT
