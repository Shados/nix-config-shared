{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.fragments.router;
in

lib.mkIf (cfg.enable && cfg.enableWifi) {
  systemd.services.hostapd.after = [ "${cfg.intBridge}-netdev.service" ];
  services.hostapd = {
    enable = true;
    logLevel = 0;
    hwMode = "g";
    interface = cfg.wifiInt;
    ssid = cfg.wifiSSID;
    channel = 7;
    extraConfig = ''
      bridge=${cfg.intBridge}

      auth_algs=1
      eap_server=0
      eapol_key_index_workaround=0
      wpa=2
      wpa_passphrase=${cfg.wifiPassphrase}
      wpa_key_mgmt=WPA-PSK
      wpa_pairwise=CCMP
      rsn_pairwise=CCMP

      wmm_enabled=1
      # wmm_ac_bk_cwmin=4
      # wmm_ac_bk_cwmax=10
      # wmm_ac_bk_aifs=7
      # wmm_ac_bk_txop_limit=0
      # wmm_ac_bk_acm=0
      # wmm_ac_be_aifs=3
      # wmm_ac_be_cwmin=4
      # wmm_ac_be_cwmax=10
      # wmm_ac_be_txop_limit=0
      # wmm_ac_be_acm=0
      # wmm_ac_vi_aifs=2
      # wmm_ac_vi_cwmin=3
      # wmm_ac_vi_cwmax=4
      # wmm_ac_vi_txop_limit=94
      # wmm_ac_vi_acm=0
      # wmm_ac_vo_aifs=2
      # wmm_ac_vo_cwmin=2
      # wmm_ac_vo_cwmax=3
      # wmm_ac_vo_txop_limit=47
      # wmm_ac_vo_acm=0

      ieee80211n=1
      wme_enabled=1
      ht_capab=[HT40+][SHORT-GI-40][DSSS_CCK-40]
      #vht_oper_chwidth=1
      #vht_oper_centr_freq_seg0_idx=42

      country_code=AU
      ieee80211d=1
      ieee80211h=1
    '';
    # N-band
    #extraCfg = # TODO: Standardize this as extraConfig like every other fucking module
    #''
    #  auth_algs=1
    #  eap_server=0
    #  eapol_key_index_workaround=0
    #  wpa=2
    #  wpa_passphrase=${cfg.wifiPassphrase}
    #  wpa_key_mgmt=WPA-PSK
    #  wpa_pairwise=CCMP
    #  rsn_pairwise=CCMP
    #
    #  bridge=${cfg.intBridge}
    #  ieee80211n=1
    #  wmm_enabled=1
    #  wme_enabled=1
    #  #ht_capab=[HT40+][SHORT-GI-40][DSSS_CCK-40][TX-STBC][RX-STBC1]
    #  #vht_oper_chwidth=1
    #  #vht_oper_centr_freq_seg0_idx=42

    #  country_code=AU
    #  #ieee80211d=1
    #  #ieee80211h=1
    #'';
    # AC-band
    #extraCfg = # TODO: Standardize this as extraConfig like every other fucking module
    #''
    #  auth_algs=1
    #  eap_server=0
    #  eapol_key_index_workaround=0
    #  wpa=2
    #  wpa_passphrase=${cfg.wifiPassphrase}
    #  wpa_key_mgmt=WPA-PSK
    #  wpa_pairwise=CCMP
    #  rsn_pairwise=CCMP

    #  bridge=${cfg.intBridge}
    #  ieee80211n=1
    #  ieee80211ac=1
    #  wmm_enabled=1
    #  wme_enabled=1
    #  ht_capab=[HT40+][SHORT-GI-40][DSSS_CCK-40]
    #  #vht_oper_chwidth=1
    #  #vht_oper_centr_freq_seg0_idx=42

    #  country_code=AU
    #  ieee80211d=1
    #  ieee80211h=1
    #'';
  };
}

# TODO: Use 802.11ac (requires newer/git? hostapd)
