{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.nginx;
  nginx_package = cfg.package;
in

mkIf cfg.enable {
  # If we ever want length hiding at the server level, we can have it: https://github.com/nulab/nginx-length-hiding-filter-module
  # nixpkgs.config = {
  #   packageOverrides = pkgs: rec {
  #     nginx = pkgs.nginx.override {
  #       lengthhiding = true;
  #     };
  #   };
  # };
  services.nginx = {
    recommendedGzipSettings = true;
    eventsConfig = ''
      #langon = nginx
      # determines how much clients will be served per worker
      # max clients = worker_connections * worker_processes
      # max clients is also limited by the number of socket connections available on the system (~64k)
      worker_connections  4000;

      # optmized to serve many clients with each thread, essential for linux
      use epoll;

      # accept as many connections as possible, may flood worker connections if set too low
      multi_accept on;
      #langoff = nginx
    '';
    appendHttpConfig = ''
      #langon = nginx
      default_type  application/octet-stream;

      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
      access_log  /srv/http/logs/access.log  main;

      server_names_hash_bucket_size 64; # Increases maximum domain name size allowed

      # directio for larger files
      # sendfile for smaller (<16MB) files
      directio 16M;
      output_buffers 2 1M;
      # copies data between one FD and other from within the kernel
      # faster then read() + write()
      sendfile on;
      sendfile_max_chunk 512k;

      # send headers in one piece, its better then sending them one by one 
      tcp_nopush on;

      # don't buffer data sent, good for small data bursts in real time
      tcp_nodelay on;

      # server will close connection after this time
      keepalive_timeout 30;

      # number of requests client can make over keep-alive -- for testing
      keepalive_requests 100000;

      # allow the server to close connection on non responding client, this will free up memory
      reset_timedout_connection on;

      # request timed out -- default 60
      client_body_timeout 10;

      # if client stop responding, free up memory -- default 60
      send_timeout 10;

      # Load modular configuration files from the /etc/nginx/conf.d directory.
      # See http://nginx.org/en/docs/ngx_core_module.html#include
      # for more information.
      include /srv/http/conf.d/*.nginx;
      #langoff = nginx
    '';
    appendConfig = lib.mkBefore ''
      #langon = nginx
      worker_processes  auto;
      worker_rlimit_nofile 100000; # Max # of open FDs

      pid        /run/nginx.pid;

      # cache informations about FDs, frequently accessed files
      # can boost performance, but you need to test those values
      #open_file_cache max=200000 inactive=20s; 
      #open_file_cache_valid 30s; 
      #open_file_cache_min_uses 2;
      #open_file_cache_errors on;
      #langoff = nginx
    '';
  };
}
