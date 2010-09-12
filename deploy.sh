#!/bin/sh

rm -rf "${WOW_BETA_ADDON_DIR}Bagnon"
rm -rf "${WOW_BETA_ADDON_DIR}Bagnon_Config"
rm -rf "${WOW_BETA_ADDON_DIR}Bagnon_GuildBank"

cp -r Bagnon "${WOW_BETA_ADDON_DIR}"
cp -r Bagnon_Config "${WOW_BETA_ADDON_DIR}"
cp -r Bagnon_GuildBank "${WOW_BETA_ADDON_DIR}"

cp LICENSE "${WOW_BETA_ADDON_DIR}Bagnon"
cp LICENSE "${WOW_BETA_ADDON_DIR}Bagnon_Config"
cp LICENSE "${WOW_BETA_ADDON_DIR}Bagnon_GuildBank"

cp README.textile  "${WOW_BETA_ADDON_DIR}Bagnon"