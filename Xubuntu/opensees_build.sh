#! /bin/bash
_gitRepo="https://github.com/OpenSees/OpenSees.git"
srcdir="${PWD}"
_installdir="/usr"
_gitmod="OpenSees"
pkgver=3.4.0
pkgrel=1

sudo apt-get install git build-essential mesa-common-dev libpng-dev gfortran tcl tcl-dev libglu1-mesa-dev libpython3-all-dev python3 python-is-python3 pkg-config tk tk-dev
sudo apt-get install libmumps-dev libscotch-dev libscalapack-openmpi-dev openmpi-bin

cd "${srcdir}"

echo $(tput bold) "Starting GIT checkout..."  $(tput sgr0)
echo $(tput bold) "${srcdir}" $(tput sgr0)
if [ -d ${srcdir}/${_gitmod}/.git ]; then
  (echo 'Copy of repository exists')
  else
  (git clone ${_gitRepo})
fi
cd OpenSees
git checkout v${pkgver}
git checkout -- .

echo $(tput bold) "GIT checkout done or server timeout"  $(tput sgr0)

cd "${srcdir}/${_gitmod}"
gitrel=$(git rev-parse HEAD)
opsVer="#define OPS_VERSION \"${pkgver}_${pkgrel} (commit ${gitrel})\""

echo $(tput bold) "Configuring..."  $(tput sgr0)
cp "${srcdir}/Makefile.def" ./ || return 1

sed -e "s|#define OPS_VERSION.*|${opsVer}|" \
  -i "${srcdir}/${_gitmod}/SRC/OPS_Globals.h"
sed -e "s|#define OPS_VERSION.*|${opsVer}|" \
  -i "${srcdir}/${_gitmod}/DEVELOPER/core/OPS_Globals.h"
      
echo $(tput bold) "Patching..."   $(tput sgr0)
# Update SRC/Makefile.inc to use include directories defined in Makefile.def
#git apply "${srcdir}/Makefile.inc.Math.patch"

# Following patch only needed if using csparse from OS Repository
# Correct PFEM solver header files for cxspare
# Correct PFEM solver header files for correctly including  umfpack.h
#git apply "${srcdir}/fix_CSPARSE_UMFPACKHdr.patch"
  
mkdir -p ${srcdir}/bin
mkdir -p ${srcdir}/lib

echo $(tput bold) "Building OpenSees..."   $(tput sgr0)
make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" clean;
make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" wipe;
rm ${srcdir}/lib/*.a
make -j$(nproc) "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" >../log.log 2>&1
# make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" 2>&1 | tee log.log

echo $(tput bold) "Building OpenSeesSP..."   $(tput sgr0)
make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" clean;
make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" wipe;
rm ${srcdir}/lib/*.a
# make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" "OpenSees_PROGRAM = ${srcdir}/bin/OpenSeesSP" "PROGRAMMING_MODE = PARALLEL" >logSP.log 2>&1
make -j$(nproc) "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" "OpenSees_PROGRAM = ${srcdir}/bin/OpenSeesSP" "PROGRAMMING_MODE = PARALLEL" >../logSP.log 2>&1


echo $(tput bold) "Building OpenSeesMP..."   $(tput sgr0)
make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" clean;
make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" wipe;
rm ${srcdir}/lib/*.a
#make "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" "OpenSees_PROGRAM = ${srcdir}/bin/OpenSeesMP" "PROGRAMMING_MODE = PARALLEL_INTERPRETERS" >logMP.log 2>&1
make -j$(nproc) "INSTALLDIR=${srcdir}" "SRCDIR=${srcdir}" "OpenSees_PROGRAM = ${srcdir}/bin/OpenSeesMP" "PROGRAMMING_MODE = PARALLEL_INTERPRETERS" >../logMP.log 2>&1
