#!/bin/bash
build=/home/piasek/android/Piasek-G2
kernel="Piasek-KK"
version="0.4"
rom="LG"
ramdisk=ramdisk
toolchain=/home/piasek/android/toolchain/bin
toolchain2="arm-eabi-"
kerneltype="zImage"
jobcount="-j4"
base=0x00000000
pagesize=2048
ramdisk_offset=0x05000000
tags_offset=0x04800000
cmdline="console=ttyHSL0,115200,n8 androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_lgd_cmd"

			export ARCH=arm
			export CCOMPILE=$CROSS_COMPILE
			export CROSS_COMPILE=arm-eabi- 
			export PATH=$PATH:/home/piasek/android/toolchain/bin

echo "Pick variant..."

		variant="d802"
		config="d802_defconfig"
		ramdisk=ramdisk/d802.lz4
		
#select choice in d800 d801 d802 d803 ls980 vs980 f320x
#do
#case "$choice" in
#	"d800")
#		variant="d800"
#		config="d800_defconfig"
#		ramdisk=ramdisk/d800.lz4
#		break;;
#	"d801")
#		variant="d801"
#		config="d801_defconfig"
#		ramdisk=ramdisk/d801.lz4
#		break;;
#	"d802")
#		variant="d802"
#		config="d802_defconfig"
#		ramdisk=ramdisk/d802.lz4
#		break;;
#	"d803")
#		variant="d803"
#		config="d803_defconfig"
#		ramdisk=ramdisk/d803.lz4
#		break;;
#	"ls980")
#		variant="ls980"
#		config="ls980_defconfig"
#		cmdline="console=ttyHSL0,115200,n8 androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_lgd_cmd gpt"
#		ramdisk=ramdisk/ls980.lz4
#		break;;
#	"vs980")
#		variant="vs980"
#		config="vs980_defconfig"
#		ramdisk=ramdisk/vs980.lz4
#		break;;
#	"f320x")
#		variant="f320x"
#		config="f320x_defconfig"
#		ramdisk=ramdisk/f320x.lz4
#esac
#done

# Begin commands
rm -rf out
mkdir out
mkdir out/tmp
echo "Checking for build..."
if [ -f ozip/boot.img ]; then
	read -p "Previous build found, clean working directory..(y/n)? : " cchoice
	case "$cchoice" in
		y|Y )
			export ARCH=arm
			export CCOMPILE=$CROSS_COMPILE
			export CROSS_COMPILE=arm-eabi- 
			export PATH=$PATH:/home/piasek/android/toolchain/bin
			rm -rf ozip/{system,boot.img}
			rm -rf arch/arm/boot/"$kerneltype"
			mkdir -p ozip/system/lib/modules
			make clean && make mrproper
			echo "Working directory cleaned...";;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
	read -p "Begin build now..(y/n)? : " dchoice
	case "$dchoice" in
		y|Y)
			make "$config"
			make "$jobcount"
			exit 0;;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
fi
if [ -f arch/arm/boot/"$kerneltype" ]; then
	cp arch/arm/boot/"$kerneltype" out
	rm -rf ozip/system
	mkdir -p ozip/system/lib/modules
	find . -name "*.ko" -exec cp {} ozip/system/lib/modules \;
else
	echo "Nothing has been made..."
	read -p "Clean working directory..(y/n)? : " achoice
	case "$achoice" in
		y|Y )
			export ARCH=arm
			export CROSS_COMPILE=$toolchain/"$toolchain2"
			rm -rf ozip/{system,boot.img}
			rm -rf arch/arm/boot/"$kerneltype"
			mkdir -p ozip/system/lib/modules
			make clean && make mrproper
			echo "Working directory cleaned...";;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
	read -p "Begin build now..(y/n)? : " bchoice
	case "$bchoice" in
		y|Y)
			make "$config"
			make "$jobcount"
			exit 0;;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
fi

if [ -f $ramdisk ]; then
	echo "Using prebuilt ramdisk..."
else
	echo "No ramdisk found..."
	exit 0;
fi

echo "Making DT.img..."
if [ -f arch/arm/boot/$kerneltype ]; then
	dtbTool -s 2048 -o out/dt.img arch/arm/boot/
else
	echo "No build found..."
	exit 0;
fi	

echo "Making boot.img..."
if [ -f arch/arm/boot/"$kerneltype" ]; then
	mkbootimg_dtb --kernel out/"$kerneltype" --ramdisk $ramdisk --cmdline "$cmdline" --base $base --pagesize $pagesize --ramdisk_offset $ramdisk_offset --tags_offset $tags_offset --dt out/dt.img -o ozip/boot.img
else
	echo "No build found..."
	exit 0;
fi

echo "Zipping..."
cd ozip
zip -r ../"$kernel"-$version-"$rom"_"$variant".zip .
mv ../"$kernel"-$version-"$rom"_"$variant".zip $build
cd ..
rm -rf out
echo "Done..."
