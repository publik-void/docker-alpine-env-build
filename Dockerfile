# vim: foldmethod=marker

FROM alpine:3.18.3
EXPOSE 22

# Remember:
# * Comments in Dockerfile need `#` at the *beginning* of the line.
# * Shell commands under RUN can have indented comments.
# * Adding a backslash after such comments helps the syntax highlighting in my
#   Neovim setup, for whatever reason.

# Regarding the splitting or joining of RUN commands:
# https://stackoverflow.com/questions/39223249/multiple-run-vs-single-chained-
# run-in-dockerfile-which-is-better

# {{{1 Foundational packages
RUN cd /root/ && apk update
RUN cd /root/ && \
  apk add \
    mandoc man-pages mandoc-apropos mandoc-doc busybox-doc less-doc tar-doc \
      wget-doc grep-doc sudo-doc \
    # TODO: Haven't found out yet how to install man pages for a bunch of \
    # utilities such as `seq`, `base64`, `tr`, `uniq`, … \
    tzdata tzdata-doc \
    openssh openssh-doc \
    curl curl-doc \
    git git-doc \
    # NOTE: `ncurses` is for coloring in terminals like `screen*` and `tmux*` \
    ncurses ncurses-doc \
    botan botan-doc \
    parallel parallel-doc \
    # NOTE: Using LibreSSL here. \
    #openssl openssl-doc \
    libressl libressl-doc \
    xz xz-doc \
    lz4 lz4-doc

# {{{1 Perl
# Because many packages and programs tend to depend on it
RUN cd /root/ && \
  apk add perl perl-doc

# {{{1 CXX/low-level compilation and numerical computing environment
RUN cd /root/ && \
  apk add \
    gfortran \
    # NOTE: `lapack` and `lapack-dev` are needed for e.g. `scipy`. \
    # …at least when building the wheel from source. \
    # But `lapack` seems to break `liblapack`, which is required by \
    # `openblas-dev`. \
    # lapack lapack-dev \
    openblas openblas-dev openblas-doc \
    libstdc++ \
    libc-dev \
    musl-dev \
    libc6-compat gcompat \
    # NOTE: `clang` and subpackages are unavailable as of 2023-08-30 \
    #clang clang-dev clang-doc lld lld-doc \
    gcc g++ gcc-doc gdb gdb-doc \
    make make-doc \
    # NOTE: `ninja` is unavailable as of 2023-08-30 \
    # …samurai may be an alternative. \
    #ninja ninja-doc ninja-bash-completion \
    cmake cmake-doc \
    boost-dev boost-doc

# TODO: Previously, I did this:
# `ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2`
# This command produces an error now and I haven't looked into fixing it yet

# {{{1 My interactive "userland"
RUN cd /root/ && \
  apk add \
    mosh mosh-doc \
    fish fish-doc fish-tools \
    tmux tmux-doc \
    neovim neovim-doc \
    ranger ranger-doc \
    viu viu-doc \
    \
    # Things needed for Neovim: \
    # NOTE: `efm-langserver` exists on Alpine `edge`, but not 3.18…
    shellcheck shellcheck-doc \
    flake8 \
    ripgrep ripgrep-doc ripgrep-fish-completion \
    fd fd-doc fd-fish-completion

# {{{1 Working with written documents
RUN cd /root/ && \
  # NOTE: As of 2023-08-30, no `tectonic-doc` exists.
  apk add tectonic pandoc-cli asciidoctor

# {{{1 Python
RUN cd /root/ && \
  # NOTE: Not self-upgrading Pip, to maximize compatibility with Alpine/`apk` \
  # NOTE: Python modules could also be installed via Pip and an index of \
  # wheels built for Alpine, such as `https://alpine-wheels.github.io/index`, \
  # but since there are `apk` packages for the Python modules I need, I'll \
  # stick to those. \
  apk add python3 python3-doc python3-dev \
    py3-pip py3-pip-doc \
    poetry \
    py3-watchdog py3-pynvim \
    py3-numpy py3-scipy

# {{{1 Julia
RUN cd /root/ && \
  # NOTE: At the time of writing (2022-02-03), there's no Julia package for \
  # Alpine. Hence, we're installing the `musl` Binary manually. This is not \
  # uncommon, since other distros do not necessarily have up-to-date Julia \
  # packages either. \
  # NOTE: I'm writing this one on 2023-05-09. Don't know if I'll grow fond of \
  # JuliaUp in the future but at the moment, it seems to not be compatible \
  # with Alpine. The above note is still true. \
  JULIA_MAJOR_VERSION_NUMBER="1" && \
  JULIA_MINOR_VERSION_NUMBER="9" && \
  JULIA_PATCH_VERSION_NUMBER="0" && \
  JULIA_MAJOR_VERSION="$JULIA_MAJOR_VERSION_NUMBER" && \
  JULIA_MINOR_VERSION="$JULIA_MAJOR_VERSION.$JULIA_MINOR_VERSION_NUMBER" && \
  JULIA_PATCH_VERSION="$JULIA_MINOR_VERSION.$JULIA_PATCH_VERSION_NUMBER" && \
  wget -O /opt/julia.tar.gz \
    https://julialang-s3.julialang.org/bin/musl/x64/$JULIA_MINOR_VERSION/julia-$JULIA_PATCH_VERSION-musl-x86_64.tar.gz && \
  gunzip /opt/julia.tar.gz && \
  tar -C /opt/ -xf /opt/julia.tar && \
  rm /opt/julia.tar && \
  ln -s /opt/julia-$JULIA_PATCH_VERSION/bin/julia /usr/bin/julia

# {{{1 Julia packages
RUN cd /root/ && \
  julia -e 'import Pkg; Pkg.add([ \
    \
    "FileIO", \
    "Match", \
    "Memoization", \
    "LoopVectorization", \
    "PyCall", \
    \
    "IntervalSets", \
    "LinearMaps", \
    "FixedPointNumbers", \
    "MultiFloats", \
    \
    "StructArrays", \
    "PooledArrays", \
    "Dictionaries", \
    "DataStructures", \
    \
    "Tables", \
    "TypedTables", \
    "DataFrames", \
    "SplitApplyCombine", \
    \
    "StatsBase", \
    "Statistics", \
    "HypothesisTests", \
    "DSP", \
    "AbstractFFTs", \
    "FFTW", \
    \
    "Colors", \
    "Images", \
    "Measures", \
    "Compose", \
    "Gadfly", \
    \
    "IterativeSolvers", \
    "Optim", \
    \
    "JLD2", \
    "CodecZlib", \
    "JSON", \
    "JSON3", \
  ])'

# {{{1 Miscellaneous setup
RUN cd /root/ && \
  echo "root:root" | chpasswd && \
  mkdir -p /root/bin && \
  ln -s /usr/share/zoneinfo/CET /etc/localtime && \
  rm /etc/motd && \
  mkdir /root/.ssh && chmod 700 /root/.ssh && \
  # `ssh-keygen -A` creates host keys in `/etc/ssh`, needed for authentication \
  ssh-keygen -A && \
  sed -i 's/\/bin\/ash/\/usr\/bin\/fish/g' /etc/passwd && \
  mkdir /root/.parallel && touch /root/.parallel/will-cite && \
  printf "\n# %s\n%s" \
    "If the client sends its terminal's color capability, accept it" \
    "AcceptEnv COLORTERM" >> /etc/ssh/sshd_config && \
  ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

COPY authorized_keys /root/.ssh/
# NOTE: `id_rsa` is not included in the git repo, for obvious reasons
COPY id_rsa /root/.ssh/
COPY id_rsa.pub /root/.ssh/

COPY motd /etc/motd

COPY .gitconfig /root/

# {{{1 CPCP, Neovim, Tmux and Fish setup
RUN cd /root/ && \
  mkdir -p /root/.config && \
  git clone git@github.com:publik-void/cross-platform-copy-paste.git \
    /root/.config/cross-platform-copy-paste && \
  ln -s /root/.config/cross-platform-copy-paste/cpcp.sh /root/bin/cpcp && \
  git clone git@github.com:publik-void/config-fish.git /root/.config/fish && \
  git clone git@github.com:publik-void/config-nvim.git /root/.config/nvim && \
  git clone git@github.com:publik-void/config-tmux.git /root/.config/tmux

# {{{1 Mosh, from source
# NOTE: I disabled (commented out) this section, because as of the time of
# writing this (2023-05-09), it seems there is a new version of mosh and it's
# available in Alpine 3.17. Hooray!
  # NOTE: I'm building from source to get the latest version. I did this in the
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
#RUN cd /root/ && \
#  apk add perl \
#    ncurses-dev \
#    libprotobuf \
#    openssh \
#    libutempter-dev && \
#  # Build dependencies (yes, `perl-doc` is needed) \
#  apk add --no-cache --virtual .build-deps \
#    git \
#    make \
#    automake \
#    autoconf \
#    g++ \
#    lld \
#    protobuf-dev \
#    libutempter-dev \
#    ncurses-dev \
#    openssl1.1-compat-dev \
#    perl-doc && \
#  git clone https://github.com/mobile-shell/mosh.git /opt/mosh && \
#  sed -i '/unicode-later-combining.test/d' /opt/mosh/src/tests/Makefile.am && \
#  export CXXFLAGS="$CXXFLAGS -Wno-deprecated-declarations" && \
#  cd /opt/mosh && \
#  ./autogen.sh && \
#  ./configure \
#    --prefix=/usr \
#    --sysconfdir=/etc \
#    --mandir=/usr/share/man \
#    --localstatedir=/var \
#    --enable-compile-warnings=error \
#    --enable-examples && \
#  make && \
#  make install && \
#  cd /root/ && \
#  rm -rf /opt/mosh && \
#  apk del .build-deps

# {{{1 Setup steps which need to be done after the above
RUN cd /root/ && \
  git clone git@github.com:publik-void/home-network-host-list.git && \
  cd home-network-host-list && \
  ./update-etc-hosts.sh && \
  cd .. && \
  rm -r home-network-host-list && \
  # Start Neovim to let Lazy install the plugins and quit afterwards. \
  # Also, wait a bit to allow treesitter to install the default languages. \
  nvim -c "sleep 15 | qall" && \
  poetry completions fish > ~/.config/fish/completions/poetry.fish && \
  # NOTE: In the following, `fish` will warn that it is unable to get the \
  # manpath, and falls back to some defaults, including `/usr/share/man`, \
  # which I believe is correct. \
  fish -c fish_update_completions

WORKDIR /root

#ENTRYPOINT /usr/sbin/sshd;/usr/bin/fish
ENTRYPOINT /usr/sbin/sshd -D

