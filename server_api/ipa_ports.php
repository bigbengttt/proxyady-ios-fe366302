<?php
header('Content-Type: application/json; charset=utf-8');
echo json_encode([
  "success"=>true,
  "host"=>"191.252.210.109",
  "port"=>"8088",
  "default_port"=>"8088",
  "ports"=>[
    "8088 = HS alto",
    "8091 = HS alto + pescoço",
    "8092 = HS alto + antena",
    "8093 = HS peito",
    "8094 = HS peito + antena",
    "8095 = Bala mágica + antena",
    "8096 = HS pescoço + alto + antena",
    "8097 = HS pescoço"
  ]
], JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT);
