#!/bin/sh

fingerprintlib=FingerJetFXOSE
netpbm=netpbm-10.47.67
base_dir=`pwd`
bmptopgm=${base_dir}/bmp-to-pgm
## here we start
echo "This will clear changes made by build.sh:"
echo "  remove from $base_dir all downloaded files, compiled binaries, libs and dirs made while build process"
echo "  undo ld system confiuration changes."
echo "Enter to continue, ^C to abort."
read confirm
rm -Rf ${base_dir}/${netpbm}.tgz ${base_dir}/$netpbm ${bmptopgm} $fingerprintlib fingerprint test.result* test.pgm test.ppm *.log
sudo rm -f /etc/ld.so.conf.d/bmptopgm.conf /etc/ld.so.conf.d/FingerJetFXOSE.conf
sudo ldconfig

