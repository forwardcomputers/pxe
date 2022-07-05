#!/bin/bash
#
_grubdir="/opt/filer/os/pxe/grub"
_keysdir="/opt/filer/os/pxe/keys"
#
# modules from https://salsa.debian.org/grub-team/grub/-/raw/master/debian/build-efi-images
#
CD_MODULES="
	all_video
	boot
	btrfs
	cat
	chain
	configfile
	echo
	efifwsetup
	efinet
	ext2
	fat
	font
	f2fs
	gettext
	gfxmenu
	gfxterm
	gfxterm_background
	gzio
	halt
	help
	hfsplus
	iso9660
	jfs
	jpeg
	keystatus
	loadenv
	loopback
	linux
	ls
	lsefi
	lsefimmap
	lsefisystab
	lssal
	memdisk
	minicmd
	normal
	ntfs
	part_apple
	part_msdos
	part_gpt
	password_pbkdf2
	png
	probe
	reboot
	regexp
	search
	search_fs_uuid
	search_fs_file
	search_label
	sleep
	squash4
	test
	true
	video
	xfs
	zfs
	zfscrypt
	zfsinfo
	"

#	linuxefi
# Platform-specific modules
CD_MODULES="$CD_MODULES
	cpuid
	play
	tpm
	"

GRUB_MODULES="$CD_MODULES
	cryptodisk
	gcry_arcfour
	gcry_blowfish
	gcry_camellia
	gcry_cast5
	gcry_crc
	gcry_des
	gcry_dsa
	gcry_idea
	gcry_md4
	gcry_md5
	gcry_rfc2268
	gcry_rijndael
	gcry_rmd160
	gcry_rsa
	gcry_seed
	gcry_serpent
	gcry_sha1
	gcry_sha256
	gcry_sha512
	gcry_tiger
	gcry_twofish
	gcry_whirlpool
	luks
	lvm
	mdraid09
	mdraid1x
	raid5rec
	raid6rec
	"
NET_MODULES="$CD_MODULES
	tftp
	"
MY_MODULES="$NET_MODULES
	http
	shim_lock
	"
#
# from https://github.com/rhboot/shim/raw/main/SBAT.md
#
echo "sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
grub,1,Free Software Foundation,grub,@UPSTREAM_VERSION@,https://www.gnu.org/software/grub/
grub.fedora,1,The Fedora Project,grub2,2.04-31.fc33,https://src.fedoraproject.org/rpms/grub2
grub.fedora,1,Red Hat Enterprise Linux,grub2,2.02-0.34.fc24,mail:secalert@redhat.com
grub.rhel,1,Red Hat Enterprise Linux,grub2,2.02-0.34.el7_2,mail:secalert@redhat.com
grub.debian,1,Debian,grub2,@DEB_VERSION@,https://tracker.debian.org/pkg/grub2
shim,1,UEFI shim,shim,16,https://github.com/rhboot/shim" > /tmp/sbat.csv

rm -f /tmp/memdisk-netboot.fat 2>/dev/null
mkfs.msdos -C "/tmp/memdisk-netboot.fat" 64

grub-mkimage \
  -O x86_64-efi \
  -o "${_grubdir}"/grubnetx64.efi.unsigned \
  -m /tmp/memdisk-netboot.fat \
  -p /grub \
  -s /tmp/sbat.csv \
  $MY_MODULES

sbsign \
  --key "${_keysdir}"/DB.key \
  --cert "${_keysdir}"/DB.crt \
  --output "${_grubdir}"/grubnetx64.efi.signed \
  "${_grubdir}"/grubnetx64.efi.unsigned 
