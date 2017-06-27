#!/bin/sh
echo "ABOUT TO DO A NIGHTLY WIP BUILD"
echo "-------------------------------"
sleep 10
cd ~/src/ohr/wip

if [ -n "True" ] ; then
  echo "From: cron@rpg.hamsterrepublic.com"
  echo "To: cron@rpg.hamsterrepublic.com"
  echo "Subject: OHRRPGCE Android nightly build ($(uname -n))"
  echo ""
  svn cleanup
  svn update
  ./distrib-nightly-android.sh 2>&1
fi | tee ~/wrap-nightly-android-output.txt
/usr/sbin/sendmail < ~/wrap-nightly-android-output.txt

echo "------------------"
echo "WILL SHUT DOWN NOW"
sleep 5
/sbin/poweroff
