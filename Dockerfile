FROM alpine:3.15.0
EXPOSE 22
# Remember: Comments in Dockerfile need `#` at the *beginning* of the line
RUN cd /root/ && apk update && \

  # -> General environment setup
  # Packages
  apk add mandoc man-pages mandoc-apropos less-doc tar-doc wget-doc \
    tzdata tzdata-doc \
    openssh openssh-doc \
    # Note: Building `mosh` from source instead, see below
    #mosh mosh-doc \
    curl curl-doc \
    git git-doc \
    fish fish-doc fish-tools \
    tmux tmux-doc \
    # Note: `ncurses` is for coloring in terminals like `screen*` and `tmux*`
    ncurses ncurses-doc \
    neovim neovim-doc \
    ranger ranger-doc \
    botan botan-doc \
    parallel parallel-doc \
    # Note: Using LibreSSL here.
    #openssl openssl-doc \
    libressl libressl-doc \
    xz xz-doc \
    lz4 lz4-doc \

  # Miscellaneous setup
  echo "root:root" | chpasswd && \
  ln -s /usr/share/zoneinfo/CET /etc/localtime && \
  rm /etc/motd && \
  mkdir /root/.ssh && chmod 700 /root/.ssh && \
  # TODO: `ssh-keygen -A` creates host keys in `/etc/ssh` – do I need that?
  ssh-keygen -A && \
  sed -i 's/\/bin\/ash/\/usr\/bin\/fish/g' /etc/passwd && \
  mkdir /root/.parallel && touch /root/.parallel/will-cite && \
  ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 && \

  # Git setup
  git config --global user.name "lasse" && \
  git config --global user.email "lasse-schloer@servermx.de" && \
  # Note: I have trouble getting a git credential helper to tun on Alpine. The
  # `cache` mode at least allows to remember passwords for a short time.
  git config --global credential.helper cache && \

  # Neovim, Tmux and Fish setup
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
  mkdir -p /root/.config && \
  git clone https://github.com/publik-void/config-fish.git \
    /root/.config/fish && \
  git clone https://github.com/publik-void/config-nvim.git \
    /root/.config/nvim && \
  git clone https://github.com/publik-void/config-tmux.git \
    /root/.config/tmux && \
  ln -s /root/.config/tmux/tmux.conf /root/.tmux.conf && \

  # -> Perl, because many packages and programs tend to depend on it
  apk add perl perl-doc && \

  # -> CXX/low-level compilation and numerical computing environment, partly
  # needed for YouCompleteMe and others
  apk add gfortran && \
  # Note: `lapack` and `lapack-dev` are needed for e.g. `scipy`.
  apk add lapack lapack-dev && \
  apk add libstdc++ && \
  apk add libc-dev && \
  apk add musl-dev && \
  apk add libc6-compat gcompat && \
  apk add clang clang-dev clang-doc && \
  apk add gcc g++ gcc-doc && \
  apk add lld && \
  apk add make make-doc && \
    # Note: Ninja does not exist for Alpine 3.15.0 at the moment
    # …Samurai may be an alternative
  #apk add ninja ninja-doc ninja-bash-completion && \
  apk add cmake cmake-doc && \
  apk add boost-dev boost-doc && \

  # -> Python, needed for YouCompleteMe in (and as provider for) Neovim
  apk add python3 python3-doc python3-dev \
    py3-pip py3-pip-doc && \
  pip3 install --upgrade pip && \
  python3 -m pip install pynvim watchdog && \

  # -> Python modules
  python3 -m pip install \
    numpy \
    scipy \
    mne \
    BCI2kReader && \

  # -> Julia
  # Note: At the time of writing (2022-02-03), there's no Julia package for
  # Alpine. Hence, we're installing the `musl` Binary manually. This is not
  # uncommon, since other distros do not necessarily have up-to-date Julia
  # packages either.
  wget -O /opt/julia.tar.gz \
    https://julialang-s3.julialang.org/bin/musl/x64/1.7/julia-1.7.1-musl-x86_64.tar.gz && \
  gunzip /opt/julia.tar.gz && \
  tar -C /opt/ -xf /opt/julia.tar && \
  rm /opt/julia.tar && \
  ln -s /opt/julia-1.7.1/bin/julia /usr/bin/julia && \

  # -> Julia packages
  julia -e 'using Pkg; Pkg.add([' \
  '"Memoization", ' \
  '"ThreadSafeDicts", ' \
  '"OrderedCollections", ' \
  '"StatsBase", ' \
  '"Statistics", ' \
  '"PyCall", ' \
  '"DSP", ' \
  '"LinearMaps", \
  '"IterativeSolvers", ' \
  '"HypothesisTests", ' \
  '"IntervalSets", ' \
  '"JLD2", ' \
  '"DataFrames", ' \
  '"StructArrays", ' \
  '"LazyArrays", ' \
  '"Optim", ' \
  '"LoopVectorization", ' \
  '"AbstractFFTs", ' \
  '"FFTW", ' \
  '"JSON", ' \
  '"JSON3"])' && \

  # -> Mosh
  # Note: I'm building from source to get the latest version. I did this in the
  # hope that it would enable some features not included in the latest release
  # (which is `mosh` 1.3.2 from 2017 at the time of writing this, 2022-02-03).
  # There may e.g. be better color support. However, at least without additional
  # help, this version of `mosh` still lacks the following functionality for me:
  # * Cursor shape changing in Neovim
  # * Copy-to-clipboard from `tmux` inside `mosh`
  # This fork proposes a fix for the cursor shape issue (open pull request):
  # `https://github.com/matheusfillipe/mosh.git`
  # However, this doesn't seem to work for me. Perhaps because my `mosh-client`
  # isn't built from that fork.
  # So I guess we're still waiting for `mosh` to catch up…
  #
  # Inspired by the Alpine `mosh` package at:
  # `https://git.alpinelinux.org/aports/tree/main/mosh/APKBUILD`
  #
  # Run dependencies (some of these may already be installed)
  apk add perl \
    ncurses-dev \
    libprotobuf \
    openssh \
    libutempter-dev && \
  # Build dependencies (yes, `perl-doc` is needed)
  apk add --no-cache --virtual .build-deps \
    git \
    make \
    automake \
    autoconf \
    g++ \
    lld \
    protobuf-dev \
    libutempter-dev \
    ncurses-dev \
    openssl1.1-compat-dev \
    perl-doc && \
  git clone https://github.com/mobile-shell/mosh.git /opt/mosh && \
  sed -i '/unicode-later-combining.test/d' /opt/mosh/src/tests/Makefile.am && \
  export CXXFLAGS="$CXXFLAGS -Wno-deprecated-declarations" && \
  cd /opt/mosh && \
  ./autogen.sh && \
  ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --localstatedir=/var \
    --enable-compile-warnings=error \
    --enable-examples && \
  make && \
  make install && \
  cd /root/ && \
  rm -rf /opt/mosh && \
  apk del .build-deps && \

  # -> Setup steps which need to be done after the above
  # TODO: Doing `PlugInstall` like this crashes at the moment.
  #echo "Running PlugInstall for vim-plug…" && \
  #nvim -c PlugInstall -c qall && \
  fish -c fish_update_completions

COPY authorized_keys /root/.ssh/
# Note: `id_rsa` is not included in the git repo for obvious reasons
COPY id_rsa /root/.ssh/
COPY id_rsa.pub /root/.ssh/

COPY motd /etc/motd

WORKDIR /root

#ENTRYPOINT /usr/sbin/sshd;/usr/bin/fish
ENTRYPOINT /usr/sbin/sshd -D

