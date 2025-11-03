{
  description = "Apache Airflow 3.1.1 with Kubernetes support - Built via pip in virtualenv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python311;

        # ============================================================================
        # AIRFLOW VERSION CONFIGURATION
        # ============================================================================
        # Choose your Airflow version by uncommenting ONE block below.
        #
        # Supported versions:
        #   3.1.1  - Latest stable (Active Support) - RECOMMENDED
        #   2.11.0 - Latest 2.x (Limited Support until April 2026, Python 3.9+)
        #   2.10.5 - For Python 3.8 users (Limited Support until April 2026)
        #
        # IMPORTANT: Only uncomment ONE version block!
        # ============================================================================

        # Airflow 3.1.1 (Latest - Active Support - RECOMMENDED)
        # Released: October 27, 2025
        # Python: 3.9, 3.10, 3.11, 3.12
        # K8s Provider: 10.8.2
        airflowVersion = "3.1.1";
        pythonVersion = "3.11";

        # # Airflow 2.11.0 (Latest 2.x - Limited Support until April 2026)
        # # Released: May 20, 2025
        # # Python: 3.9, 3.10, 3.11, 3.12 (NO Python 3.8!)
        # # K8s Provider: 10.5.0
        # # Breaking changes from 2.10: Drops Python 3.8, removes deprecated features
        # airflowVersion = "2.11.0";
        # pythonVersion = "3.11";

        # # Airflow 2.10.5 (For Python 3.8 users - Limited Support until April 2026)
        # # Released: February 6, 2025
        # # Python: 3.8, 3.9, 3.10, 3.11, 3.12
        # # K8s Provider: 8.4.x
        # # Use this if you need Python 3.8 support
        # airflowVersion = "2.10.5";
        # pythonVersion = "3.11";

        # ============================================================================
        # Constraint file URL (auto-generated from version)
        constraintUrl = "https://raw.githubusercontent.com/apache/airflow/constraints-${airflowVersion}/constraints-${pythonVersion}.txt";

        # Build Airflow package using pip with constraints
        # NOTE: This uses a Fixed-Output Derivation to allow network access
        airflow = pkgs.stdenv.mkDerivation {
          pname = "apache-airflow";
          version = airflowVersion;

          # Minimal source - we install from PyPI
          src = pkgs.writeTextFile {
            name = "airflow-build-script";
            text = "# Airflow build placeholder";
          };

          nativeBuildInputs = [
            python
            pkgs.curl
            pkgs.cacert  # For HTTPS downloads
          ];

          buildInputs = [
            python
            pkgs.postgresql  # Runtime dependency
            pkgs.redis       # Runtime dependency
          ];

          # This build requires network access for pip downloads
          # MUST use: nix build --impure
          # The --impure flag disables the sandbox to allow network access
          __noChroot = true;

          buildPhase = ''
            echo "========================================="
            echo "Building Apache Airflow ${airflowVersion}"
            echo "========================================="

            # Create virtualenv in $out
            ${python}/bin/python -m venv $out

            # Activate virtualenv
            source $out/bin/activate

            # Upgrade pip and build tools
            echo "Upgrading pip..."
            pip install --upgrade pip setuptools wheel

            # Download constraint file
            echo "Downloading constraint file from:"
            echo "  ${constraintUrl}"
            curl -sSL "${constraintUrl}" -o constraints.txt

            # Install Airflow with Kubernetes provider
            echo ""
            echo "Installing apache-airflow[cncf.kubernetes]==${airflowVersion}..."
            pip install "apache-airflow[cncf.kubernetes]==${airflowVersion}" \
              --constraint constraints.txt

            # Verify installation
            echo ""
            echo "========================================="
            echo "✅ Installation complete!"
            echo "========================================="
            airflow version
            echo ""
            echo "Kubernetes provider test:"
            python -c "from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator; print('  ✅ KubernetesPodOperator: OK')"
            echo ""

            # Cleanup
            rm -f constraints.txt
          '';

          installPhase = ''
            echo "Virtualenv already created in $out"
          '';

          # Make sure downloaded files are included in output
          dontStrip = true;
          dontPatchELF = true;
          dontPatchShebangs = false;

          meta = with pkgs.lib; {
            description = "Apache Airflow - Platform to programmatically author, schedule and monitor workflows";
            longDescription = ''
              Apache Airflow 3.1.1 with Kubernetes provider, built via pip in a virtualenv.

              IMPORTANT: This build requires network access during build phase.
              You MUST use the --impure flag:
                nix build --impure .#airflow

              The --impure flag allows network access for pip to download packages from PyPI.
            '';
            homepage = "https://airflow.apache.org";
            license = licenses.asl20;
            platforms = platforms.unix;
            maintainers = [ ];
          };
        };

        # Build Airflow with additional providers
        airflow-full = pkgs.stdenv.mkDerivation {
          pname = "apache-airflow-full";
          version = airflowVersion;

          src = pkgs.writeTextFile {
            name = "airflow-full-build-script";
            text = "# Airflow full build placeholder";
          };

          nativeBuildInputs = [
            python
            pkgs.curl
            pkgs.cacert
          ];

          buildInputs = [
            python
            pkgs.postgresql
            pkgs.redis
          ];

          # This build requires network access for pip downloads
          # MUST use: nix build --impure
          __noChroot = true;

          buildPhase = ''
            echo "========================================="
            echo "Building Full Apache Airflow ${airflowVersion}"
            echo "========================================="

            ${python}/bin/python -m venv $out
            source $out/bin/activate

            pip install --upgrade pip setuptools wheel

            echo "Downloading constraint file..."
            curl -sSL "${constraintUrl}" -o constraints.txt

            echo ""
            echo "Installing apache-airflow with multiple providers..."
            pip install "apache-airflow[cncf.kubernetes,postgres,redis,http,ssh]==${airflowVersion}" \
              --constraint constraints.txt

            echo ""
            echo "========================================="
            echo "✅ Full installation complete!"
            echo "========================================="
            airflow version
            echo ""

            rm -f constraints.txt
          '';

          installPhase = ''
            echo "Virtualenv created in $out"
          '';

          dontStrip = true;
          dontPatchELF = true;
          dontPatchShebangs = false;

          meta = with pkgs.lib; {
            description = "Apache Airflow with common providers (K8s, postgres, redis, http, ssh)";
            homepage = "https://airflow.apache.org";
            license = licenses.asl20;
            platforms = platforms.unix;
          };
        };

      in {
        packages = {
          default = airflow;
          airflow = airflow;
          airflow-full = airflow-full;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [
            python
            pkgs.postgresql
            pkgs.redis
            pkgs.kubectl
            pkgs.kind
            pkgs.git
            pkgs.curl
          ];

          shellHook = ''
            echo "╔════════════════════════════════════════════════════════╗"
            echo "║   Apache Airflow Development Environment              ║"
            echo "╚════════════════════════════════════════════════════════╝"
            echo ""
            echo "Python: ${python}/bin/python"
            echo ""
            echo "Active Configuration:"
            echo "  Airflow Version: ${airflowVersion}"
            echo "  Python Version: ${pythonVersion}"
            echo ""
            echo "Supported Versions:"
            echo "  3.1.1  - Latest (Active Support) ⭐"
            echo "  2.11.0 - Latest 2.x (Limited Support, Python 3.9+)"
            echo "  2.10.5 - Python 3.8 support (Limited Support)"
            echo ""
            echo "To change version:"
            echo "  • Edit flake.nix (uncomment desired version block)"
            echo ""
            echo "To build Airflow (requires --impure flag):"
            echo "  nix build --impure .#airflow"
            echo "  nix build --impure .#airflow-full"
            echo ""
            echo "To use built Airflow:"
            echo "  ./result/bin/airflow version"
            echo "  source result/bin/activate"
            echo ""
            echo "📖 See SETUP.md for detailed version information"
            echo ""
          '';
        };

        # Apps - for direct execution
        apps = {
          airflow = {
            type = "app";
            program = "${airflow}/bin/python";
            # Note: Direct execution of virtualenv-installed scripts is tricky
            # Users should source the virtualenv instead
          };
        };
      }
    );
}
