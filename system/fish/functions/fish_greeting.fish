function fish_greeting
  # Don't need MOTD/logo/whatever in a non-interactive shell!
  if status --is-interactive
    echo ""
    print_nixos_logo
    echo ""
  end
end

function print_nixos_logo
  set c0 "\e[0;0m" # Default
  set c1 "\e[8;34m" # Light
  set c2 "\e[8;36m" # Dark
  set c3 "\e[8;32m" # Highlight
  set fulloutput \
    "$c1            :::.    $c2':::::     :::            %s" \
    "$c1           ':::::    $c2':::::.  ::::'           %s" \
    "$c1             :::::     $c2'::::.:::::            %s" \
    "$c1       .......:::::..... $c2::::::::    $c1.     %s" \
    "$c1      ::::::::::::::::::: $c2::::::    $c1.::  %s" \
    "$c1     ::::::::::::::::::::: $c2:::::.  $c1.:::: %s" \
    "$c2            .....           ':::' $c1:::::'    %s" \
    "$c2           :::::             ':' $c1:::::'     %s" \
    "$c2  ........:::::               ' $c1:::::::::::.%s" \
    "$c2 :::::::::::::     $c3 NixOS      $c1::::::::::::'%s" \
    "$c2  ::::::::::: $c1:.              $c1:::::      %s" \
    "$c2      .::::: $c1::::            $c1:::::       %s" \
    "$c2     .::::: $c1':::::          $c1'''''        %s" \
    "$c2     :::::   $c1':::::.$c2'::::::::::::::::::::'%s" \
    "$c2      :::     $c1::::::.$c2'::::::::::::::::::'%s" \
    "$c2       '     $c1::::::::: $c2'::::::::::            %s" \
    "$c1            :::::''::::.     $c2'::::.           %s" \
    "$c1          .:::::    ::::.     $c2'::::.         %s" \
    "$c1           ':::      ::::.     $c2':::"

  for line in $fulloutput
    printf "$line $c0\n"
  end
end
