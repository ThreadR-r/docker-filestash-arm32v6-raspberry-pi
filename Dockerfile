FROM arm32v6/alpine:latest
MAINTAINER threadrr@gmail.com
COPY qemu-arm-static /usr/bin/

ENV GOPATH /tmp/go
ENV CGO_LDFLAGS_ALLOW '-fopenmp'

RUN mkdir -p $GOPATH/src/github.com/mickael-kerjean/ && \
    #################
    # Dependencies
    apk --no-cache --virtual .build-deps add make gcc g++ curl nodejs git npm python && \
    apk  --no-cache --virtual .go add go --repository http://dl-3.alpinelinux.org/alpine/edge/community && \
    mkdir /tmp/deps && \
    cd /tmp/deps && \
    # libvips #######
    #cd /tmp/deps && \
    #curl -L -X GET https://github.com/libvips/libvips/releases/download/v8.9.1/vips-8.9.1.tar.gz > libvips.tar.gz && \
    #tar -zxf libvips.tar.gz && \
    #cd vips-8.9.1/ && \
    #apk --no-cache add libexif-dev tiff-dev jpeg-dev libjpeg-turbo-dev libpng-dev librsvg-dev giflib-dev glib-dev fftw-dev glib-dev libc-dev expat-dev orc-dev && \
    #./configure && \
    #make -j 6 && \
    #make install && \
    apk --no-cache add vips && \
    # libraw ########
    #cd /tmp/deps && \
    #curl -X GET https://www.libraw.org/data/LibRaw-0.19.5.tar.gz > libraw.tar.gz && \
    #tar -zxf libraw.tar.gz && \
    #cd LibRaw-0.19.5/ && \
    #./configure && \
    #make -j 6 && \
    #make install && \
    apk --no-cache add libraw && \
    #################
    # Prepare Build
    cd $GOPATH/src/github.com/mickael-kerjean && \
    git clone --depth 1 https://github.com/mickael-kerjean/filestash && \
    cd filestash && \
    mkdir -p ./dist/data/ && \
    mv config ./dist/data/ && \
    #################
    # Compile Frontend
    npm install && \
    npm rebuild node-sass && \
    NODE_ENV=production npm run build && \
    #################
    # Compile Backend
    cd $GOPATH/src/github.com/mickael-kerjean/filestash/server && go get && cd ../ && \
    go build -ldflags "-X github.com/mickael-kerjean/filestash/server/common.BUILD_NUMBER=`date -u +%Y%m%d`" -o ./dist/filestash ./server/main.go && \
    #################
    # Compile Plugins
    mkdir -p ./dist/data/plugin && \
    go build -buildmode=plugin -o ./dist/data/plugin/image.so server/plugin/plg_image_light/index.go && \
    #################
    # External dependencies: emacs and pdflatex
    apk --no-cache add curl emacs texlive zip && \
    curl https://raw.githubusercontent.com/mickael-kerjean/filestash_latex/master/wrapfig.sty > /usr/share/texmf-dist/tex/latex/base/wrapfig.sty && \
    curl https://raw.githubusercontent.com/mickael-kerjean/filestash_latex/master/capt-of.sty > /usr/share/texmf-dist/tex/latex/base/capt-of.sty && \
    curl https://raw.githubusercontent.com/mickael-kerjean/filestash_latex/master/sectsty.sty > /usr/share/texmf-dist/tex/latex/base/sectsty.sty && \
    texhash && \
    apk --no-cache del curl && \
    # put emacs on a diet program
    find /usr/share/emacs -name '*.pbm' | xargs rm && \
    find /usr/share/emacs -name '*.png' | xargs rm && \
    find /usr/share/emacs -name '*.xpm' | xargs rm && \
    # put latex on a diet program
    rm -rf /usr/share/texmf-dist/doc && \
    #################
    # Finalise the build
    cd $GOPATH/src/github.com/mickael-kerjean/filestash/ && \
    apk --no-cache add ca-certificates && \
    mv dist /app && \
    cd /app && \
    rm -rf $GOPATH && \
    rm -rf /tmp/* && \
    apk del .build-deps && \
    apk del .go && \
    #################
    # Create machine user
    addgroup -S filestash && adduser -S -g filestash filestash && \
    chown -R filestash:filestash /app/ && \
    chown filestash:filestash /app/data/config/config.json

EXPOSE 8334
VOLUME ["/app/data/config/"]
WORKDIR "/app"
USER filestash
CMD ["/app/filestash"]
