'''

Stupid library to get CMSSW version

'''

import os
import subprocess
import re

_fsa_directory = os.path.join(
    os.environ['CMSSW_BASE'], 'src', 'FinalStateAnalysis')

def cmssw_version():
    return os.getenv('CMSSW_VERSION')

def cmssw_major_version():
    return int(os.getenv('CMSSW_VERSION').split('_')[1])

def cmssw_minor_version():
    return int(os.getenv('CMSSW_VERSION').split('_')[2])

def fsa_version():
    ''' Get commit hash of FSA '''
    result = subprocess.Popen(
        ['git', 'log', '-1', '--format=%h'],
        cwd=_fsa_directory, stdout=subprocess.PIPE).communicate()[0]
    return result.strip()

def repo_status():
    ''' Get status of FSA repository '''
    result = subprocess.Popen(
        ['git', 'status', '-s'],
        cwd=_fsa_directory, stdout=subprocess.PIPE).communicate()[0]
    return result.strip()

if __name__ == "__main__":
    print "Version info:"
    print "CMSSW: %s - major = %i" % (cmssw_version(), cmssw_major_version())
    print "Commit: %s" % fsa_version()
    print "Repo Status:\n%s" % repo_status()

