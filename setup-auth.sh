# DONE
function setup_yubikey {

  # 4, fido/u2f support
  echo "YubiKey: Installing necessary packages..."
  ensure_packages yubikey-manager yubikey-manager-qt \
                  pam_yubico # for PAM (desktop authentication)
  setup_yubikey_with_luks_partition
  setup_yubikey_for_pam sudo gdm login
}

# DONE
# I think touch required everywhere is a reasonable base
function setup_yubikey_for_pam {
  if [[ Array::hasValue $@ "sudo" ]]; then
    echo "Setting up U2F for sudo..."
    # generate a key bound to the current user.
    su - ${USER}
    mkdir ${HOME}/.config/Yubico/
    pamu2fcfg > ${HOME}/.config/Yubico/u2f_keys
    sudo su -
    mv /home/${EUSER}/.config/Yubico/u2f_keys /etc/Yubico/u2f_keys

    cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
    sed -ie "s/^auth.*substack/auth\tsufficient\tpam_u2f.so \
userpresence=1 \
authfile=\/etc\/Yubico\/u2f_keys/g" /etc/pam.d/sudo
  fi

  if [[ Array::hasValue $@ "gdm" ]]; then
    echo "Setting up U2F for GDM login..."
    cp /etc/pam.d/gdm-password /etc/pam.d/gdm-password.bak
    sed -ie "s/^auth.*substack/auth\tsufficient\tpam_u2f.so \
userpresence=1 \
authfile=\/etc\/Yubico\/u2f_keys/g" /etc/pam.d/gdm-password
  fi

  if [[ Array::hasValue $@ "login" ]]; then
    echo "Setting up U2F for console login..."
    cp /etc/pam.d/login /etc/pam.d/login.bak
    sed -ie "s/^auth.*substack/auth\tsufficient\tpam_u2f.so \
userpresence=1 \
authfile=\/etc\/Yubico\/u2f_keys/g" /etc/pam.d/login
  fi
}

# DONE
function setup_yubikey_with_luks_partition {
  # https://fedoramagazine.org/use-systemd-cryptenroll-with-fido-u2f-or-tpm2-to-decrypt-your-disk/
  echo "add_dracutmodules+=\" fido2 \"" | tee /etc/dracut.conf.d/fido2.conf
  # enroll all partitions
  for partition in "$(find_luks_partitions)"; do
    # enroll
    uuid="$(lsblk -d -n --output UUID -f /dev/"$partition")"
    echo "luks-$uuid UUID=$uuid none discard fido2-device=auto" \
         >> /etc/crypttab
    systemd-cryptenroll --fido2-device auto "/dev/${partition}"
  done
  # setup
  # rebuild initramfs
  dracut -f
}

# Following https://github.com/drduh/YubiKey-Guide
# A secured master key is generated along with:
# 1. A key for signing
# 2. A key for encryption
# 3. A key for authentication
# TODO
# function setup_yubikey_for_gpg {
# gnupg 'scdaemon'
# ... do stuff
# conflicts with pcsc so we are disabling it entirely
# https://ludovicrousseau.blogspot.com/2019/06/gnupg-and-pcsc-conflicts.html
#   systemctl disable --now pcscd.service
# }

# DONE
function setup_browserpass_native_for_chrome {
  # 1. import pub keys
  ensure_packages go
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://github.com/browserpass/browserpass-native
  pushd browserpass-native
  make browserpass-linux64

  sudo su -
  make BIN=browserpass-linux64 install # as root
  su - ${EUSER}
  make BIN=browserpass-linux64 hosts-chrome-user # configure for ${EUSER}
  make BIN=browserpass-linux64 policies-chrome-user # configure for ${EUSER}
  exit # ?
  popd
  rm -rf browserpass-native
}

# DONE
function setup_pass_extensions {
  setup_pass_update
  setup_pass_coffin
}

# DONE
function setup_pass_update {
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://github.com/roddhjav/pass-update/
  cd pass-update
  sudo make install
  popd
}

# DONE
function setup_pass_coffin {
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://github.com/ayushnix/pass-coffin
  cd pass-coffin
  sudo make install
  popd
}

# TODO: setup yubikey for secrets
# https://docs.fedoraproject.org/en-US/quick-docs/using-yubikeys/
