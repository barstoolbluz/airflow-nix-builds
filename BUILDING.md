# Apache Airflow - Multi-Version Build Environment

Build Apache Airflow (3.1.1, 2.11.0, or 2.10.5) from source using **Nix flakes** or **Flox manifest builds**, bypassing nixpkgs CVE issues and dependency conflicts.

## Why This Exists

Apache Airflow 2.7.3 in nixpkgs has:
- **Multiple CVEs** (CVE-2023-50943, CVE-2023-49920, CVE-2023-50944)
- **No K8s provider packages** available in nixpkgs
- **Dependency conflicts** when trying to install providers via pip

This repository provides two approaches to build Airflow with full Kubernetes support, supporting multiple versions:
- **Airflow 3.1.1** - Latest stable (Active Support) - RECOMMENDED
- **Airflow 2.11.0** - Latest 2.x (Limited Support until April 2026, Python 3.9+)
- **Airflow 2.10.5** - For Python 3.8 users (Limited Support until April 2026)

## Two Build Approaches

### Approach 1: Flox Manifest Builds (Recommended)
Simple, reproducible builds using Flox's built-in build system.

**Requirements**: Git remote configured and commits pushed (see SETUP.md)

### Approach 2: Nix Flakes
Traditional Nix approach for maximum reproducibility and integration with Nix ecosystems.

**Requirements**: Must use `--impure` flag for network access (see SETUP.md)

---

## ⚠️ Important: Setup Required Before Building

**This is critical!** Both build approaches have prerequisites that MUST be met:

1. **Flox builds** require:
   - Git remote configured (`git remote add origin <url>`)
   - Current commit pushed to remote (`git push origin main`)
   - See [SETUP.md](SETUP.md) for detailed instructions

2. **Nix flake builds** require:
   - Network access during build (pip downloads from PyPI)
   - Must use `nix build --impure` flag (REQUIRED)
   - See [SETUP.md](SETUP.md) for detailed instructions

**📖 Read [SETUP.md](SETUP.md) first before attempting to build!**

---

## Quick Start

### Using Flox Manifest Builds

```bash
cd /home/daedalus/dev/testes/airflow-build

# Activate the build environment
flox activate

# Build Airflow with Kubernetes support
flox build airflow

# Use the built Airflow
./result-airflow/bin/airflow version

# Or activate the virtualenv
source result-airflow/bin/activate
airflow version
airflow db init
```

### Using Nix Flakes

```bash
cd /home/daedalus/dev/testes/airflow-build

# Build with Nix flakes (MUST use --impure for network access)
nix build --impure .#airflow

# Use the built Airflow
./result/bin/airflow version

# Or activate the virtualenv
source result/bin/activate
airflow version
```

---

## Flox Manifest Builds

### Available Builds

1. **`airflow`** - Airflow with Kubernetes provider
2. **`airflow-full`** - Airflow with common providers (kubernetes, postgres, redis, http, ssh)
3. **`airflow-minimal`** - Minimal installation (LocalExecutor only)

### Build Commands

```bash
# Build specific version
flox build airflow
flox build airflow-full
flox build airflow-minimal

# Results are in:
#   result-airflow/
#   result-airflow-full/
#   result-airflow-minimal/
```

### Using Built Packages

```bash
# Activate the environment for helper functions
flox activate

# Use helper function to activate a build
activate-airflow airflow
activate-airflow airflow-full

# Or build and activate in one command
build-and-activate airflow
build-and-activate airflow-full
```

### Direct Usage Without Activation

```bash
# Run Airflow commands directly
./result-airflow/bin/airflow version
./result-airflow/bin/airflow db init
./result-airflow/bin/airflow webserver
./result-airflow/bin/airflow scheduler

# Or source the virtualenv
source result-airflow/bin/activate
airflow --help
```

---

## Nix Flakes

### Available Packages

- `default` - Alias for `airflow`
- `airflow` - Airflow with Kubernetes provider
- `airflow-full` - Airflow with common providers

### Build Commands

```bash
# Build default package (airflow)
nix build

# Build specific package
nix build .#airflow
nix build .#airflow-full

# Development shell
nix develop

# Run Airflow directly
nix run .#airflow -- version
```

### Using Flakes in Flox Environments

You can reference the flake in other Flox environments:

```toml
[install]
# Reference the flake-built package
airflow.pkg-path = "github:yourusername/airflow-build#airflow"
```

Or use it in hooks:

```toml
[hook]
on-activate = '''
  # Build and activate Airflow from flake
  nix build path:/home/daedalus/dev/testes/airflow-build#airflow
  source result/bin/activate
'''
```

---

## Version Configuration

### Supported Versions

This environment supports building three Airflow versions:

| Version | Released | Support Status | Python Versions | K8s Provider | Use Case |
|---------|----------|----------------|-----------------|--------------|----------|
| **3.1.1** | Oct 27, 2025 | Active Support | 3.9-3.12 | 10.8.2 | New deployments (RECOMMENDED) |
| **2.11.0** | May 20, 2025 | Limited (until Apr 2026) | 3.9-3.12 | 10.5.0 | Existing 2.x, no Python 3.8 |
| **2.10.5** | Feb 6, 2025 | Limited (until Apr 2026) | 3.8-3.12 | 8.4.x | Python 3.8 required |

### Changing Airflow Version

#### Option 1: Edit manifest/flake (Persistent)

**For Flox builds**, edit `.flox/env/manifest.toml` and uncomment your desired version:

```toml
# Comment out current version:
# export AIRFLOW_VERSION="${AIRFLOW_VERSION:-3.1.1}"
# export PYTHON_VERSION="${PYTHON_VERSION:-3.11}"

# Uncomment desired version:
export AIRFLOW_VERSION="${AIRFLOW_VERSION:-2.11.0}"
export PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
```

**For Nix flakes**, edit `flake.nix` and uncomment your desired version:

```nix
# Comment out current version:
# airflowVersion = "3.1.1";
# pythonVersion = "3.11";

# Uncomment desired version:
airflowVersion = "2.11.0";
pythonVersion = "3.11";
```

#### Option 2: Runtime Override (Flox only)

Override at activation time:

```bash
AIRFLOW_VERSION=2.11.0 flox activate
# or with custom Python version:
AIRFLOW_VERSION=2.10.5 PYTHON_VERSION=3.8 flox activate
```

### Adding More Providers

Edit the build command in manifest.toml:

```toml
[build.airflow-custom]
command = '''
  python -m venv "$out"
  source "$out/bin/activate"
  pip install --upgrade pip setuptools wheel
  curl -sSL "${CONSTRAINT_URL}" -o /tmp/constraints.txt

  # Add your providers here
  pip install "apache-airflow[cncf.kubernetes,amazon,google,azure]==${AIRFLOW_VERSION}" \
    --constraint /tmp/constraints.txt

  airflow version
'''
```

---

## Architecture Details

### Build Process

Both approaches:
1. Create a Python virtualenv in `$out` directory
2. Download official Airflow constraint file for reproducibility
3. Install Airflow and providers via pip with constraints
4. Verify installation
5. Package as Nix store path (flakes) or symlink (Flox builds)

### Why This Works

- **Solves CVEs**: Builds latest Airflow versions (no known CVEs)
- **Multi-version support**: Three versions covering different use cases
- **Solves providers**: K8s providers install cleanly via pip with constraints
- **Solves conflicts**: Virtualenv isolates from nixpkgs Python packages
- **Reproducible**: Git commit + constraint file = deterministic build
- **Flexible**: Switch versions by commenting/uncommenting or runtime override
- **Maintainable**: Simple version updates (uncomment desired version)
- **Official approach**: Uses Airflow's recommended constraint files

### Constraint Files

Airflow maintains tested dependency sets for each release:
- URL pattern: `https://raw.githubusercontent.com/apache/airflow/constraints-{VERSION}/constraints-{PYTHON}.txt`
- Example: `constraints-3.1.1/constraints-3.11.txt`
- Ensures compatible dependency versions

---

## Using in Production

### Deployment Options

#### Option 1: Flox Environment Composition

Create a production Airflow environment that composes the built package:

```toml
[include]
environments = [
  { remote = "barstoolbluz/postgres-headless" },
  { remote = "barstoolbluz/redis-headless" },
]

[hook]
on-activate = '''
  # Activate the built Airflow
  source /path/to/result-airflow/bin/activate

  export AIRFLOW_HOME="$FLOX_ENV_CACHE/airflow"
  export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql://..."
  # ... other configuration
'''

[services]
airflow-webserver.command = "airflow webserver"
airflow-scheduler.command = "airflow scheduler"
```

#### Option 2: Container Build

Build a container with the Airflow virtualenv:

```dockerfile
FROM nixos/nix

# Build Airflow using flake
RUN nix build github:yourusername/airflow-build#airflow

# Copy virtualenv
COPY --from=builder /nix/store/.../result /opt/airflow

# Activate and run
CMD ["/opt/airflow/bin/airflow", "webserver"]
```

#### Option 3: Direct Deployment

Deploy the virtualenv directory to your server:

```bash
# Build locally
flox build airflow

# Copy to server
rsync -av result-airflow/ server:/opt/airflow/

# On server
source /opt/airflow/bin/activate
airflow db init
airflow webserver
```

---

## Kubernetes Support

### KubernetesPodOperator

The `airflow` and `airflow-full` builds include the Kubernetes provider.

Example DAG:

```python
from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from datetime import datetime

with DAG('kubernetes_example', start_date=datetime(2025, 1, 1)) as dag:
    k8s_task = KubernetesPodOperator(
        task_id='run_pod',
        name='airflow-pod',
        namespace='default',
        image='python:3.11',
        cmds=['python', '-c'],
        arguments=['print("Hello from Kubernetes!")'],
    )
```

### KubernetesExecutor

Enable via environment variable:

```bash
export AIRFLOW__CORE__EXECUTOR=KubernetesExecutor
export AIRFLOW__KUBERNETES__NAMESPACE=airflow
export AIRFLOW__KUBERNETES__KUBE_CLIENT_REQUEST_ARGS='{"_request_timeout": 60}'
```

### KIND for Local Testing

The build environment includes KIND:

```bash
flox activate

# Create local K8s cluster
kind create cluster --name airflow-test

# Verify
kubectl cluster-info --context kind-airflow-test

# Deploy Airflow tasks to KIND cluster
export KUBECONFIG="$HOME/.kube/config"
```

---

## Troubleshooting

### Build Fails: Network Issues

The build downloads from PyPI. Ensure network access:

```bash
# Test constraint file download
curl -I https://raw.githubusercontent.com/apache/airflow/constraints-3.1.1/constraints-3.11.txt

# Test PyPI access
curl -I https://pypi.org/simple/apache-airflow/
```

### Build Fails: Dependency Conflicts

Check the constraint file is downloading correctly:

```bash
curl -sSL "https://raw.githubusercontent.com/apache/airflow/constraints-3.1.1/constraints-3.11.txt"
```

If constraint file is missing, Airflow may not have that version released yet.

### Flox Build Requires Git Commit

Flox builds require a clean Git state:

```bash
git add .
git commit -m "Update build"
git remote add origin <your-remote>
git push origin main
```

### Provider Import Fails

Verify the provider installed correctly:

```bash
source result-airflow/bin/activate
pip list | grep airflow-providers
python -c "from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator"
```

---

## Comparison: Flox vs Nix Flakes

| Feature | Flox Manifest Builds | Nix Flakes |
|---------|---------------------|-----------|
| **Ease of use** | ⭐⭐⭐⭐⭐ Simple TOML | ⭐⭐⭐ Requires Nix knowledge |
| **Build speed** | ⭐⭐⭐⭐ Fast (pip) | ⭐⭐⭐ Moderate (Nix build) |
| **Reproducibility** | ⭐⭐⭐⭐ Git + constraints | ⭐⭐⭐⭐⭐ Fully hermetic |
| **Integration** | ⭐⭐⭐⭐⭐ Native Flox | ⭐⭐⭐⭐ Can use in Flox |
| **Maintenance** | ⭐⭐⭐⭐⭐ Easy updates | ⭐⭐⭐ More complex |
| **Portability** | ⭐⭐⭐⭐ Needs Flox | ⭐⭐⭐⭐⭐ Works anywhere with Nix |

### When to Use Each

**Use Flox Manifest Builds when:**
- You're already using Flox environments
- You want simplicity and ease of maintenance
- You need fast iteration cycles
- You trust PyPI + constraint files for reproducibility

**Use Nix Flakes when:**
- You need maximum reproducibility
- You're integrating with Nix/NixOS ecosystems
- You want truly hermetic builds
- You're comfortable with Nix language

---

## Development

### Testing Changes

```bash
# Activate environment
flox activate

# Make changes to manifest.toml
flox edit

# Rebuild
flox build airflow

# Test
./result-airflow/bin/airflow version
```

### Publishing Builds

```bash
# Publish to Flox Catalog (requires setup)
flox publish airflow

# Or push the built package to a binary cache
nix copy .#airflow --to file:///path/to/cache
```

### CI/CD Integration

```yaml
# GitHub Actions example
name: Build Airflow

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Flox
        run: |
          curl -fsSL https://downloads.flox.dev/by-env/stable/install | bash

      - name: Build Airflow
        run: |
          flox activate -- flox build airflow

      - name: Test
        run: |
          ./result-airflow/bin/airflow version
```

---

## Security Considerations

- ✅ **No CVEs**: Airflow 3.1.1 has no known CVEs (as of build date)
- ⚠️ **Network access**: Build requires PyPI access (could cache)
- ✅ **Constraint files**: Pin dependencies to tested versions
- ⚠️ **Update frequency**: Monitor Airflow security announcements

### Production Checklist

- [ ] Change default admin password
- [ ] Set AIRFLOW__WEBSERVER__SECRET_KEY
- [ ] Configure PostgreSQL (not SQLite)
- [ ] Enable authentication/authorization
- [ ] Set up HTTPS/TLS
- [ ] Review security settings: https://airflow.apache.org/docs/apache-airflow/stable/security/

---

## Resources

- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Airflow Kubernetes Documentation](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/)
- [Flox Documentation](https://flox.dev/docs/)
- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [Airflow Constraints](https://github.com/apache/airflow/tree/constraints-3.1.1)

---

## License

This build environment configuration is provided as-is for building Apache Airflow.

Apache Airflow itself is licensed under the Apache License 2.0.

---

**Questions or Issues?** Open an issue or check the Airflow community resources.
