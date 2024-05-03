#!/usr/bin/env bash

BASE_SCRIPT_DIR="$(dirname "$_")"
BASE_CLONE_DIR="/tmp/"

source setup-emacs.sh

### VARS

declare -r STEPMANIA_SONG_DIRECTORY="${HOME}/.stepmania-5.1/Songs"

### --- UTILITIES

# TODO
function ensure_mount_point {
  until [[ $mount_point == "$(external_storage_mounted)" || "${answer}" != " " ]]; do
                                                                                                                                                                                                    echo "Mount point not found."
                                                                                                                                                                                                    echo "Please insert your setup external storage."
                                                                                                                                                                                                    read -p "Afterwards press Y to continue, or Q at any time to quit: " answer
  done
}


# DONE
function find_luks_partitions {
  porcpppplocal -r partitions=$(lsblk -l -o NAME | grep -q -v NAME)
  local -a luks_partitions=()
  for partition in $partitions; do
                                                                                                                                                                                                    if $(sudo cryptsetup isLuks /dev/"$partition" &>/dev/null); then
                                                                                                                                                                                                      luks_partitions+=("${partition}")
                                                                                                                                                                                                    fi
  done
  echo "LUKS: found luks partitions:"
  for partition in ${luks_partitions[@]}; do
                                                                                                                                                                                                    echo "$partition"
  done
}


# from https://github.com/hugot/bash-array-utils/
function Array::isValid {
  if ! declare -p "${1}" &>>/dev/null; then
    echo 'Array: Array variable needs to be set.' >&2
    return 1
  elif [[ ${1} == array ]]; then
    echo 'Array: Array variable can not be named "array"' >&2
    return 2
  fi
}

function Array::hasValue {
  if ! Array::isValid "${1}"; then
    echo "$(caller): ${1} is not a valid array."
    return 1
  fi
  declare -n array="${1}"
  if [[ ${2} == +([0-9]) ]]; then
    for item in "${array[@]}"; do
                                                                                                                                                                                                      [[ ${2} -eq $item ]] && return 0
    done
  else
    for item in "${array[@]}"; do
                                                                                                                                                                                                      [[ "${2}" == "$item" ]] && return 0
    done
  fi
  return 1
}

### my utilities

# for some simple dependency management
# TODO: test

function call_setup_function {
  # Call 'func'. If succeeded, append to 'array_var'.
  local -r func="${1}";
  shift
  local -r array_var="${1}";
  shift
  local -a args="$@";
  "${func}" "${args}" # call func with args
  # assuming success (otherwise would exit)
  $array_var+="${func}"
  export $array_var
}

function after_setup {
  local -r feature="${1}";
  # Either successfully installed (function already called)
  Array::hasValue "$SUCCESSFULLY_SETUP" "setup_$feature" ||
    call_setup_function "setup_$feature" "$@" # or call it
}

# https://google.github.io/styleguide/shellguide.html

function err {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

# TODO:
function fetch {
  local url="${1}"
  local filename="${2}"
  local OPTIND=
  # TODO: from DOMAIN.TLD
  echo "Fetching ${filename}..."
  wget -q -O "${filename}" "${url}"
  while getopts "c" opt; do
                                                                                                                                                                                                    case "${opt}" in
                                                                                                                                                                                                      # translates to function (feature->function), just call all
                                                                                                                                                                                                      c) echo "Editing file ${filename}...";
                                                                                                                                                                                                         "${EDITOR}" "${filename}"
                                                                                                                                                                                                         ;;
                                                                                                                                                                                                      z) echo "Unzipping ${filename}...";
                                                                                                                                                                                                         tar xvf "${filename}" &>/dev/null
                                                                                                                                                                                                         ;;
                                                                                                                                                                                                    esac
  done
  OPTIND=$((OPTIND - 1))
  OPTIND=0
}

### main functionality
# TODO: test
function ensure_gh_authentication {
  ensure_packages gh jq
  # Let's setup GitHub as trusted
  # From https://github.blog/2023-03-23-we-updated-our-rsa-ssh-host-key/
  if ! [[ $(grep -q "github.com" ${HOME}/.ssh/known_hosts) ]]; then
    echo "GitHub: Adding GitHub as trusted host..."
    curl -sSL https://api.github.com/meta \
      | jq -r '.ssh_keys | .[]' \
      | sed -e 's/^/github.com /' \ >> "${HOME}/.ssh/known_hosts"
  else
    echo "GitHub: trusted host found. Not adding..."
  fi

  echo "GitHub: Logging in to GitHub..."
  gh auth login -p ssh -w # SSH, open in a web-browser
  echo "GitHub: Ensuring public key is setup to GitHub..."
  gh ssh-key add "${HOME}/.ssh/id_rsa.pub"
}

# DONE: test
# Ensure a remote bash script ${1} is installed from ${2}.
# Optional: pass -y to skip checking manually with $EDITOR.
function ensure_remote_bash {
  local -r executable_name="${1}";
  local -r url="${2}";
  while getopts "y" opt; do
                                                                                                                                                                                                    case "${opt}" in
                                                                                                                                                                                                      y) EDITOR="nil" ;;
                                                                                                                                                                                                      *) ;;
                                                                                                                                                                                                    esac
  done
  OPTIND=0
  if ! [[ "$(which ${executable_name})" ]]; then
    echo "${executable_name} not installed!"
    pushd "${BASE_CLONE_DIR}"
    echo "Fetching remote script ${executable_name}..."
    curl -O "${executable_name}.sh" -sSL "${url}"
    $EDITOR "${executable_name}.sh"
    read -p "Install? [Y/N]: " to_install
    if [[ "${to_install}" =~ ".*Y.*" ]]; then
      echo "Installing remote script..."
      # fresh
      bash "${executable_name}.sh"
      # move it to ~/.local/bin
      chmod 755 "${executable_name}.sh"
      chown "${ESER}":"${EUSER}" "${executable_name}.sh"
      mv "${executable_name}.sh" "${HOME}/.local/bin"
    fi
  fi
}

#
function ensure_packages {
  # TODO
  local -ar packages="$@"; # STUB
  for package in $packages; do
                                                                                                                                                                                                    if ! [[ "$(rpm --quiet -q "${package}")" ]]; then
                                                                                                                                                                                                      echo "${package} not installed!"
                                                                                                                                                                                                      echo "Installing ${package}..."
                                                                                                                                                                                                      dnf install -q -y "${package}"
                                                                                                                                                                                                    fi
  done
}

# TODO: test, expand?
function external_storage_mounted {
  local mount_point="$(lsblk -I 8 -o "MOUNTPOINTS" | tail -1)";
  if ! [[ ${mount_point} ]]; then # if no mount point
    err "External storage: no mount point"
    return 1;
  fi
  export "${mount_point}"
}


# ---

# TODO: parse from file
declare -Ar feature_to_function_hash=("node" "setup_node"
                                      "python" "setup_python"
                                      "ruby" "setup_ruby"
                                      "home_packages"
                                      "setup_home_packages"
                                      "jap" "setup_beets" "setup_fan"
                                      "standard_font" "setup_standard_font"
                                      "spamhaus" "setup_spamhaus"
                                      "firejail" "setup_firejail"
                                      "home_package" "setup_home_package"
                                      "unbound" "setup_unbound"
                                      "stepmania" "setup_stepmania")

declare -r EUSER=$(whoami)
declare -r HOME="/home/${EUSER}"

# TODO: when ending: finish features
function print_help {
  echo -e "Script v0.1.0!\n
-a: All features.
-f FEATURE[,FEATURE][,FEATURE]: some features.

Features available: python, ruby, jap, beets, fan, standard_font, "
  echo -e "spamhaus, firejail, home_packages, unbound, stepmania, node\n"
  echo -e "Enjoy!"
}

# TODO: test
function ensure_python_module {
  local -ar packages="$@"; # STUB
  for package in $packages; do

                                                                                                                                                                                                    if ! [[ "$(python3 -m pip --user TODO "${package}")" ]]; then
                                                                                                                                                                                                      echo "${package} python module not installed!"
                                                                                                                                                                                                      echo "Installing ${package}..."
                                                                                                                                                                                                      python3 -m pip -qqq --user install "${package}"
                                                                                                                                                                                                    fi
  done
}

# DONE
function ensure_packages {
  local -ar packages="$@"; # STUB
  for package in $packages; do
                                                                                                                                                                                                                                                                                                                                                                                                    if ! [[ "$(rpm --quiet -q "${package}")" ]]; then
                                                                                                                                                                                                                                                                                                                                                                                                      echo "${package} not installed!"
                                                                                                                                                                                                                                                                                                                                                                                                      echo "Installing ${package}..."
                                                                                                                                                                                                                                                                                                                                                                                                      dnf install -q -y "${package}"
                                                                                                                                                                                                                                                                                                                                                                                                    fi
  done
}

# TODO
function setup_swap_hibernation {

}

# DONE
function setup_redshift {
  # TODO: STUB
  ensure_packages redshift jq
  # Copy and start user service
  echo "Redshift: Starting user service..."
  cp "${mount_point}/redshift.service" "${HOME}/.config/systemd/user/redshift.service"
  systemctl -q enable --now "redshift.service"
  # Defaults are fine.
}

# think
function setup_home_packages {
  local -ar HOME_PACKAGES=(# media
                           "easyrpg-player"
                           "wine" "android-tools"
                           "nicotine+"
                           "flac"
                           "gimp"
                           "pdf2svg" # for emacs 'org-inline-pdf'
                           # TODO: sort. emacs dependencies
                           # nice to have
                           "gnome_tweaks"
                           "pandoc"
                           "unbound"
                           "cloc"
                           # essential
                           "docker"
                           "docker-compose"
                           "livecd-tools"
                           "blueman"
                           "rofi"
                           "ripgrep"
                           "pass"
                           "unrar"
                           "git-delta"
                           "hddtemp"
                           "gh"
                           "wireshark"
                           "strace"
                           "sensors"
                           "cronie"
                           # for latex
                           "texlive-xetex"
                           "texlive-collection-latexextra"
                           "texlive-collection-latexrecommended"
                           "certbot" "parallel" "redshift"
                           # entertainment
                           "dosbox"
                           "lame-libs"
                           # japanese
                           "fcitx5-mozc"
                           "fcitx5"
                           "fcitx5-qt" # support modules
                           "fcitx5-mozc"
                           "fcitx5-gtk2"
                           "fcitx5-gtk3"
                           "fcitx5-gtk4"
                           "fcitx5-autostart"
                           "google-noto-cjk-fonts"
                           "langpacks-core-font-ko"
                           # misc
                           "repo"
                           # for mpv
                           "openh264-devel")
  echo "Home: Updating first..."
  echo "Home: Installing parallel first for background jobs..."
  # TODO: parallel first to run rest
  dnf install -q -y "${PACKAGE}"
  echo "Home: Installing home packages..."
  for package in "${HOME_PACKAGES[*]}"; do
                                                                                                                                                                                                                                                                                                                                                                                                    dnf install -q -y "${PACKAGE}"
  done
}

# DONE
function setup_wine {
  ensure_packages wine wine.i686 winetricks 7z
  # install usual applications via wine_tricks
  # TODO: winetricks arch=32
  winetricks d3dx10 vcrun2003 vcrun2005 vcrun2008 vcrun2010 \
             vcrun2012 vcrun2013 vcrun2015 \
             dotnet35
  winetricks arch=32
  # dotnet45
}

# DONE:
function setup_dnf_gpg_check {
  echo "DNF GPG: setting up dnf GPG check.."
  sed -ie "s/^gpgcheck=True/#gpgcheck=True/g" /etc/dnf/dnf.conf
}

# DONE
function setup_beets_mp3val {
  pushd "${BASE_CLONE_DIR}"
  fetch mp3val.tar.gz "https://downloads.sourceforge.net/project/mp3val/mp3val/mp3val%200.1.8/mp3val-0.1.8-src.tar.gz"
  tar xvf mp3val.tar.gz &> /dev/null
  pushd mp3val &> /dev/null
  make -sf Makefile.linux # -s: quiet
  chown {$EUSER:$EUSER} mp3val
  mv mp3val "/home/${EUSER}/.local/bin/"
  popd
}

# DONE
function setup_beets {
  local -ar BEETS_PACKAGES=("beetcamp" "beets-check" "beets-copyartifacts3"
                            "python3-discogs-client"
                            "beautifulsoup4" "requests"
                            "git+https://github.com/steven-murray/beet-summarize.git"
                            "git+https://github.com/YetAnotherNerd/whatlastgenre@master"
                            "git+https://github.com/igordertigor/beets-usertag.git")
  echo "Beets: Installing beets and add-ons using pipx..."
  pipx install beets
  for package in ${BEETS_PACKAGES[*]}; do pipx inject beets "$package" &>/dev/null;
  done

  echo "Beets: Setting up 'mp3val' for checking MP3s..."
  setup_beets_mp3val
}

# DONE
function setup_standard_font {
  # font setup: victor mono
  if [[ "$(find ${HOME}/.local/share/fonts/ -name '*VictorMono')" ]]; then
    echo "Victor: Victor Mono font already setup. Exiting..."
    return 2
  fi
  pushd "${BASE_CLONE_DIR}"
  fetch VictorMonoAll.zip https://rubjo.github.io/victor-mono/VictorMonoAll.zip
  unzip -q VictorMono*
  mv * -t "${HOME}.local/share/fonts/"
  rm -rf VictorMono*
  fc-cache -r &>/dev/null
}


## some security measures
# DONE
function setup_spamhaus {
  if [[ grep -q 'spamhaus.sh' "/var/spool/crontab/${EUSER}"
                               && -x ${HOME}/.local/bin/spamhaus.sh ]]; then
    echo "Spamhaus: Spamhaus already setup. Exiting..."
    return 2
  fi

  # spamhaus + cronjob
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://github.com/cowgill/spamhaus

  pushd spamhaus
  chmod +x spamhaus.sh
  ./spamhaus.sh # TODO sudo
  mv spamhaus.sh "/usr/local/bin/spamhaus"
  chown root:root /usr/local/bin/spamhaus
  popd

  rm -rf spamhaus

  echo -e "# run the script every day at 3am\n\
  0 3 * * * /usr/local/bin//spamhaus.sh" \ >> \/etc/crontab
  echo "Spamhaus: Running spamhaus as admin"
  /usr/local/bin/spamhaus &> /dev/null
}

# DONE
function setup_firejail{
  ensure_packages firejail
  # firejail with some exceptions
  echo <<MPV
noblacklist /${MEDIA_PARTITION}
noblacklist {MUSIC}
MPV
  > /etc/firejail/mpv.local
  # setup profiles, sudo
  firecfg
}

# DONE
function setup_dns_with_dot { # dns
  echo <<DYN
  DNS=1.1.1.1
  DNSSEC=yes
  DNSOverTLS=yes
  Cache=yes
DYN
  >> /etc/systemd/resolved.conf
  systemctl -q restart systemd-resolved.service
}

# TODO: todo
function setup_stumpwm {
  # We fetch and compile from source.
  # Fedora package is broken and gives segmentation fault on launch.
  # The README of the official binary distro suggests I disable
  # exec-shield:
  #
  # Segfaults on Fedora
  #
  # Try disabling exec-shield. The easiest way is to use
  # setarch: "setarch i386 -R sbcl".
  #
  # This does not solve the issue however.
  # 1. setup sbcl
  setup_sbcl
  # 2. setup dependencies: quicklisp, clx, cl-ppcre, alexandria
  pushd "${BASE_CLONE_DIR}"
  wget -O quicklisp.lisp https://beta.quicklisp.org # TODO
  sbcl --load quicklisp.lisp

  if [[ -d ~/${HOME}/quicklisp/ ]]; then
    install_string="(quicklisp-quickstart:install)"
  else
    # TODO: align this!
    install_string='(load "~/quicklisp/setup.lisp")'
  fi

  sbcl --eval <<FORM
(progn (${install_string}
(ql:add-to-init-file)
(ql:quickload "clx")
(ql:quickload "cl-ppcre")
(ql:quickload "alexandria")))
FORM
  rm -rf quicklisp.lisp
  # 3. fetch stumpwm and build from source
  git clone -q https://github.com/stumpwm/stumpwm
  pushd stumpwm
  ./autogen.sh
  ./configure
  ./make # TODO: breaks here
  ./make install # /usr/local/bin/stumpwm
  cp $TODOSTUMPWMFILE /usr/share/xsessions/stumpwm.desktop
}

# TODO:
function setup_bash_unit {
  ensure_remote_bash bash_unit "https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh"
}


# note setup
# DONE

# --- front

if [[ $UID != 0 ]]; then
  echo "Please run this script with sudo."
  echo "sudo $0 $*"
  return 1
fi

declare -a SUCCESSFULLY_SETUP=()

function to_sort {
  # home-ish
  # webcam
  tee -a /etc/modules <<< "snd_usb_audio" # sudo
}

# NOTE: use this at the beginning!
function setup_github {
  ensure_packages git gh
  ensure_python_module pipx
  echo "GitHub: installing pass-git-helper..."
  pipx install pass-git-helper &> /dev/null
  # TODO: git-pass-mapping
  read -p "Use existing gitconfig? [Y/N]: " answer
  if [[ "${answer}" =~ ".*Y.*" ]]; then
    pushd "${BASE_CLONE_DIR}"
    echo "Pulling your publicly available gitconfig..."
    git clone -q "https://github.com/strangepr0gram/gitconfig" gitconfig
    cp gitconfig/.gitconfig "${HOME}/.gitconfig"
    rm -rf gitconfig*
    popd tmp
  fi
  read -p "Use existing key (off media)? [Y/N]: " answer
  if [[ "${answer}" =~ ".*Y.*" ]]; then
    echo "GitHub: Setting up GitHub with existing ssh_key..."
    if [[ ${external_storage_mounted} ]]; then
      cp "${mount_point}/.ssh/*" "${HOME}/.ssh/"
      gh auth login -w # TODO: trap point?
    else
      echo "GitHub: Not mounted..."
    fi
  else
    read -p "Generate a new key and use that? [Y/N]: " answer
    if [[ "${answer}" =~ ".*Y.*" ]]; then
      ssh-keygen
    fi
  fi
}

# # TODO: test
# function get_dot_entry {
#   local -r entry="$1"
#   local answer=
#   read -p "Copy from git or local? [Y/N]: " answer
#   if [[ "${answer}" == "=~ ".*it.*"" ]]; then
#     echo "Dot-files: Copying dotfiles from git..."
#     git clone -q "https://github.com/strangepr0gram/my_dots" "${copy_dest}"
# }


# # TODO
# function copy_my_dots_over {
#   local -r entry="$1"
#   local answer=
#   read -p "Copy from git or local? [Y/N]: " answer
#   if [[ "${answer}" == "=~ ".*it.*"" ]]; then
#     echo "Dot-files: Copying dotfiles from git..."
#     git clone -q "https://github.com/strangepr0gram/my_dots" "${BASE_CLONE_DIR}"
#   fi
# }

# DONE
function setup_gnome_shell_extensions {
  ensure_package yarn # need for last extension
  # DONE gnome switcher
  git clone -q "https://github.com/strangepr0gram/switcher" \
      "${HOME}/.local/share/gnome-shell/extensions/switcher@landau.fi"
  # DONE remove alt-tab delay
  git clone -q "https://github.com/bdaase/remove-alt-tab-delay" \
      "${HOME}/.local/share/gnome-shell/extensions/remove-alt-tab-delay@daase.net"
  # DONE simple-system-monitor
  pushd "${BASE_CLONE_DIR}"
  git clone -q "https://github.com/LGiki/gnome-shell-extension-simple-system-monitor.git"
  pushd gnome-shell-extension-simple-system-monitor
  ./build.sh
  gnome-extensions install ssm-gnome\@lgiki.net.shell-extension.zip
  popd
  # DONE weather-oclock
  git clone -q "https://github.com/CleoMenezesJr/weather-oclock"
  pushd weather-oclock
  make install
  mv weatheroclock@CleoMenezesJr.github.io/ -t \
     "${HOME}/.local/share/gnome-shell/extensions/"
  popd
  # TODO watch searchprovider-for-browser-tabs
  git clone -q https://github.com/harshadgavali/searchprovider-for-browser-tabs/
  pushd searchprovider-for-browser-tabs
  pushd shellextension
  yarn
  yarn build
  yarn extension:install
  popd
  popd
  sudo dnf copr enable harshadgavali/searchproviders
  sudo dnf install tabsearchproviderconnector
}

# TODO: set up sasl ? or cert-based authentication for libera ?
# just generate a cert
function setup_irc_cert {

}

# ADDITIONAL: set it up for roaming also
# see https://libera.chat/guides/registration
# TODO: setup slock on close
# TODO: handler to exit only specific setup function

# TODO: test and detail
function setup_aws {
  after python # we need python first
  ensure_packages aws
  # setup EB CLI
  pushd "${BASE_CLONE_DIR}"
  git clone -q "https://github.com/aws/aws-elastic-beanstalk-cli-setup.git"
  pushd aws-elastic-beanstalk-cli-setup
  echo "AWS: Installing 'ebcli'..."
  python ./scripts/ebcli_installer.py &>/dev/
  grep -q "^[a-z].*ebcli-virtual-env/executables:$PATH" \
       "${HOME}/.bashrc"
}

# DONE:
function setup_usbguard {
  ensure_packages usbguard
  usbguard generate-polciy > /etc/usbguard/rules.conf
  systemctl enable --now usbguard
}

# DONE
function setup_autorandr {
  ensure_packages autorandr
  read -p "Laptop only?" answer
  if [[ "${answer}" =~ ".*Y.*" ]]; then
    autorandr --save laptop # For test to succeed.
  else
    read -p "Autorandr: Setup your monitors successfully, then press any key to continue."
    autorandr --save desktop-setup
    echo "autorandr --load desktop-setup --force" \
         > /usr/lib/systemd/system-sleep/autorandr
    echo "xrandr --output HDMI-A-1 --gamma 1:1:1" \
         >> /usr/lib/systemd/system-sleep/autorandr
    echo "xrandr --output HDMI-A-0 --gamma 1:1:1" \
         >> /usr/lib/systemd/system-sleep/autorandr
    echo "xrandr --output DisplayPort-0 --gamma 1:1:1" \
         >> /usr/lib/systemd/system-sleep/autorandr
  fi
}

# DONE:
function setup_rpm_fusion {
  sudo dnf install -q -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf swap -q -y ffmpeg-free ffmpeg --allowerasing
}

while getopts "af:" opt; do
                                                                                                                                                                                                                                                                                                                                                                                                  case "${opt}" in
                                                                                                                                                                                                                                                                                                                                                                                                    a) ;;
                                                                                                                                                                                                                                                                                                                                                                                                    b) ;;
                                                                                                                                                                                                                                                                                                                                                                                                    *) ;;
                                                                                                                                                                                                                                                                                                                                                                                                  esac
done

mkdir -p "${BASE_CLONE_DIR}" || return 1

# translates to function (feature->function), just call all
# a) for func in "$feature_to_function_hash[*]"; do "${func}"; done ;;

# # check against avialable features. if no feature then abort
# f) set -f;
#    IFS=','
#    for choice in "${OPTARG[*]}"; do
#          if ! [[ ${feature_to_function_hash[$choice] ]]; then



#                 err "${choice} does not exist. Exiting."
#                 print_help
#                 return 1;

#                else
#                  ${feature_to_function_hash[$choice]} # call it
#               fi


#                shift # go to next
#                ;;

#               done
#                esac
#               done


#                # TODO: configurable quiet?

# TODO
function setup-git-config {
}
