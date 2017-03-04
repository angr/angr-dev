#!/usr/bin/env python

import os

# THE GIST IS
# you spawn a docker container
# clone some repo or download something
# run some command
# copy some output file
# put the result somewhere

# TODO: make this whole thing usable from the command line. make some provision for windows somehow.

DEST_DIR = 'bdist'
GIT_ROOT = 'git@github.com:angr'

DEFAULT_CHDIR = '.'
DEFAULT_RUN_CMD = 'python setup.py bdist_wheel sdist && pip install dist/*.whl'
DEFAULT_COPY_CMD = 'cp dist/* /output'

OUTPUT_STRING = """\
#!/bin/bash -ex

function python() {
    /opt/python/cp27-cp27mu/bin/python "$@"
}

function pip() {
    /opt/python/cp27-cp27mu/bin/pip "$@"
}

yum install -y libffi libffi-devel
"""

def main():
    try:
        os.mkdir('bdist')
    except OSError as e:
        if e.errno != 17:
            raise

    run('bdist', [
        Target('capstone', chdir='bindings/python', tar_target='https://github.com/aquynh/capstone/archive/3.0.5-rc2.tar.gz', dir_name='capstone-3.0.5-rc2'),
        Target('unicorn', chdir='bindings/python', tar_target='https://github.com/unicorn-engine/unicorn/archive/1.0.tar.gz', dir_name='unicorn-1.0')
    ])

def run(output_dir, targets):
    output_dir = os.path.realpath(output_dir)
    output_file = os.path.join(output_dir, 'build.sh')
    output = open(output_file, 'w')
    output.write(OUTPUT_STRING)

    for target in targets:
        target.run(output)

    output.close()

    os.chmod(output_file, 0777)
    os.system('''
    sudo docker run -it --rm -v "%s:/output" quay.io/pypa/manylinux1_x86_64 /output/build.sh
    sudo docker run -it --rm -v "%s:/output" quay.io/pypa/manylinux1_i686 /output/build.sh
    sudo chown $(id -un):$(id -un) %s/*
    ''' % (output_dir, output_dir, output_dir))
    #os.unlink(output_file)


class Target(object):
    def __init__(self, name,
            chdir=DEFAULT_CHDIR,
            run_cmd=DEFAULT_RUN_CMD,
            copy_cmd=DEFAULT_COPY_CMD,
            dl_cmd=None,
            dir_name=None,
            git_target=None,
            tar_target=None,
            zip_target=None):

        self.name = name
        self.chdir = chdir
        self.run_cmd = run_cmd
        self.copy_cmd = copy_cmd
        self.dl_cmd = dl_cmd
        self.dir_name = dir_name

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

    def run(self, output):
        assert self.dl_cmd is not None
        assert self.name is not None
        assert self.dir_name is not None
        output.write('echo "\\e[32mWorking on %s\\e[0m"\n' % self.name)
        output.write(self.dl_cmd + '\n')
        output.write('cd "%s"\n' % os.path.join(self.dir_name, self.chdir))
        output.write(self.run_cmd + '\n')
        output.write(self.copy_cmd + '\n')
        output.write('cd -\n\n')

if __name__ == '__main__':
    main()
