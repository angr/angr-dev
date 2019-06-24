#!/usr/bin/env python

import os
import sys
import requests

# THE GIST IS
# create a new environment (docker, virtualenv, ...)
# clone some repo or download something
# run some command
# copy some output file
# put the result somewhere

# TODO: make this whole thing usable from the command line. refactor into Platform or BuildEnv or something

DEST_DIR = 'bdist'
GIT_ROOT = 'https://github.com/angr'

def mkdir(path):
    if not os.path.isdir(path):
        os.mkdir(path)

def main():
    mkdir('bdist')

    run('bdist', [
        #Target('capstone', chdir='bindings/python', tar_target='https://github.com/aquynh/capstone/archive/4.0.tar.gz', dir_name='capstone-4.0'),
        #Target('unicorn', chdir='bindings/python', tar_target='https://github.com/unicorn-engine/unicorn/archive/1.0.tar.gz', dir_name='unicorn-1.0'),
        #Target('unicorn', chdir='bindings/python', git_target='https://github.com/rhelmot/unicorn.git', git_branch='fix/x86_eflags_cc_op'),
        #Target('pyvex', git_target='https://github.com/angr/pyvex.git', do_install=True),
        #Target('angr', git_target='https://github.com/angr/angr.git'),
        #Target('keystone-engine', chdir='bindings/python', tar_target='https://files.pythonhosted.org/packages/9a/fc/ed0d3f46921bfaa612d9e8ce8313f99f4149ecf6635659510220c994cb72/keystone-engine-0.9.1-3.tar.gz', dir_name='keystone-engine-0.9.1-3'),
        Target('z3-solver', pypi_target='z3-solver'),
        #Target('z3-solver', git_target='https://github.com/angr/angr-z3.git', chdir='src/api/python', env={'Z3_VERSION_SUFFIX': '.post1'}),
        #Target('z3-solver', zip_target='https://github.com/angr/angr-z3/archive/master.zip', dir_name='angr-z3-master', chdir='src/api/python', env={'Z3_VERSION_SUFFIX': '.post1'}),
        #Target('pyvex', pypi_target='pyvex', do_install=True),
        #Target('angr', pypi_target='angr'),
        #Target('capstone', pypi_target='capstone'),
    ])

class Target(object):
    def __init__(self, name,
            chdir=None,
            env=None,
            run_cmd=None,
            copy_cmd=None,
            git_branch=None,
            dl_cmd=None,
            dir_name=None,
            pypi_target=None,
            git_target=None,
            tar_target=None,
            zip_target=None,
            do_install=False):

        if chdir is None: chdir = DEFAULT_CHDIR
        if env is None: env = {}
        if run_cmd is None: run_cmd = DEFAULT_RUN_CMD
        if copy_cmd is None: copy_cmd = DEFAULT_COPY_CMD

        self.name = name
        self.chdir = chdir
        self.env = env
        self.run_cmd = run_cmd
        self.copy_cmd = copy_cmd
        self.dl_cmd = dl_cmd
        self.dir_name = dir_name
        self.git_branch = git_branch
        self.do_install = do_install

        if git_target is not None:
            raise Exception("UNFORTUNATE ERROR: The version of git in this docker image is too old to work with modern TLS protocols. please use a zip or tarball target instead. (though feel free to remove this assertion and see if the issue has magically been fixed..!")
            self.set_git_target(git_target)

        if pypi_target is not None:
            tar_target, zip_target = self.extract_pypi_target(pypi_target)

        if tar_target is not None:
            self.set_tar_target(tar_target)
        if zip_target is not None:
            self.set_zip_target(zip_target)


    def set_git_target(self, target):
        if not target.endswith('.git'):
            self.dir_name = os.path.basename(target)
            target += '.git'
        else:
            self.dir_name = os.path.basename(target.split('.')[-2])

        if '/' in target:
            self.dl_cmd = 'git clone "%s" "%s"' % (target, self.dir_name)
        else:
            self.dl_cmd = 'git clone "%s/%s" "%s"' % (GIT_ROOT, target, self.dir_name)

    def set_tar_target(self, target):
        aname = os.path.basename(target)
        self.dl_cmd = 'curl -L -o "%s" "%s" && tar -xf "%s"' % (aname, target, aname)

    def set_zip_target(self, target):
        aname = os.path.basename(target)
        self.dl_cmd = 'curl -L -o "%s" "%s" && unzip "%s"' % (aname, target, aname)

    def extract_pypi_target(self, target):
        r = requests.get('https://pypi.org/simple/%s/' % target).text
        url_with_fragment = [x for x in r.split('"') if 'files.pythonhosted.org' in x and '.whl' not in x and '.egg' not in x][-1]
        url = url_with_fragment.split('#')[0]

        if url.endswith('.tar.gz'):
            self.dir_name = url.split('/')[-1][:-7]
            return url, None
        elif url.endswith('.tar') or url.endswith('.tgz'):
            self.dir_name = url.split('/')[-1][:-4]
            return url, None
        elif url.endswith('.zip'):
            self.dir_name = url.split('/')[-1][:-4]
            return None, url
        else:
            raise ValueError('Extracted pypi link with unknown suffix')

    def run(self, build_fp, destination):
        assert self.dl_cmd is not None
        assert self.name is not None
        assert self.dir_name is not None
        build_fp.write('echo -e "\\e[32mWorking on %s\\e[0m"\n' % self.name)
        for k, v in self.env.items():
            build_fp.write('export %s=%s\n' % (k, v))
        build_fp.write(self.dl_cmd + '\n')
        build_fp.write('pushd "%s"\n' % os.path.join(self.dir_name, self.chdir))
        if self.git_branch is not None:
            build_fp.write('git checkout "%s"\n' % self.git_branch)
        build_fp.write(self.run_cmd + '\n')
        if self.do_install:
            build_fp.write(DEFAULT_INSTALL_CMD + '\n')
        build_fp.write(self.copy_cmd % destination + '\n')
        build_fp.write('popd\n\n')

    @property
    def docker_env_str(self):
        return ''.join('-e %s=%s ' % (k, v) for k, v in self.env)

def run_windows(output_dir, targets):
    output_dir = os.path.realpath(output_dir)
    try:
        path32 = os.environ['PYTHON_32']
        path64 = os.environ['PYTHON_64']
    except KeyError:
        print("Please set the PYTHON_32 and PYTHON_64 environment variables to the paths to 32- and 64-bit python executables")
        sys.exit(1)

    for arch, interp in [('x86', path32), ('amd64', path64)]:
        arch_dir = os.path.join(output_dir, arch)
        mkdir(arch_dir)
        build_script = os.path.join(arch_dir, 'build.bat')
        fp = open(build_script, 'w')
        fp.write(COMMAND_BASE % (arch, interp))

        for target in targets:
            target.run(fp, output_dir)

        fp.close()
        os.chdir(arch_dir)
        os.system('cmd /C "%s"' % build_script)


def run_linux(output_dir, targets):
    output_dir = os.path.realpath(output_dir)
    output_file = os.path.join(output_dir, 'build.sh')
    output = open(output_file, 'w')
    output.write(COMMAND_BASE)

    for target in targets:
        target.run(output, '/output')

    output.close()

    os.chmod(output_file, 0o777)
    os.system('''
    sudo docker run -it --rm -v "%s:/output" quay.io/pypa/manylinux1_x86_64 /output/build.sh
    sudo docker run -it --rm -v "%s:/output" quay.io/pypa/manylinux1_i686 /output/build.sh
    sudo chown $(id -un):$(id -un) %s/*
    ''' % (output_dir, output_dir, output_dir))
    #os.unlink(output_file)

if sys.platform == 'win32':
    run = run_windows
    DEFAULT_CHDIR = '.'
    DEFAULT_RUN_CMD = 'python setup.py bdist_wheel'
    DEFAULT_INSTALL_CMD = 'for %%f in (dist\\*.whl) DO pip install %%f'
    DEFAULT_COPY_CMD = 'for %%%%f in (dist\\*) DO copy "%%%%f" "%s"'

    COMMAND_BASE = """\
call VsDevCmd -arch=%s
virtualenv build_env --python="%s"
call build_env\\Scripts\\activate.bat
"""
else:
    run = run_linux
    DEFAULT_CHDIR = '.'
    DEFAULT_RUN_CMD = 'python setup.py bdist_wheel'
    DEFAULT_INSTALL_CMD = 'pip install dist/*.whl'
    DEFAULT_COPY_CMD = 'cp dist/* %s'

    COMMAND_BASE = """\
#!/usr/bin/env bash
set -ex

function python() {
    /opt/python/cp35-cp35m/bin/python "$@"
}

function pip() {
    /opt/python/cp35-cp35m/bin/pip "$@"
}

yum install -y libffi libffi-devel
"""


if __name__ == '__main__':
    main()
