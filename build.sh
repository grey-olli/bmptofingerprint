#!/bin/sh

fingerprintlib=FingerJetFXOSE
netpbm=netpbm-10.47.67
base_dir=`pwd`
bmptopgm=${base_dir}/bmp-to-pgm
ubuntu_deps="g++ wget git gcc make binutils patch gzip tar coreutils libc6 libc-bin zlib1g-dev diffutils sed grep debianutils"
#original sourceforge
netpbmurl=https://sourceforge.net/projects/netpbm/files/super_stable/10.47.67/${netpbm}.tgz
# sourceforge some times fails - use mirror
#netpbmurl=https://fossies.org/linux/misc/${netpbm}.tgz

opcheck () {
  code=$1
  notice=$2
  if [ $code != 0 ]; then
     echo " !> FAIL: $notice . Abort."
     echo "Cannot build automatically. Please try manually repeat commands in $0 ."
     exit $code
    else
      echo " -> SUCCESS: $notice"
  fi
}

## here we start
grep -i ubuntu /etc/*release* >/dev/null 2>/dev/null
opcheck $? "OS check. The build script is specific to Ubuntu OS"

echo "This will install dependencies, then build and run sample code in $base_dir ."
echo "Enter to accept / ^C to abort."
read confirm
# ubuntu
echo "Installing software dependencies.."
sudo apt-get -qq install $ubuntu_deps
if [ ! -d ${base_dir}/$fingerprintlib ]; then
    git clone https://github.com/${fingerprintlib}/${fingerprintlib}.git
    opcheck $? 'git clone https://github.com/FingerJetFXOSE/FingerJetFXOSE.git'
  else
    echo "\nFingerJetFXOSE source dir already present."
fi
cd $base_dir/FingerJetFXOSE
echo "Executing make for ${fingerprintlib}.."
log=make.`date +%Y%m%d_%T`.log
make 2>>$log 1>>$log 
opcheck $? "make in `pwd`"
echo "\nmake for $fingerprintlib is done.\n"
sudo sh -c '/bin/echo -e "#fingerprint lib\n`pwd`/lib" > /etc/ld.so.conf.d/FingerJetFXOSE.conf'
opcheck $? "Installing /etc/ld.so.conf.d/FingerJetFXOSE.conf"
cd $base_dir
sudo ldconfig
if [ ! -r ./${netpbm}.tgz ]; then
    wget $netpbmurl
    opcheck $? "wget ${netpbmurl}"
  else
    echo "${netpbm}.tgz already downloaded."
fi
tar xzf ${netpbm}.tgz
cd $netpbm
rm -f config.mk 2>/dev/null
echo "\nNow configure will be executed for netpbm-10.47.67. Please select all default values and apply these setting:"
echo "gnu platform, regular build, shared libraries, no static libraries."
echo "All other questions - just press Enter and ignore build errors:"
echo "we need only some files here to be generated - that require conffigure && make to be executed, but not nesessary fully succeed with make."
echo "The whole netpbm-10.47.67 is NOT subject for install.\n"
echo "Press Enter to continue."
read confirm
./configure
echo "Executing make.."
log=make.`date +%Y%m%d_%T`.log
make 2>>$log 1>>$log
echo "configure ; make for $netpbm finished (ignoring make errors)."
#cd $base_dir/${netpbm}/converter/other
#make
cd $base_dir
rm -Rf ${bmptopgm} 2>/dev/null >/dev/null
echo "Extracting files from $netpbm we depend on.."
mkdir -p $bmptopgm
for f in `cat ${base_dir}/${netpbm}_dependencies.txt|tr '\n' ' '`; do
 cp -f $netpbm/$f $bmptopgm
 opcheck $? "cp -f $netpbm/$f $bmptopgm"
done
cd $bmptopgm
echo "Fixing imports.."
for f in *; do 
  sed -i "s@#include <netpbm/@#include <@g" $f 
  sed -i "s@#include netpbm/@#include @g" $f 
done
cd $base_dir
echo "Creating bmptopnm_as_lib.c , bmptopnm.h with patch.."
patch -i patch1.diff ./${netpbm}/converter/other/bmptopnm.c -o ./bmp-to-pgm/bmptopnm_as_lib.c
patch -i patch2.diff ./${netpbm}/converter/other/bmptopnm.c -o ./bmp-to-pgm/bmptopnm.h
cp ./${netpbm}/lib/libpgm2.c ./bmp-to-pgm/libpgm2.c
cd $bmptopgm
echo "Compiling extracted sources.."
log=bmptopgm-build-output.`date +%Y%m%d_%T`.log
#gcc -c -I. *.c  2>>$log 1>>$log
gcc -fPIC -c -I. *.c 2>>$log 1>>$log
echo "Creating shared library.."
#ar rvs libbmptopnm.a *.o 
gcc -shared -Wl,-soname,libbmptopnm.so -o libbmptopnm.so *.o 2>>$log 1>>$log
echo "Installing /etc/ld.so.conf.d/bmptopgm.conf .."
sudo sh -c '/bin/echo -e "#bpmtopgm custom lib\n`pwd`" > /etc/ld.so.conf.d/bmptopgm.conf'
opcheck $? "Installing /etc/ld.so.conf.d/bmptopgm.conf" 
sudo ldconfig
cd $base_dir
echo "\nFinally compiling our code.."
rm -f ./fingerprint
log=fingerprint.c_compile.log
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/FingerJetFXOSE/lib:`pwd`/bmp-to-pgm
gcc fingerprint.c -o fingerprint -L ./FingerJetFXOSE/lib -lfjfx -I./FingerJetFXOSE/include/ -I./bmp-to-pgm -L./bmp-to-pgm -lbmptopnm -lm 2>>$log 1>>$log
opcheck $? "compiling fingerprint.c"
