# Setup Instructions

## Prerequisites Before Building

### For Nix Flake Builds

The Nix flake uses **network access during build** (to run `pip install`).

**You MUST use the `--impure` flag:**

```bash
nix build --impure .#airflow
nix build --impure .#airflow-full
```

The `--impure` flag disables Nix's sandbox and allows network access for pip to download packages from PyPI.

**Why impure?** This build uses pip to install packages into a virtualenv, which is inherently impure. The Airflow constraint files provide reproducibility instead of Nix's FOD mechanism.

### For Flox Manifest Builds

Flox requires the following before `flox build` will work:

1. ✅ **Git repository** - Already set up
2. ✅ **Clean working tree** - No uncommitted changes to tracked files
3. ❌ **Git remote configured** - MUST ADD BEFORE BUILDING
4. ❌ **Current commit pushed to remote** - MUST PUSH BEFORE BUILDING

## Setup Steps for Flox Builds

### Step 1: Add Git Remote

You must add a git remote before building. Choose one:

#### Option A: Push to GitHub (Recommended)

```bash
# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/airflow-build.git
git push -u origin main
```

#### Option B: Use a local "remote" (Testing Only)

```bash
# Create a bare repo as fake remote
mkdir -p /tmp/airflow-build-remote.git
cd /tmp/airflow-build-remote.git
git init --bare

# Back in your project
cd /home/daedalus/dev/testes/airflow-build
git remote add origin /tmp/airflow-build-remote.git
git push -u origin main
```

#### Option C: Use any git hosting

```bash
git remote add origin <your-git-url>
git push -u origin main
```

### Step 2: Verify Prerequisites

```bash
# Check git status (should be clean)
git status

# Check remote is configured
git remote -v

# Check current commit is pushed
git log origin/main..HEAD  # Should show "nothing"
```

### Step 3: Build

```bash
# Activate environment
flox activate

# Build one of the targets
flox build airflow
flox build airflow-full
flox build airflow-minimal
```

## Quick Start After Setup

### Using Nix Flake

```bash
# Build with impure flag
nix build --impure .#airflow

# Use the result
./result/bin/airflow version
source result/bin/activate
airflow db init
```

### Using Flox Build

```bash
# Activate environment
flox activate

# Build
flox build airflow

# Use the result
./result-airflow/bin/airflow version

# Or use helper function
activate-airflow airflow
```

## Troubleshooting

### Flox Build Error: "no remote configured"

```
Error: Git remote required
```

**Solution**: Add a git remote and push (see Step 1 above)

### Flox Build Error: "uncommitted changes"

```
Error: Git working tree not clean
```

**Solution**: Commit all changes
```bash
git add .
git commit -m "Prepare for build"
git push
```

### Flox Build Error: "commit not pushed"

```
Error: Current commit not in remote
```

**Solution**: Push your commits
```bash
git push origin main
```

### Nix Build Error: "network access denied" or "sandbox" error

```
error: unable to download 'https://...'
```

**Solution**: You forgot the `--impure` flag
```bash
nix build --impure .#airflow
```

The `--impure` flag is REQUIRED for this build because it downloads from PyPI during the build phase.

## Airflow Version Support

This environment supports building multiple Airflow versions:

### Supported Versions

#### Airflow 3.1.1 (Latest - RECOMMENDED)
- **Released**: October 27, 2025
- **Support**: Active Support
- **Python**: 3.9, 3.10, 3.11, 3.12
- **K8s Provider**: 10.8.2
- **Use for**: New deployments, latest features

#### Airflow 2.11.0 (Latest 2.x)
- **Released**: May 20, 2025
- **Support**: Limited Support until April 2026
- **Python**: 3.9, 3.10, 3.11, 3.12 (NO Python 3.8!)
- **K8s Provider**: 10.5.0
- **Breaking changes**: Drops Python 3.8, removes deprecated features
- **Use for**: Existing 2.x deployments on Python 3.9+

#### Airflow 2.10.5 (Python 3.8 Support)
- **Released**: February 6, 2025
- **Support**: Limited Support until April 2026
- **Python**: 3.8, 3.9, 3.10, 3.11, 3.12
- **K8s Provider**: 8.4.x
- **Use for**: Deployments requiring Python 3.8

### Changing Versions

#### Option 1: Edit manifest/flake (Persistent)
Edit `.flox/env/manifest.toml` or `flake.nix` and uncomment your desired version block while commenting out the others:

```toml
# Comment out the current version:
# export AIRFLOW_VERSION="${AIRFLOW_VERSION:-3.1.1}"
# export PYTHON_VERSION="${PYTHON_VERSION:-3.11}"

# Uncomment your desired version:
export AIRFLOW_VERSION="${AIRFLOW_VERSION:-2.11.0}"
export PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
```

#### Option 2: Runtime Override (Temporary)
Override at activation time (Flox manifest builds only):

```bash
AIRFLOW_VERSION=2.11.0 flox activate
# or
AIRFLOW_VERSION=2.10.5 PYTHON_VERSION=3.8 flox activate
```

## What Each Build Does

All builds:
1. Create a Python virtualenv (version depends on selected PYTHON_VERSION)
2. Download Airflow constraint file from GitHub (version-specific)
3. Install Airflow via pip with constraints
4. Verify installation

### `airflow`
- Installs: `apache-airflow[cncf.kubernetes]==${AIRFLOW_VERSION}`
- Use for: Kubernetes-based workflows
- Size: ~500MB

### `airflow-full`
- Installs: `apache-airflow[cncf.kubernetes,postgres,redis,http,ssh]==${AIRFLOW_VERSION}`
- Use for: Full-featured deployments
- Size: ~600MB

### `airflow-minimal`
- Installs: `apache-airflow==${AIRFLOW_VERSION}`
- Use for: LocalExecutor only, minimal testing
- Size: ~400MB

## Next Steps

After successful build:

1. **Test the installation**:
   ```bash
   ./result-airflow/bin/airflow version
   ```

2. **Activate the virtualenv**:
   ```bash
   source result-airflow/bin/activate
   airflow db init
   airflow users create --username admin --password admin --role Admin --email admin@example.com --firstname Admin --lastname User
   ```

3. **Start Airflow** (need separate terminals):
   ```bash
   # Terminal 1
   airflow webserver

   # Terminal 2
   airflow scheduler
   ```

4. **Access UI**: http://localhost:8080

5. **Create wrapper environment** (see main README.md)
