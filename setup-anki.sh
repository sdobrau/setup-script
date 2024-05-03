#!/usr/bin/env bash

# TODO:
function setup_anki_sync_server_nginx {
  ensure_packages nginx
}

function setup_nginx_with_modsec_and_rules {
  ensure_packages nginx mod_security_crs nginx-mod-security
  mkdir -p /etc/nginx/modsec/
  cp /usr/share/mod_modsecurity_crs/* -t /etc/nginx/modsec/
  echo "include /etc/nginx/modsec/rules/*.conf" >/etc/nginx/modsecurity.conf
}

# TODO: ANKI_PROFILE...
function setup_anki_connect {
  ANKI_PROFILE
  echo "Anki-connect: copying anki add-on..."
  cp -r ${BACKUP_DIR}/anki/addons/anki-connect/* -t \
     ${HOME}/.local/share/Anki2/addons21/
}

# DONE:
# Note: need to test anki-connect
function setup_anki_config {
  cp -r ${BACKUP_DIR}/Anki2 -t ${HOME}/.local/share/Anki2
}

# DONE
function setup_anki_sync_server {
  after python
  echo "Anki: Setting up anki-sync-server..."
  pushd "${PROJECT_HOME}" # usually ~/.virtualenvs/
  # Clone in PROJECT_HOME
  git clone -q "https://github.com/ankicommunity/anki-sync-server" anki-sync-server # Make a virtualenv named anki-sync-server, bind the git source to it, and openo2
  mkproject anki-sync-server
  # inside of the venv do this
  pip install -r src/requirements.txt
  pip install -e src
  cp src/ankisyncd.conf src/ankisyncd/.
  python -m ankisyncd_cli adduser strangepr0gram
  # copy service file
  cp -rv "${mount_point}"/systemd-services/anki-sync-server.service "${HOME}/.config/systemd/user/"
}

# DONE
function setup_anki_package {
  after python                    # need pipx
  echo "Jap: Installing Anki... " #
  pipx install aqt[qt6] &>/dev/null
}

function setup_anki_with_ajatt {
  # for morphman: need mecab morphological analyzer
  https://github.com/ianki/MecabUnidic/releases/download/v3.1.0/MecabUnidic3.1.0.ankiaddon

}
