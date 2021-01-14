FROM innovanon/xorg-base:latest as builder-01
USER root
COPY --from=innovanon/util-macros /tmp/util-macros.txz /tmp/
COPY --from=innovanon/xorgproto   /tmp/xorgproto.txz   /tmp/
COPY --from=innovanon/libxau      /tmp/libXau.txz      /tmp/
COPY --from=innovanon/libxdmcp    /tmp/libXdmcp.txz    /tmp/
COPY --from=innovanon/xcb-proto   /tmp/xcbproto.txz    /tmp/
COPY --from=innovanon/libxcb      /tmp/libxcb.txz      /tmp/
COPY --from=innovanon/freetype    /tmp/freetype2.txz   /tmp/
COPY --from=innovanon/fontconfig  /tmp/fontconfig.txz  /tmp/
COPY ./build.sh /usr/local/bin/
RUN command -v build.sh \
 && extract.sh

FROM builder-01 as xtrans
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libxtrans.git

FROM builder-01 as libX11
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libX11.git

FROM builder-01 as libXext
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
COPY --from=libX11                /tmp/libX11.txz      /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXext.git

FROM builder-01 as libFS
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
COPY --from=libX11                /tmp/libX11.txz      /tmp/
COPY --from=libXext               /tmp/libXext.txz     /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libFS.git

FROM builder-01 as libICE
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
COPY --from=libX11                /tmp/libX11.txz      /tmp/
COPY --from=libXext               /tmp/libXext.txz     /tmp/
COPY --from=libFS                 /tmp/libFS.txz       /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN sleep 31                                                                              \
 && git clone --depth=1 --recursive https://gitlab.freedesktop.org/xorg/lib/libICE.git    \
 && cd                                                                      libICE        \
 && ./autogen.sh                                                                          \
 && ./configure $XORG_CONFIG ICE_LIBS=-lpthread                                           \
 && make                                                                                  \
 && make DESTDIR=/tmp/libICE install                                                      \
 && rm -rf                                                                  libICE        \
 && cd           /tmp/libICE                                                              \
 && strip.sh .                                                                            \
 && tar  pacf        ../libICE.txz .                                                        \
 && cd ..                                                                                 \
 && rm -rf       /tmp/libICE

FROM builder-01 as libSM
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
COPY --from=libX11                /tmp/libX11.txz      /tmp/
COPY --from=libXext               /tmp/libXext.txz     /tmp/
COPY --from=libFS                 /tmp/libFS.txz       /tmp/
COPY --from=libICE                /tmp/libICE.txz      /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libSM.git

FROM builder-01 as libXScrnSaver
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
COPY --from=libX11                /tmp/libX11.txz      /tmp/
COPY --from=libXext               /tmp/libXext.txz     /tmp/
COPY --from=libFS                 /tmp/libFS.txz       /tmp/
COPY --from=libICE                /tmp/libICE.txz      /tmp/
COPY --from=libSM                 /tmp/libSM.txz       /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXScrnSaver.git

FROM builder-01 as libXt
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN sleep 31                                                                                  \
 && git clone --depth=1 --recursive https://gitlab.freedesktop.org/xorg/lib/libXt.git         \
 && cd                                                                      libXt             \
 && ./autogen.sh                                                                              \
 && ./configure $XORG_CONFIG --with-appdefaultdir=$XORG_PREFIX/etc/X11/app-defaults           \
 && make                                                                                      \
 && make DESTDIR=/tmp/libXt install                                                           \
 && rm -rf                                                                  libXt             \
 && cd           /tmp/libXt                                                                   \
 && strip.sh .                                                                                \
 && tar  pacf        ../libXt.txz .                                                             \
 && cd ..                                                                                     \
 && rm -rf       /tmp/libXt

FROM builder-01 as libXmu
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXmu.git

FROM builder-01 as libXpm
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXpm.git

FROM builder-01 as libXaw
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXaw.git

FROM builder-01 as libXfixes
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXfixes.git

FROM builder-01 as libXcomposite
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXcomposite.git

FROM builder-01 as libXrender
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXrender.git

FROM builder-01 as libXcursor
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXcursor.git

FROM builder-01 as libXdamage
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXdamage.git

FROM builder-01 as libfontenc
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libfontenc.git

FROM builder-01 as libXfont2
COPY --from=xtrans                /tmp/libxtrans.txz   /tmp/
COPY --from=libX11                /tmp/libX11.txz      /tmp/
COPY --from=libXext               /tmp/libXext.txz     /tmp/
COPY --from=libFS                 /tmp/libFS.txz       /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN sleep 31                                                                              \
 && git clone --depth=1 --recursive https://gitlab.freedesktop.org/xorg/lib/libXfont2.git \
 && cd                                                                      libXfont2     \
 && ./autogen.sh                                                                          \
 && ./configure $XORG_CONFIG --disable-devel-docs                                         \
 && make                                                                                  \
 && make DESTDIR=/tmp/libXfont2 install                                                   \
 && rm -rf                                                                  libXfont2     \
 && cd           /tmp/libXfont2                                                           \
 && strip.sh .                                                                            \
 && tar  pacf        ../libXfont2.txz .                                                     \
 && cd ..                                                                                 \
 && rm -rf       /tmp/libXfont2

FROM builder-01 as libXft
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXft.git

FROM builder-01 as libXi
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXi.git

FROM builder-01 as libXinerama
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXinerama.git

FROM builder-01 as libXrandr
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXrandr.git

FROM builder-01 as libXres
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXres.git

FROM builder-01 as libXtst
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXtst.git

FROM builder-01 as libXv
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXv.git

FROM builder-01 as libXvMC
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXvMC.git

FROM builder-01 as libXxf86dga
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXxf86dga.git

FROM builder-01 as libXxf86vm
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
COPY --from=libXxf86dga           /tmp/libXxf86dga.txz   /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libXxf86vm.git

FROM builder-01 as libdmx
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
COPY --from=libXxf86dga           /tmp/libXxf86dga.txz   /tmp/
COPY --from=libXxf86vm            /tmp/libXxf86vm.txz    /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libdmx.git

FROM builder-01 as libpciaccess
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
COPY --from=libXxf86dga           /tmp/libXxf86dga.txz   /tmp/
COPY --from=libXxf86vm            /tmp/libXxf86vm.txz    /tmp/
COPY --from=libdmx                /tmp/libdmx.txz        /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libpciaccess.git

FROM builder-01 as libxkbfile
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
COPY --from=libXxf86dga           /tmp/libXxf86dga.txz   /tmp/
COPY --from=libXxf86vm            /tmp/libXxf86vm.txz    /tmp/
COPY --from=libdmx                /tmp/libdmx.txz        /tmp/
COPY --from=libpciaccess          /tmp/libpciaccess.txz  /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libxkbfile.git

FROM builder-01 as libxshmfence
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
COPY --from=libXxf86dga           /tmp/libXxf86dga.txz   /tmp/
COPY --from=libXxf86vm            /tmp/libXxf86vm.txz    /tmp/
COPY --from=libdmx                /tmp/libdmx.txz        /tmp/
COPY --from=libpciaccess          /tmp/libpciaccess.txz  /tmp/
COPY --from=libxkbfile            /tmp/libxkbfile.txz    /tmp/
RUN extract.sh
ARG LFS=/mnt/lfs
WORKDIR $LFS/sources
USER lfs
RUN build.sh https://gitlab.freedesktop.org/xorg/lib/libxshmfence.git

FROM scratch as final
COPY --from=xtrans                /tmp/libxtrans.txz     /tmp/
COPY --from=libX11                /tmp/libX11.txz        /tmp/
COPY --from=libXext               /tmp/libXext.txz       /tmp/
COPY --from=libFS                 /tmp/libFS.txz         /tmp/
COPY --from=libICE                /tmp/libICE.txz        /tmp/
COPY --from=libSM                 /tmp/libSM.txz         /tmp/
COPY --from=libXScrnSaver         /tmp/libXScrnSaver.txz /tmp/
COPY --from=libXt                 /tmp/libXt.txz         /tmp/
COPY --from=libXmu                /tmp/libXmu.txz        /tmp/
COPY --from=libXpm                /tmp/libXpm.txz        /tmp/
COPY --from=libXaw                /tmp/libXaw.txz        /tmp/
COPY --from=libXfixes             /tmp/libXfixes.txz     /tmp/
COPY --from=libXcomposite         /tmp/libXcomposite.txz /tmp/
COPY --from=libXrender            /tmp/libXrender.txz    /tmp/
COPY --from=libXcursor            /tmp/libXcursor.txz    /tmp/
COPY --from=libXdamage            /tmp/libXdamage.txz    /tmp/
COPY --from=libfontenc            /tmp/libfontenc.txz    /tmp/
COPY --from=libXfont2             /tmp/libXfont2.txz     /tmp/
COPY --from=libXft                /tmp/libXft.txz        /tmp/
COPY --from=libXi                 /tmp/libXi.txz         /tmp/
COPY --from=libXinerama           /tmp/libXinerama.txz   /tmp/
COPY --from=libXrandr             /tmp/libXrandr.txz     /tmp/
COPY --from=libXres               /tmp/libXres.txz       /tmp/
COPY --from=libXtst               /tmp/libXtst.txz       /tmp/
COPY --from=libXv                 /tmp/libXv.txz         /tmp/
COPY --from=libXvMC               /tmp/libXvMC.txz       /tmp/
COPY --from=libXxf86dga           /tmp/libXxf86dga.txz   /tmp/
COPY --from=libXxf86vm            /tmp/libXxf86vm.txz    /tmp/
COPY --from=libdmx                /tmp/libdmx.txz        /tmp/
COPY --from=libpciaccess          /tmp/libpciaccess.txz  /tmp/
COPY --from=libxkbfile            /tmp/libxkbfile.txz    /tmp/
COPY --from=libxshmfence          /tmp/libxshmfence.txz  /tmp/

