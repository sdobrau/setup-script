#!/usr/bin/env bats
# bats file_tags=auth

### YUBIKEY

# DONE
function test_setup_yubikey_with_luks_partition_crypttab_entries { #@test
  run setup_yubikey_with_luks_partition
  for partition in "$(find_luks_partitions)"; do
    # test if present
    uuid="$(lsblk -d -n --output UUID -f "$partition")"
    # is the corresponding entry found in /etc/crypttab?
    grep -q 'luks-$uuid UUID=$uuid none discard fido2-device=auto' /etc/crypttab
  done
}

# DONE:
function test_setup_yubikey_for_pam { #@test
  run setup_yubikey_for_pam gdm sudo login
  [[ -f /etc/pam.d/gdm.bak ]]
  grep -q pam_u2f /etc/pam.d/gdm
  [[ -f /etc/pam.d/sudo.bak ]]
  grep -q pam_u2f /etc/pam.d/sudo
  [[ -f /etc/pam.d/login.bak ]]
  grep -q pam_u2f /etc/pam.d/login

}

# function test_setup_yubikey_for_gpg { #@test
#   systemctl is-enabled pcscd.service
#   systemctl is-active pcscd.service
# }

# DONE
function test_setup_browserpass_native_for_chrome { #@test
  run setup_browserpass_native_for_chrome
  browserpass-linux64 -version
}

### PASS

# DONE
function test_setup_pass_extensions {
  run setup_pass_update
  pass update &>/dev/null
  run setup_pass_coffin
  pass coffin -h &>/dev/null
}

### TEARDOWN

function teardown_file { #@test
  # DONE test_setup_yubikey_with_luks_partition_crypttab_entries
  echo "" >/etc/crypttab
  for partition in "$(find_luks_partitions)"; do
    # test if present
    uuid="$(lsblk -d -n --output UUID -f "$partition")"
    # TODO: expect
    systemd-cryptenroll --wipe-slot=fido2 /dev/${partition}
  done
  # DONE test_setup_yubikey_for_pam
  dnf remove -y yubikey-manageryubikey-manager-qt pam_yubico \
    yubioath-desktop
  rm -rf /etc/Yubico/
  mv /etc/pam.d/gdm.bak /etc/pam.d/gdm
  mv /etc/pam.d/sudo.bak /etc/pam.d/sudo
  mv /etc/pam.d/login.bak /etc/pam.d/login
  # DONE test_setup_yubikey_for_gpg
  dnf install -q -y pcscd.service
  systemctl enable --now pcscd.service
  # DONE test_setup_pass_update
  pushd "${BASE_CLONE_DIR}/pass-update"
  sudo make uninstall
  rm -rf "${BASE_CLONE_DIR}/pass-update"
  popd

  pushd "${BASE_CLONE_DIR}/pass-coffin"
  sudo make uninstall
  popd
  rm -rf "${BASE_CLONE_DIR}/pass-coffin"
}
