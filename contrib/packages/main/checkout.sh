#!/bin/bash

SCALARIS_VERSION="0.8.0+git"
date=`date +"%Y%m%d.%H%M"`
name="scalaris" # folder base name (without version)
url="https://github.com/scalaris-team/scalaris.git"
deletefolder=0 # set to 1 to delete the folder the repository is checked out to

#####

folder="./${name}"

if [ ! -d "${folder}" ]; then
  echo "checkout ${url} -> ${folder} ..."
  git clone "${url}" "${folder}"
  result=$?
else
  echo "update ${url} -> ${folder} ..."
  cd "${folder}"
  git pull
  result=$?
  cd - >/dev/null
fi

if ! diff -q checkout.sh "${folder}/contrib/packages/main/checkout.sh" > /dev/null ; then
  echo "checkout-script changed - re-run ./checkout.sh"
  cp "${folder}/contrib/packages/main/checkout.sh" ./ ; exit 1
fi

if [ ${result} -eq 0 ]; then
  echo -n "get git revision ..."
  revision=`cd "${folder}" && git log --pretty=format:'%h' -n 1`
  result=$?
  echo " ${revision}"
  pkg_version="${SCALARIS_VERSION}${date}.${revision}"
fi

if [ ${result} -eq 0 ]; then
  tarfile="${folder}-${pkg_version}.tar.gz"
  newfoldername="${folder}-${pkg_version}"
  echo "making ${tarfile} ..."
  mv "${folder}" "${newfoldername}" && tar -czf "${tarfile}" "${newfoldername}" --exclude-vcs && mv "${newfoldername}" "${folder}"
  result=$?
fi

if [ ${result} -eq 0 ]; then
  echo "extracting .spec file ..."
  sourcefolder="${folder}/contrib/packages/main"
  sed -e "s/%define pkg_version .*/%define pkg_version ${pkg_version}/g" \
      < "${sourcefolder}/scalaris.spec"              > ./scalaris.spec && \
  cp  "${sourcefolder}/scalaris-rpmlintrc"             ./scalaris-rpmlintrc && \
  cp  "${sourcefolder}/scalaris.changes"               ./scalaris.changes
  result=$?
fi

if [ ${result} -eq 0 ]; then
  echo "extracting Debian package files ..."
  sourcefolder="${folder}/contrib/packages/main"
  sed -e "s/Version: .*-.*/Version: ${pkg_version}-1/g" \
      -e "s/scalaris\\.orig\\.tar\\.gz/scalaris-${pkg_version}\\.orig\\.tar\\.gz/g" \
      -e "s/scalaris\\.diff\\.tar\\.gz/scalaris-${pkg_version}\\.diff\\.tar\\.gz/g" \
      < "${sourcefolder}/scalaris.dsc"                > ./scalaris.dsc && \
  sed -e "0,/(.*-.*)/s//(${pkg_version}-1)/" \
      -e "0,/ -- Nico Kruber <kruber@zib.de>  .*/s// -- Nico Kruber <kruber@zib.de>  `LANG=C date -R`/" \
      < "${sourcefolder}/debian.changelog"            > ./debian.changelog && \
  cp  "${sourcefolder}/debian.compat"                   ./debian.compat && \
  cp  "${sourcefolder}/debian.control"                  ./debian.control && \
  cp  "${sourcefolder}/debian.rules"                    ./debian.rules && \
  cp  "${sourcefolder}/debian.scalaris.prerm"           ./debian.scalaris.prerm && \
  cp  "${sourcefolder}/debian.scalaris.postrm"          ./debian.scalaris.postrm && \
  cp  "${sourcefolder}/debian.scalaris.postinst"        ./debian.scalaris.postinst && \
  cp  "${sourcefolder}/debian.source.lintian-overrides" ./debian.source.lintian-overrides && \
  cp  "${folder}/LICENSE"                               ./debian.copyright
  result=$?
fi

if [ ${result} -eq 0 ]; then
  echo "extracting ArchLinux package files ..."
  sourcefolder="${folder}/contrib/packages/main"
  tarmd5sum=`md5sum ${tarfile} | cut -d' ' -f 1` && \
  sed -e "s/pkgver=.*/pkgver=${pkg_version}/g" \
      -e "s/md5sums=('.*')/md5sums=('${tarmd5sum}')/g" \
      < "${sourcefolder}/PKGBUILD"                   > ./PKGBUILD && \
  cp  "${sourcefolder}/install"                        ./install
  result=$?
fi

if [ ${result} -eq 0 -a ${deletefolder} -eq 1 ]; then
  echo "removing ${folder} ..."
  rm -rf "${folder}"
fi
