#!/usr/bin/env bash

# DONE
function setup_emacs {
  setup_emacs_build
  setup_emacs_clone
  setup_emacs_ensure_config
}

# DONE
function setup_emacs_test_config {
  emacs

}

# DONE
function setup_newer_emacs_build {
  if [[ -f "${HOME}/.emacs.d/current_commit" ]]; then
    local -r older_commit = "$(cat "${HOME}/.emacs.d/current_commit")"
  else
    echo "Emacs upgrade: Error! current_commit not found"
    echo "Emacs upgrade: exiting.."
    return 1
  fi

  if [[ -d "${GIT_DIR}/emacs" ]]; then
    echo "Newer Emacs: Already present. Pulling..."
    pushd "${GIT_DIR}/emacs"
    git stash -q
    git pull
  else
    pushd "${GIT_DIR}"
    git clone https://git.savannah.gnu.org/git/emacs.git emacs
    pushd "${GIT_DIR}/emacs"
  fi

  local -r newer_commit="$(git rev-parse HEAD)"
  git log --oneline "${older_commit}".."${newer_commit}"
  read -p "Want to proceed? [Y/N]: " answer
  if [[ "${answer}" =~ ".*Y.*" ]]; then
    echo "Emacs upgrade: proceeding..."
    configure_and_install_emacs "$(pwd)"
  else
    echo "Emacs upgrade: Bye bye..."
  fi
}

# DONE:
function configure_and_install_emacs {
  local -r directory="$1"
  pushd "${directory}"
  # Generate the configuration script using autoconf
  # 1. Macros processed by m4. Result passed to autoconf
  # 2. Configuration generated using autoconf
  # some useful info
  echo "Emacs: installing build dependencies..."
  ensure_packages gnutls-devel \
    ncurses-devel \
    texinfo \
    giflib-devel \
    libXpm-devel \
    libacl-devel \
    libattr-devel \
    libgccjit-devel \
    libtree-sitter-devel \
    jansson-devel

  local -r cur_commit="$(git rev-parse HEAD)"
  echo "Emacs: building emacs master from scratch..."
  ./autogen.sh &>/dev/null
  ./configure -q
  # These are so as to disable d-bus as we do not require them
  --without-gconf --without-gsettings \
    --with-mailutils \ # preinstalled, more secure
  --without-xinput2 \ # No touch-screens
  --without-sound
  # Cairo is a 2D graphics library, for SVGs and emoji's for example
  --with-cairo
  # For integration with various e.g. RhythmBox etc
  --with-dbus
  # Module support is required for vterm to work
  --with-modules \ # For vterm
  # Requires libgccjit-devel
  --with-native-compilation=aot \
    --with-tree-sitter \
    --with-json
  # calculate number of cores
  cores=$(ls /dev/cpu/ | wc -l)
  echo $cores
  make -s -j$cores install
  popd
  rm -rf emacs

  echo "Emacs Installing Zile..."
  ensure_packages zile
  echo "Emacs: Build done! Removing dependencies..."
  dnf remove -q -y nutls-devel ncurse ve-compilation libgccjit-devel libattr-devel libacl-devel libXpm-devel giflib-devel jansson-devel
  echo "${cur_commit}" >"${HOME}/.emacs.d/current_commit"

  echo "Emacs: removing development dependencies..."
  dnf remove -y gnutls-devel \
    ncurses-devel \
    texinfo \
    giflib-devel \
    libXpm-devel \
    libacl-devel \
    libattr-devel \
    libgccjit-devel \
    libtree-sitter-devel \
    jansson-devel
}

# DONE
function setup_pdf_tools {
  echo "Emacs: setup 'pdf-tools'..."
  pushd ${BASE_CLONE_DIR}
  git clone -q https://github.com/vedang/pdf-tools
  pushd pdf-tools
  make -s
  # epdfinfo done, now just copy over lisp and executable
  mv lisp/* "${HOME}/.emacs.d/packages/other/pdf-tools/"
  mv server/epdfinfo "${HOME}/.local/bin"
  chmod +x "${HOME}/.local/bin"
}

# DONE
function setup_emacs_build {
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://git.savannah.gnu.org/git/emacs.git
  pushd emacs
  configure_and_install_emacs .
}

# TODO: complete and test
function setup_emacs_clone {

  local OPTIND=
  local git_url="$1"
  local do_backup=
  ensure_gh_authentication
  while getopts "db" opt; do
    case "${opt}" in
    d) git_url="git@github.com:strangepr0gram/emacs.git" ;;
    b) do_backup=true ;;
    esac
  done
  OPTIND=$((OPTIND - 1))
  OPTIND=0

  if ! [[ "${git_url}" ]]; then
    echo "Emacs: No URL supplied. Please supply a URL when running this. Bye!"

  fi

  if [[ "${do_backup}" ]]; then
    backup_directory="$(setup_emacs_main_dir)"
    echo "Emacs: backing up Emacs directory..."
    tar cf "${HOME}/emacs-backup-$(date +"%Y-%m-%d-%H-%M-%S")" "${backup_directory}" &>/dev/null
    echo "Emacs: backup done."
  fi
  git clone -q "${git_url}" "${backup_directory}"
}

# TODO: complete and test
function setup_emacs_main_dir {
  # We can reasonably assume that the one with the most lines is
  # the only one we care about
  relevant_emacs_file="$(find "${HOME}/.emacs" \
    "${HOME}/.emacs.d/init.el" \
    "${HOME}/.config/emacs/init.el" -type f \
    -exec \
    wc -l '{}' \; | sort -rnk 1 | head -1 | cut -d' ' -f2)"
  dirname "${relevant_emacs_file}"
}

function setup_eww_history_ext {
  after cargo
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://github.com/1History/eww-history-ext
  echo "Setting up shared object for 'eww-history-ext'..."
  pushd eww-history-ext
  make dev # release has issues
  mv target/debug/libeww_history_ext.so ${HOME}/.emacs.d/lib/others/
  pushd
  rm -rf eww-history-ext
}
