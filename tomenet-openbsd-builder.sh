#!/bin/sh
VERSION='4.8.0'
REQUIREMENTS="bzip2 p7zip unzip gmake gcc libvorbis libogg sdl-mixer sdl-sound sdl libmikmod libgcrypt"
PACKAGE="tomenet-${VERSION}.tar.bz2"
URL_PACKAGE="https://www.tomenet.eu/downloads/$PACKAGE"
URL_SOUND="http://www.mediafire.com/?issv5sdv7kv3odq"
URL_MUSIC="http://www.mediafire.com/?3j87kp3fgzpqrqn"
URL_FONTS='https://drive.google.com/uc?export=download&id=1CCnHi_BABM_n7ybYL_eiABOyd-kEL_xp'

download(){
	local url=$1
	local to=$2
	ftp -o $to $url
}

mfget() {
	_url="$1"
	_to="$2"
	_direct_url="https://$(ftp -o- -V "$_url" | grep -o 'download[0-9]*\.mediafire.com[^"]*' | tail -1)"
	[ -z "$_direct_url" ] && return 1
	ftp -o "$_to" "$_direct_url" || return 1
	return 0
}

echo 'Hello!
This script downloads sources, resources and builds the game TomeNET (the Tales of Middle Earth)'
echo "The following packages need to be installed:
$REQUIREMENTS
Press ctrl-c to exit or enter to continue"
read
doas pkg_add $REQUIREMENTS

echo "Downloding sources.."
ftp $URL_PACKAGE
tar xjvf $PACKAGE
rm -f $PACKAGE

cd tomenet-${VERSION}/src

echo "Patching sources.."
sed -i -e 's/^CC = gcc/CC = egcc/' -e 's/^CPP = cpp/CPP = ecpp/' -e 's/-lcrypt/-lgcrypt/g' makefile
sed -i 's/^\#  include <sys\/timeb\.h>/\#  include <sys\/time\.h>/' common/h-system.h
echo "Building.."
gmake tomenet
mv ./tomenet ..
gmake clean
cd ..

echo "Turning off font_map_solid_walls.."
sed -i 's/Y:font_map_solid_walls/X:font_map_solid_walls/' ./lib/user/options.prf

echo "Downloading sound pack.."
mfget "$URL_SOUND" sound.7z
7z x sound.7z
rm -f sound.7z
mv -f sound/* ./lib/xtra/sound/
rm -rf sound

echo "Downloading music pack.."
mfget "$URL_MUSIC" music.7z
7z x -ptomenet music.7z
rm -f music.7z
mv -f music/* ./lib/xtra/music/
rm -rf music

echo "Installing Tangar's fonts..."
_fdir="./fonts"
download $URL_FONTS fonts.zip && unzip -q fonts.zip
rm -f fonts.zip
mkdir -p $_fdir
cp ./pcf/* $_fdir
(cd $_fdir && mkfontdir)
rm -rf ./pcf
cp ./prf/* ./lib/user/
rm -rf ./prf

echo '#!/bin/sh
MAIN_FONT="16x22tg"
SMALLER_FONT="8x13"
export TOMENET_X11_FONT=${MAIN_FONT}
export TOMENET_X11_FONT_MIRROR=${SMALLER_FONT}
export TOMENET_X11_FONT_RECALL=${SMALLER_FONT}
export TOMENET_X11_FONT_CHOICE=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_4=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_5=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_6=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_7=${SMALLER_FONT}
xset fp+ $(pwd)/fonts
xset fp rehash
./tomenet -p18348 -m europe.tomenet.eu
' > tomenet-tgfnt.sh
chmod +x tomenet-tgfnt.sh
echo "Complete!"
