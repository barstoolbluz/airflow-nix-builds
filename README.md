# Apache Airflow - Nix/Flox Build Environment

Build modern Apache Airflow versions (3.1.1, 2.11.0, 2.10.5) using **Nix** and **Flox** - versions not available in nixpkgs.

## Why This Exists

**Problem:** Modern Apache Airflow versions are not available in nixpkgs:
- nixpkgs contains Airflow 2.7.3 (released 2023) with known CVEs
- No Kubernetes provider packages available
- Dependency conflicts when trying to add providers via pip

**Solution:** This repository provides build tooling to install Airflow from PyPI using:
- **[Flox Manifest Builds](https://flox.dev/docs/concepts/manifest-builds/)** - Declarative TOML-based builds
- **Nix Flakes** - Traditional Nix ecosystem integration
- **Nix Expressions** *(planned)* - For `nix-build` users

Official Apache Airflow constraint files ensure reproducibility across all build methods.

---

## Supported Versions

| Version | Released | Support Status | Python | K8s Provider | Use Case |
|---------|----------|----------------|--------|--------------|----------|
| **3.1.1** | Oct 2025 | Active Support | 3.9-3.12 | 10.8.2 | New deployments ⭐ |
| **2.11.0** | May 2025 | Limited (until Apr 2026) | 3.9-3.12 | 10.5.0 | Existing 2.x (no Python 3.8) |
| **2.10.5** | Feb 2025 | Limited (until Apr 2026) | 3.8-3.12 | 8.4.x | Python 3.8 required |

---

## Quick Start

### Option 1: Flox Manifest Builds (Recommended)

```bash
# Clone this repository
git clone https://github.com/barstoolbluz/airflow-nix-builds.git
cd airflow-nix-builds

# Activate the build environment
flox activate

# Build Airflow with Kubernetes support
flox build airflow

# Use the built package
./result-airflow/bin/airflow version
source result-airflow/bin/activate
airflow db init
```

**Available builds:**
- `airflow` - Airflow + Kubernetes provider
- `airflow-full` - Airflow + multiple providers (k8s, postgres, redis, http, ssh)
- `airflow-minimal` - Minimal Airflow (LocalExecutor only)

### Option 2: Nix Flakes

```bash
# Clone this repository
git clone https://github.com/barstoolbluz/airflow-nix-builds.git
cd airflow-nix-builds

# Build with Nix flakes (requires --impure for network access)
nix build --impure .#airflow

# Use the built package
./result/bin/airflow version
source result/bin/activate
airflow db init
```

**Available packages:**
- `airflow` - Airflow + Kubernetes provider
- `airflow-full` - Airflow + multiple providers

### Option 3: Nix Expression (Planned)

Traditional `nix-build` support is planned for broader Nix community compatibility.

---

## Version Selection

Switch between Airflow versions by editing configuration files:

### For Flox Builds

Edit `.flox/env/manifest.toml` and uncomment your desired version:

```toml
# Airflow 3.1.1 (default)
export AIRFLOW_VERSION="${AIRFLOW_VERSION:-3.1.1}"
export PYTHON_VERSION="${PYTHON_VERSION:-3.11}"

# # Airflow 2.11.0 (uncomment to use)
# export AIRFLOW_VERSION="${AIRFLOW_VERSION:-2.11.0}"
# export PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
```

Or use runtime override:
```bash
AIRFLOW_VERSION=2.11.0 flox activate
```

### For Nix Flakes

Edit `flake.nix` and uncomment your desired version:

```nix
# Airflow 3.1.1 (default)
airflowVersion = "3.1.1";
pythonVersion = "3.11";

# # Airflow 2.11.0 (uncomment to use)
# airflowVersion = "2.11.0";
# pythonVersion = "3.11";
```

---

## Documentation

- **[BUILDING.md](BUILDING.md)** - Detailed build instructions, troubleshooting, production deployment
- **[SETUP.md](SETUP.md)** - Prerequisites, version details, first-time setup
- **[Flox Manifest Builds](https://flox.dev/docs/concepts/manifest-builds/)** - Official Flox documentation
- **[Apache Airflow Docs](https://airflow.apache.org/docs/)** - Official Airflow documentation

---

## How It Works

All build methods:

1. **Create a Python virtualenv** in the output directory
2. **Download official Airflow constraint files** from GitHub for reproducibility
3. **Install Airflow via pip** with providers and constraints
4. **Verify installation** and test provider imports
5. **Package as Nix store path** (flakes) or symlink (Flox builds)

This approach:
- ✅ Solves CVE issues (builds latest versions)
- ✅ Provides Kubernetes provider support
- ✅ Avoids nixpkgs dependency conflicts
- ✅ Uses official Apache Airflow constraint files
- ✅ Supports multiple versions easily
- ✅ Enables runtime version switching (Flox)

---

## Use Cases

### Development Environments

```bash
flox activate
flox build airflow
source result-airflow/bin/activate
airflow standalone
```

### Production Deployments

Compose with Flox environments for postgres/redis:

```toml
[include]
environments = [
  { remote = "barstoolbluz/postgres-headless" },
  { remote = "barstoolbluz/redis-headless" },
]

[hook]
on-activate = '''
  source /path/to/result-airflow/bin/activate
  export AIRFLOW_HOME="$FLOX_ENV_CACHE/airflow"
'''

[services]
airflow-webserver.command = "airflow webserver"
airflow-scheduler.command = "airflow scheduler"
```

### Container Builds

```dockerfile
FROM nixos/nix
RUN nix build --impure github:barstoolbluz/airflow-nix-builds#airflow
CMD ["/nix/store/.../result/bin/airflow", "webserver"]
```

---

## Contributing

Contributions welcome! Please:
1. Test your changes with all three supported versions
2. Update documentation (BUILDING.md, SETUP.md)
3. Ensure both Flox and Nix builds work

---

## About Apache Airflow

[Apache Airflow](https://airflow.apache.org/docs/apache-airflow/stable/) is a platform to programmatically author, schedule, and monitor workflows.

When workflows are defined as code, they become more maintainable, versionable, testable, and collaborative.

### Links

- **Official Repository**: https://github.com/apache/airflow
- **Official Documentation**: https://airflow.apache.org/docs/
- **PyPI Package**: https://pypi.org/project/apache-airflow/
- **Slack Community**: https://s.apache.org/airflow-slack
- **Kubernetes Provider**: https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/

---

## License

Apache Airflow is licensed under the Apache License 2.0.

This build environment configuration is provided as-is for building Apache Airflow.

---

## Acknowledgments

- **Apache Airflow Community** for creating and maintaining Airflow
- **Flox** for declarative environment and build system
- **Nix Community** for reproducible build infrastructure
