#!/usr/bin/env bash

set -euo pipefail

force=0
if [[ ${1:-} == "--force" ]]; then
    force=1
    shift
fi

root=${1:-$PWD}
python=${PYTHON:-python}

# Keep this order in sync with the dependency order used by angr-dev's setup
# scripts. Missing repositories are intentionally skipped.
known_projects=(
    angr-data
    archinfo
    pyvex
    cle
    claripy
    angr
    angr-management
)

project_dirs=()
for project in "${known_projects[@]}"; do
    if [[ -f $root/$project/pyproject.toml ]]; then
        project_dirs+=("$project")
    fi
done

if (( ${#project_dirs[@]} == 0 )); then
    echo "No angr package checkouts found under $root."
    exit 0
fi

state_file=$(
    "$python" - <<'PY'
from pathlib import Path
import sys

print(Path(sys.prefix) / ".angr-editables-state")
PY
)

current_state()
{
    "$python" - "$root" "${project_dirs[@]}" <<'PY'
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1]).resolve()
state = []

for relative_path in sys.argv[2:]:
    checkout = root / relative_path
    revision = subprocess.run(
        ["git", "-C", checkout, "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    ).stdout.strip()
    status_lines = subprocess.run(
        ["git", "-C", checkout, "status", "--porcelain", "--untracked-files=normal"],
        check=False,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    # Content changes are already visible through an editable install. File-set
    # changes need a rebuild when setuptools uses editable_mode=strict.
    changes = [
        line
        for line in status_lines
        if line.startswith("??") or any(code in "ADRC" for code in line[:2])
    ]

    packaging_hash = hashlib.sha256()
    for filename in ("pyproject.toml", "setup.py", "setup.cfg", "Cargo.toml", "Cargo.lock"):
        packaging_file = checkout / filename
        if packaging_file.is_file():
            packaging_hash.update(filename.encode())
            packaging_hash.update(packaging_file.read_bytes())

    state.append(
        {
            "path": str(checkout),
            "revision": revision,
            "changes": changes,
            "packaging_hash": packaging_hash.hexdigest(),
        }
    )

print(json.dumps(state, sort_keys=True, separators=(",", ":")))
PY
}

checkout_state=$(current_state)

# Entering the shell should be cheap after the initial installation. Verify both
# the editable flag and the checkout path so a venv copied from elsewhere is
# repaired automatically.
if (( force == 0 )) \
    && [[ -f $state_file ]] \
    && [[ $(< "$state_file") == "$checkout_state" ]] \
    && "$python" - "$root" "${project_dirs[@]}" <<'PY'
import importlib.metadata
import json
from pathlib import Path
import sys
import tomllib
from urllib.parse import unquote, urlparse

root = Path(sys.argv[1]).resolve()

for relative_path in sys.argv[2:]:
    checkout = root / relative_path
    with (checkout / "pyproject.toml").open("rb") as pyproject_file:
        package_name = tomllib.load(pyproject_file)["project"]["name"]

    try:
        distribution = importlib.metadata.distribution(package_name)
        direct_url = json.loads(distribution.read_text("direct_url.json") or "{}")
        source_path = Path(unquote(urlparse(direct_url["url"]).path)).resolve()
        editable = direct_url.get("dir_info", {}).get("editable", False)
    except (importlib.metadata.PackageNotFoundError, KeyError, OSError, ValueError):
        raise SystemExit(1)

    if not editable or source_path != checkout.resolve():
        raise SystemExit(1)
PY
then
    exit 0
fi

echo "Installing checked-out angr packages into the development venv..."

pip_options=()
if [[ -n ${PIP_OPTIONS:-} ]]; then
    read -r -a pip_options <<< "$PIP_OPTIONS"
fi

"$python" -m pip install "${pip_options[@]}" --upgrade \
    pip \
    wheel \
    "setuptools>=77.0.0" \
    setuptools-rust \
    cffi \
    "unicorn==2.1.4" \
    nanobind \
    "scikit-build-core~=0.12.2"

# Install third-party runtime dependencies separately. Local angr packages are
# filtered out so checkouts on temporarily mismatched branches can still all be
# installed editable without pip replacing one of them with a wheel from PyPI.
mapfile -t runtime_dependencies < <(
    "$python" - "$root" "${project_dirs[@]}" <<'PY'
from pathlib import Path
import re
import sys
import tomllib

root = Path(sys.argv[1])
projects = []
local_names = set()

def normalize(name):
    return re.sub(r"[-_.]+", "-", name).lower()

for relative_path in sys.argv[2:]:
    with (root / relative_path / "pyproject.toml").open("rb") as pyproject_file:
        project = tomllib.load(pyproject_file)["project"]
    projects.append(project)
    local_names.add(normalize(project["name"]))

seen = set()
for project in projects:
    for requirement in project.get("dependencies", []):
        match = re.match(r"\s*([A-Za-z0-9][A-Za-z0-9._-]*)", requirement)
        if match is not None and normalize(match.group(1)) in local_names:
            continue
        if requirement not in seen:
            print(requirement)
            seen.add(requirement)
PY
)

if (( ${#runtime_dependencies[@]} > 0 )); then
    "$python" -m pip install "${pip_options[@]}" "${runtime_dependencies[@]}"
fi

for project in "${project_dirs[@]}"; do
    install_options=(
        "${pip_options[@]}"
        --no-build-isolation
        --no-deps
        --editable
        "$root/$project"
    )

    case $project in
        angr)
            install_options+=(--config-settings editable_mode=compat)
            ;;
        pyvex)
            ;;
        *)
            install_options+=(--config-settings editable_mode=strict)
            ;;
    esac

    "$python" -m pip install "${install_options[@]}"
done

checkout_state=$(current_state)
printf '%s\n' "$checkout_state" > "$state_file"

echo "Editable angr package installation complete."
