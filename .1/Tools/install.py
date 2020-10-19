##
## Author: Michel F. Sanner, Anna Omelchenko
## Date: Dec 2014
## CopyRight: Michel F.SANNER and TSRI
##
##
import os, re, sys, string

#print "python executable", sys.executable
#print "prefix:", sys.prefix
#print "exec_prefix:", sys.exec_prefix

from os import path
import warnings
import tarfile
import compileall
from shutil import copy

compile = False
import getopt
noLicense = False
optlist, pargs = getopt.getopt(sys.argv[1:], 'cl')
if len(optlist):
    for opt in optlist:
        if opt[0] == "-c":
            compile = True
        elif opt[0] == "-l":
            noLicense = True

#
#print os.environ['PYTHONHOME']
# 
cwd = os.getcwd()
#print "current directory", cwd
mgl_root = path.abspath(os.environ['MGL_ROOT'])
mgl_archosv = os.environ['MGL_ARCHOSV']
bindir = path.join(mgl_root, 'bin')

#print "mgl_root", mgl_root
#print "mgl_archosv", mgl_archosv

# 1- Untar and install MGLPACKS
print 'Installing  MGLPackages'
py_version =  (string.split(sys.version))[0][0:3]
#print "python version:", py_version


scriptsInst = path.join(mgl_root, 'bin')

mglPckgsDir = 'MGLToolsPckgs'

mglTars = ['MGLToolsPckgs', 'Data', 'ThirdPartyPacks']

for name in mglTars:
    instDir = mgl_root
    if path.exists(name+'.tar.gz'):
        print "Installing files from %s " % name+'.tar.gz'
        # uncompress the tarFile
        tf = tarfile.open(name+'.tar.gz', 'r:gz')
        for tfinfo in tf:
            tf.extract(tfinfo, path=instDir)
        tf.close()
if path.exists("LICENSE.txt") and not path.samefile(cwd, instDir):
    copy("LICENSE.txt", instDir)
if compile: #compile Python source files to byte-code files
    try:
        compileall.compile_dir(path.join(mgl_root, "lib"))
    except:
        print "Compillation error"
        
# copy ./Tools/archosv to scriptsInst

copy(path.join("Tools", "archosv"), scriptsInst)

print "Creating scripts"

templatePath = path.join(cwd, 'Tools/scriptTemplate')
f = open(templatePath, 'r')
tplLines = f.readlines()
f.close()

# Get the MGL_ROOT line
#l = filter(lambda x: x.startswith('MGL_ROOT='), tplLines)
l = [x for x in tplLines if x.startswith('MGL_ROOT=')]
if l:
    l = l[0]
    lIndex = tplLines.index(l)
    # set it to the right path
    tplLines[lIndex] = 'MGL_ROOT="%s" \n'%mgl_root

# Make pmv2 (for PmvApp)

pmv2Script = path.join("$MGL_ROOT", mglPckgsDir,'PmvApp', 'GUI', 'Qt', 'bin', 'runPmv.py' )
pmv2lines = """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(pmv2Script, pmv2Script)
pmv2shPath = path.join(bindir, 'pmv2')
f = open(pmv2shPath, 'w')
f.writelines(tplLines)
f.write(pmv2lines)
f.close()
os.chmod(pmv2shPath, 509)

# make adfr script 
adfrScript = path.join("$MGL_ROOT", mglPckgsDir, 'ADFR',  'bin', 'runADFR.py')
adfrlines = """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(adfrScript, adfrScript)
adfrshPath = path.join(bindir, 'adfr')
f = open(adfrshPath, 'w')
f.writelines(tplLines)
f.write(adfrlines)
f.close()
os.chmod(adfrshPath, 509)

# make adfrgui script 
#adfrguiScript = path.join("$MGL_ROOT", mglPckgsDir, 'ADFR',  'bin', 'ADFRgui.py')
#adfrguilines = """if test $# -gt 0
#then
#	exec $python $pyflags %s $@
#else
#	exec $python $pyflags %s
#fi
#"""%(adfrguiScript, adfrguiScript)
#adfrguishPath = path.join(bindir, 'adfrgui')
#f = open(adfrguishPath, 'w')
#f.writelines(tplLines)
#f.write(adfrguilines)
#f.close()
#os.chmod(adfrguishPath, 509) 

# make agfr script 
agfrScript = path.join("$MGL_ROOT", mglPckgsDir, 'ADFR',  'bin', 'runAGFR.py')
agfrlines = """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(agfrScript, agfrScript)
agfrshPath = path.join(bindir, 'agfr')
f = open(agfrshPath, 'w')
f.writelines(tplLines)
f.write(agfrlines)
f.close()
os.chmod(agfrshPath, 509)

# make agfrgui script 
agfrguiScript = path.join("$MGL_ROOT", mglPckgsDir, 'ADFR',  'bin', 'AGFRgui.py')
agfrguilines = """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(agfrguiScript, agfrguiScript)
agfrguishPath = path.join(bindir, 'agfrgui')
f = open(agfrguishPath, 'w')
f.writelines(tplLines)
f.write(agfrguilines)
f.close()
os.chmod(agfrguishPath, 509)

# make about script 
aboutScript = path.join("$MGL_ROOT", mglPckgsDir, 'ADFR',  'bin', 'about.py')
aboutlines = """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(aboutScript, aboutScript)
aboutshPath = path.join(bindir, 'about')
f = open(aboutshPath, 'w')
f.writelines(tplLines)
f.write(aboutlines)
f.close()
os.chmod(aboutshPath, 509)

# make autosite script 
autositeScript = path.join("$MGL_ROOT", mglPckgsDir, 'AutoSite',  'bin', 'AS.py')
autositelines = """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(autositeScript, autositeScript)
autositeshPath = path.join(bindir, 'autosite')
f = open(autositeshPath, 'w')
f.writelines(tplLines)
f.write(autositelines)
f.close()
os.chmod(autositeshPath, 509)

#prepare_receptor , prepare_ligand

if path.exists(path.join(mgl_root, "MGLToolsPckgs", "AutoDockTools", "Utilities24")):
    prepareRecScript = path.join("$MGL_ROOT", mglPckgsDir, "AutoDockTools", "Utilities24", "prepare_receptor4.py")
    prepareRecLines =  """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(prepareRecScript, prepareRecScript)
    prepareRecPath = path.join(bindir, 'prepare_receptor')
    f = open(prepareRecPath, 'w')
    f.writelines(tplLines)
    f.write(prepareRecLines)
    f.close()
    os.chmod(prepareRecPath, 509)

    prepareLigScript = path.join("$MGL_ROOT", mglPckgsDir, "AutoDockTools", "Utilities24", "prepare_ligand4.py")
    prepareLigLines =  """if test $# -gt 0
then
	exec $python $pyflags %s $@
else
	exec $python $pyflags %s
fi
"""%(prepareLigScript, prepareLigScript)
    prepareLigPath = path.join(bindir, 'prepare_ligand')
    f = open(prepareLigPath, 'w')
    f.writelines(tplLines)
    f.write(prepareLigLines)
    f.close()
    os.chmod(prepareLigPath, 509)


# Make raccoon

#raccoonScript = path.join("$MGL_ROOT", mglPckgsDir,'Raccoon', 'GUI', 'raccoonGUI.py' )
#raccoonlines = """if test $# -gt 0
#then
#	exec $python $pyflags %s $@
#else
#	exec $python $pyflags %s
#fi
#"""%(raccoonScript, raccoonScript)
#raccoonshPath = path.join(bindir, 'raccoon')
#f = open(raccoonshPath, 'w')
#f.writelines(tplLines)
#f.write(raccoonlines)
#f.close()
#os.chmod(raccoonshPath, 509)

# Make tester

## testerScript = path.join("$MGL_ROOT", mglPckgsDir,'mglutil','TestUtil', 'bin', 'tester' )
## testerlines = """if test $# -gt 0
## then
## 	exec $python $pyflags %s $@
## else
## 	exec $python $pyflags %s
## fi
## """%(testerScript, testerScript)
## testershPath = path.join(bindir, 'tester')
## f = open(testershPath, 'w')
## f.writelines(tplLines)
## f.write(testerlines)
## f.close()
## os.chmod(testershPath, 509)

# Make python executable
if sys.platform == 'darwin':
    #comment open -a X11
    #l = filter(lambda x: x.find('This assumes X11 is installed') != -1, tplLines)
    l = [x for x in tplLines if x.find('This assumes X11 is installed') != -1]
    if l:
        l = l[0]
        lIndex = tplLines.index(l)
        for i in range(1,10):
    	    tplLines[lIndex+i] = "#"+tplLines[lIndex+i]
    	    
pythonlines = """if test $# -gt 0
then
	exec $python $pyflags "$@"
else
	exec $python $pyflags 
fi
"""
pythonshPath = path.join(bindir, 'pythonsh')
f = open(pythonshPath, 'w')
f.writelines(tplLines)
f.write(pythonlines)
f.close()
os.chmod(pythonshPath, 509)

#create mglenv.sh and mglenv.csh files
mglenvshPath = path.join(bindir, 'mglenv.sh')
f = open(mglenvshPath , 'w')
f.writelines(tplLines)
f.close()
os.chmod(mglenvshPath, 509)


f = open(path.join(cwd, 'Tools/mglenv.csh'), 'r')
mglenvLines = f.readlines()
f.close()
# Get the MGL_ROOT line
#l = filter(lambda x: x.startswith('setenv MGL_ROOT'), mglenvLines)
l = [x for x in mglenvLines if x.startswith('setenv MGL_ROOT')]
if l:
    l = l[0]
    lIndex = mglenvLines.index(l)
    # set it to the right path
    mglenvLines[lIndex] = 'setenv MGL_ROOT %s\n'%mgl_root
mglenvcshPath = path.join(bindir, 'mglenv.csh')
f = open(mglenvcshPath , 'w')
f.writelines(mglenvLines)
f.close()
os.chmod(mglenvcshPath, 509)

# create mgl scripts to run OpenBabel executables
obexecs= ["babel", "obchiral", "obenergy",  "obgen", "obminimize",  "obprop", "obrotamer",  "obspectrophore", "obabel", "obconformer",  "obfit", "obgrep",  "obprobe", "obrms", "obrotate",   "roundtrip"]
templatePath = path.join(cwd, 'Tools/obscriptTemplate')
f = open(templatePath, 'r')
tplLines = f.readlines()
f.close()

# Get the MGL_ROOT line
l = [x for x in tplLines if x.startswith('MGL_ROOT=')]
if l:
    l = l[0]
    lIndex = tplLines.index(l)
    # set it to the right path
    tplLines[lIndex] = 'MGL_ROOT="%s" \n'%mgl_root

for obfile in obexecs:
    oblines = """obexec="$MGL_ROOT/bin/%s"\nexec $obexec  $@""" %(obfile,)
    obPath = path.join(bindir, "mgl%s"%obfile)
    f = open(obPath, 'w')
    f.writelines(tplLines)
    f.write(oblines)
    f.close()
    os.chmod(obPath, 509)


#create sitecustomize.py
f1 = open(os.path.join(mgl_root, mglPckgsDir, "Support", "sitecustomize.py"))
txt = f1.readlines()
f1.close()
f2 = open(os.path.join(mgl_root, "lib", "python%s"%py_version, "sitecustomize.py"), "w")
f2.write("mglroot = '%s'\n" % mgl_root)
if os.environ.has_key("MGL64"):
    f2.write("import os\n")
    f2.write("os.environ['MGL64']='1'\n")
f2.writelines(txt)
f2.close()

# check if initPython is sourced in your shell ressource file
#shell = sys.argv[1]
print "current directory:", os.getcwd()
alias_csh = """alias pmv2 %s/bin/pmv2
alias agfr %s/bin/agfr
alias autosite %s/bin/autosite
alias adfr %s/bin/adfr
alias raccoon %s/bin/raccoon
alias pythonsh %s/bin/pythonsh\n""" % (mgl_root, mgl_root, mgl_root, mgl_root, mgl_root, mgl_root,)
alias_sh="""alias pmv2='%s/bin/pmv2'
alias agfr='%s/bin/agfr'
alias autosite='%s/bin/autosite'
alias adfr='%s/bin/adfr'
alias raccoon='%s/bin/raccoon'
alias pythonsh='%s/bin/pythonsh'\n""" % (mgl_root, mgl_root, mgl_root, mgl_root, mgl_root, mgl_root,)


f = open("initMGLtools.csh", "w")
f.write(alias_csh)
f.close()

f = open("initMGLtools.sh", "w")
f.write(alias_sh)
f.close()

#license part:

if not noLicense:
    text = """\nThe molecular surface calculation software (MSMS) is freely available for academic research.\nFor obtainig commercial license usage contact Dr. Sanner at sanner@scripps.edu.\n ACADEMIC INSTALLATION (Y/N) ?"""
    ans = raw_input(text)
    if ans=='':
        ans = 'Y'
    while ans[0] not in ['y', 'Y', 'n', 'N']:
        ans = raw_input("Please enter Y or N: ")
    if ans[0] in ['y', 'Y']:
        #academic installation -->> rename mslibACA mslib
        mslib = path.join(mgl_root, "MGLToolsPckgs", "mslibACA")
    else: # commercial installation: rename mslibCOM mslib
        mslib = path.join(mgl_root, "MGLToolsPckgs", "mslibCOM")
    if path.exists(mslib):
        os.rename(mslib, path.join(mgl_root, "MGLToolsPckgs", "mslib") )

print """\n MGLTools installation complete.
To run MGLTools scripts(pmv2, agfr, agfrgui, adfr, autosite, about, pythonsh) located at:
%s/bin
you will need to add  %s/bin to the path environment variable in .cshrc or .bashrc:
.cshrc:
set path = (%s/bin $path)

.bashrc:
export PATH=%s/bin:$PATH

"""%(mgl_root, mgl_root, mgl_root, mgl_root)

