#!/bin/sh

fingerprintlib=FingerJetFXOSE
netpbm=netpbm-10.47.67
base_dir=`pwd`
bmptopgm=${base_dir}/bmp-to-pgm

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
opcheck $? "OS check: The test script is specific to Ubuntu OS."

echo "\nThis will install dependency 'netpbm', then run some checks using binaries built for the sample job."
echo "Enter to accept / ^C to abort."
read confirm
if [ ! -x ${base_dir}/$fingerprintlib/bin/fjfxSample ]; then
   echo " !> FAIL: No fjfxSample binary or is not executable. Abort."
   exit 254
fi
if [ ! -r ${base_dir}/$fingerprintlib/lib/libfjfx.so ]; then
   echo " !> FAIL: libfjfx.so library not found. Abort."
   exit 250
fi
if [ ! -r ${bmptopgm}/libbmptopnm.so ]; then 
   echo " !> FAIL: No ${bmptopgm}/libbmptopnm.a library. Abort."
   exit 253
fi
if [ ! -r /etc/ld.so.conf.d/bmptopgm.conf ]; then
   echo " !> FAIL: ld configuration for libbmptopnm.a is not installed. Abort."
   exit 252
fi
if [ ! -x ./fingerprint ]; then 
   echo " !> FAIL: No ./fingerprint or is not executable. Abort." 
   exit 251
fi
if [ ! -r ./test.bmp ]; then
   echo " !> FAIL: No test.bmp . Abort."
   exit 249
fi
echo "Installing software dependencies.."
sudo apt-get -qq install netpbm

echo "\nStarting tests:\n"
bmptoppm ./test.bmp > ./test.ppm
ppmtopgm ./test.ppm > ./test.pgm
opcheck $? "created ./test.pgm from ./test.bmp using 'netpbm' ubuntu package tools to check our binaries."

FingerJetFXOSE/bin/fjfxSample ./test.pgm ./test.result
opcheck $? "FingerJetFXOSE/bin/fjfxSample made ISO/IEC 19794-2 file ./test.result , exit code 0 ."

./fingerprint ./test.bmp ./test.result_
opcheck $? "./fingerprint made ISO/IEC 19794-2 file ./test.result_ , exit code 0 ."

diff test.result test.result_
opcheck $? "ISO/IEC 19794-2 files made by FingerJetFXOSE/bin/fjfxSample and ./fingerprint are equal."

echo "tests passed."
