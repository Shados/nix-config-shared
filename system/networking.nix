{ config, pkgs, lib, ... }:
{
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
  };
}
