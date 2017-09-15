#!/usr/bin/env python

import os
import sys


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
        #Target('capstone', chdir='bindings/python', tar_target='https://github.com/aquynh/capstone/archive/3.0.5-rc2.tar.gz', dir_name='capstone-3.0.5-rc2'),
        #Target('unicorn', chdir='bindings/python', tar_target='https://github.com/unicorn-engine/unicorn/archive/1.0.tar.gz', dir_name='unicorn-1.0'),
        #Target('unicorn', chdir='bindings/python', git_target='https://github.com/rhelmot/unicorn.git', git_branch='fix/x86_eflags_cc_op'),
        Target('pyvex', git_target='https://github.com/angr/pyvex.git', do_install=True),
        Target('angr', git_target='https://github.com/angr/angr.git'),
    ])

class Target(object):
    def __init__(self, name,
            chdir=None,
            run_cmd=None,
            copy_cmd=None,
            git_branch=None,
            dl_cmd=None,
            dir_name=None,
            git_target=None,
            tar_target=None,
            zip_target=None,
            do_install=False):

        if chdir is None: chdir = DEFAULT_CHDIR
        if run_cmd is None: run_cmd = DEFAULT_RUN_CMD
        if copy_cmd is None: copy_cmd = DEFAULT_COPY_CMD

        self.name = name
        self.chdir = chdir
        self.run_cmd = run_cmd
        self.copy_cmd = copy_cmd
        self.dl_cmd = dl_cmd
        self.dir_name = dir_name
        self.git_branch = git_branch
        self.do_install = do_install

        if git_target is not None:
            self.set_git_target(git_target)
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
        self.dl_cmd = 'wget -O "%s" "%s" && tar -xf "%s"' % (aname, target, aname)

    def set_zip_target(self, target):
        self.dl_cmd = 'wget "%s" && unzip "%s"' % (target, os.path.basename(target))

    def run(self, build_fp, destination):
        assert self.dl_cmd is not None
        assert self.name is not None
        assert self.dir_name is not None
        build_fp.write('echo -e "\\e[32mWorking on %s\\e[0m"\n' % self.name)
        build_fp.write(self.dl_cmd + '\n')
        build_fp.write('pushd "%s"\n' % os.path.join(self.dir_name, self.chdir))
        if self.git_branch is not None:
            build_fp.write('git checkout "%s"\n' % self.git_branch)
        build_fp.write(self.run_cmd + '\n')
        if self.do_install:
            build_fp.write(DEFAULT_INSTALL_CMD + '\n')
        build_fp.write(self.copy_cmd % destination + '\n')
        build_fp.write('popd\n\n')

def run_windows(output_dir, targets):
    output_dir = os.path.realpath(output_dir)

    for arch in ['x86', 'amd64']:
        arch_dir = os.path.join(output_dir, arch)
        mkdir(arch_dir)
        build_script = os.path.join(arch_dir, 'build.bat')
        fp = open(build_script, 'w')
        fp.write(COMMAND_BASE % arch)

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

    os.chmod(output_file, 0777)
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
    DEFAULT_INSTALL_CMD = 'pip install dist\\*.whl'
    DEFAULT_COPY_CMD = 'copy dist\\* %s'

    COMMAND_BASE = """\
call VsDevCmd -arch=%s
virtualenv build_env
call build_env\\Scripts\\activate.bat
"""
else:
    run = run_linux
    DEFAULT_CHDIR = '.'
    DEFAULT_RUN_CMD = 'python setup.py bdist_wheel'
    DEFAULT_INSTALL_CMD = 'pip install dist/*.whl'
    DEFAULT_COPY_CMD = 'cp dist/* %s'

    COMMAND_BASE = """\
#!/bin/bash -ex

function python() {
    /opt/python/cp27-cp27mu/bin/python "$@"
}

function pip() {
    /opt/python/cp27-cp27mu/bin/pip "$@"
}

yum install -y libffi libffi-devel
"""


if __name__ == '__main__':
    main()
