$repos = @(
    "angr/archinfo"
    "angr/pyvex"
    "angr/cle"
    "angr/claripy"
    "angr/ailment"
    "angr/angr"
    "angr/angr-management"
)

$extra_requires = @{
    angr = @("angrdb")
}

$build_deps = $(
    "pip"
    "setuptools>=66.1.0"
    "setuptools-rust"
    "wheel"
    "cffi"
    "unicorn==2.0.1.post1"
)

$extras_install = $(
    "nose2"
    "flaky"
    "ipython"
    "ipdb"
    "pylint"
)

function Test-Dependencies() {
    # git
    if ((Get-Command -ErrorAction 'SilentlyContinue' git).count -eq 0) {
        Write-Error "git is required to install angr. Please ensure 'git' is in your PATH."
        exit 1
    }
    # Python
    if ((Get-Command -ErrorAction 'SilentlyContinue' py).count -eq 0) {
        Write-Error "Python is required to install angr. Please ensure 'python' is in your PATH."
        exit 1
    }
    # Visual Studio
    if (-Not (Test-Path (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'))) {
        Write-Error "Visual Studio is required to install angr."
        exit 1
    }
}

function Initialize-VisualStudio() {
    $vsPath = &(Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe') -property installationpath
    Import-Module (Join-Path $vsPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')

    $pyarch = python -c "import platform; print(platform.architecture()[0])"
    if ($pyarch -eq "32bit") {
        $arch = "x86"
    } elseif ($pyarch -eq "64bit") {
        $arch = "amd64"
    } else {
        Write-Error "Python architecture not recognized: $pyarch"
        exit 1
    }
    Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments "-arch=$arch"
}

function Get-Repo($repo) {
    $name = $repo.Split('/')[-1]

    if (-Not (Test-Path -Path $name)) {
        git clone --recursive https://github.com/$repo.git
        if (!$?) {
            Write-Error "Failed to clone $repo"
            exit 1
        }
    }
}

function Install-Repo($repo) {
    $name = $repo.Split('/')[-1]

    if (Test-Path -Path $name/pyproject.toml) {
        if ($extra_requires.ContainsKey($name)) {
            $extras = "[" + ($extra_requires[$name] -Join ",") + "]"
        } else {
            $extras = ""
        }

        python -m pip install --no-build-isolation -e .\$name$extras
        if (!$?) {
            Write-Error "Failed to install $repo"
        }
    }
}

function Install-BuildDeps() {
    python -m pip install $build_deps
    if (!$?) {
        Write-Error "Failed to install extras"
        exit 1
    }
}

function Install-Extras() {
    python -m pip install $extras_install
    if (!$?) {
        Write-Error "Failed to install extras"
        exit 1
    }
}


Write-Output "Checking dependencies..."
Test-Dependencies

Write-Output "Cloning repos..."
foreach ($repo in $repos) {
    Get-Repo $repo
}

Write-Output "Installing Visual Studio..."
Initialize-VisualStudio

Write-Output "Installing Python build dependencies..."
Install-BuildDeps

Write-Output "Installing repos..."
foreach ($repo in $repos) {
    Install-Repo $repo
}

Write-Output "Installing extras..."
Install-Extras

Write-Output "Done!"
