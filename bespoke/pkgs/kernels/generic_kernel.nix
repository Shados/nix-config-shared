{ stdenv, buildLinux
, version
, customVersion ? null
, extraConfig
, ... } @ args:

with stdenv.lib;
let
  baseKConfig = ''
    ${optionalString (! isNull customVersion) "LOCALVERSION ${customVersion}"}
  '' + ''
    # Disable some unnecessary debugging config
    # ?-appended to mark them as 'optional' to
    # generate-config.pl, so it doesn't error when 'make config' doesn't ask
    # about them (as pre-reqs for them may be disabled)
    DYNAMIC_DEBUG? n
    DEBUG_DEVRES? n
    DEBUG_STACK_USAGE? n
    DEBUG_STACKOVERFLOW? n
    DEBUG_INFO? n

    MEMTEST? n

    PM_ADVANCED_DEBUG? n

    # BFQ_GROUP_IOSCHED y
    ${optionalString (versionAtLeast version "4.12") ''
      # BFQ was added to mainline in 4.12
      # There were perf. issues introduced in 4.15 and not fixed until 4.16,
      # but we have the patches for those
      # CONFIG_DEFAULT_IOSCHED bfq
    ''}

    NET_SCH_MQPRIO? y

    ACCESSIBILITY? n
    AUXDISPLAY? n
    DONGLE? n
    HIPPI? n
    MTD_COMPLEX_MAPPINGS? n
    IP_VS? n
    IP_VS_PROTO_TCP? n
    IP_VS_PROTO_UDP? n
    IP_VS_PROTO_ESP? n
    IP_VS_PROTO_AH? n

    # FB devices I don't have
    FB_RIVA_I2C? n
    FB_ATY_CT? n # Mach64 CT/VT/GT/LT (incl. 3D RAGE) support
    FB_ATY_GX? n # Mach64 GX support
    FB_SAVAGE_I2C? n
    FB_SAVAGE_ACCEL? n
    FB_SIS? n
    FB_SIS_300? n
    FB_SIS_315? n
    FB_3DFX_ACCEL? n
    FB_GEODE? n


    # Disable firmware for various USB serial devices.
    # Only applicable for kernels below 4.16, after that no firmware is shipped in the kernel tree.
    ${optionalString (versionOlder version "4.16") ''
      USB_SERIAL_KEYSPAN_MPR? n
      USB_SERIAL_KEYSPAN_USA28? n
      USB_SERIAL_KEYSPAN_USA28X? n
      USB_SERIAL_KEYSPAN_USA28XA? n
      USB_SERIAL_KEYSPAN_USA28XB? n
      USB_SERIAL_KEYSPAN_USA19? n
      USB_SERIAL_KEYSPAN_USA18X? n
      USB_SERIAL_KEYSPAN_USA19W? n
      USB_SERIAL_KEYSPAN_USA19QW? n
      USB_SERIAL_KEYSPAN_USA19QI? n
      USB_SERIAL_KEYSPAN_USA49W? n
      USB_SERIAL_KEYSPAN_USA49WLC? n
    ''}


    # Features and hardware I'm unlikely to ever need (in this context, at
    # least)
    8139TOO_8129? n
    FUSION? n
    IRDA? n
    IRDA_ULTRA? n
    LOGIRUMBLEPAD2_FF? n # Logitech Rumblepad 2 force feedback
    MEGARAID_NEWGEN? n
    MOUSE_PS2_ELANTECH? n
    NET_FC? n
    MMC_BLOCK? n
    MMC_BLOCK_MINORS? 8
    REGULATOR? n
    TPS6105X? n
    RC_DEVICES? n
    RT2800USB_RT53XX? n
    RT2800USB_RT55XX? n
    SCSI_LOGGING? n
    MWAVE? n
    SERIAL_8250? n
    SLIP? n
    SLIP_SMART? n
    SLIP_COMPRESSED? n
    XEN? n
    MEDIA_DIGITAL_TV_SUPPORT? n
    MEDIA_CONTROLLER? n
    MEDIA_ANALOG_TV_SUPPORT? n
    VIDEO_STK1160_COMMON? n
    MEDIA_ATTACH? n
    USELIB? n

    # not using zram
    ZRAM? n
    ZSMALLOC? n
  '';
in

buildLinux (args // {
  extraConfig = baseKConfig + extraConfig;

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0"))) + optionalString (! isNull customVersion) customVersion;

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));
} // (args.argsOverride or {}))


