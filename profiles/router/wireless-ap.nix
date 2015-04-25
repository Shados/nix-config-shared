{ config, pkgs, lib, ... }:

let 
  cfg = config.fragments.router;
in

lib.mkIf (cfg.enable && cfg.enableWifi) {
  services.hostapd = {
    enable = true;
    hwMode = "g";
    interface = cfg.wifiInt;
    ssid = cfg.wifiSSID;
    channel = 2;
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
    extraCfg = # TODO: Standardize this as extraConfig like every other fucking module
    ''
      auth_algs=1
      eap_server=0
      eapol_key_index_workaround=0
      wpa=2
      wpa_passphrase=${cfg.wifiPassphrase}
      wpa_key_mgmt=WPA-PSK
      wpa_pairwise=CCMP
      rsn_pairwise=CCMP

      bridge=${cfg.intBridge}
      ieee80211n=1
      ieee80211ac=1
      wmm_enabled=1
      wme_enabled=1
      ht_capab=[HT40+][SHORT-GI-40][DSSS_CCK-40][TX-STBC][RX-STBC1]
      #vht_oper_chwidth=1
      #vht_oper_centr_freq_seg0_idx=42

      country_code=AU
      ieee80211d=1
      ieee80211h=1
    '';
  };
}

# TODO: Use 802.11ac (requires newer/git? hostapd)
