<?php
header('Content-Type: application/json; charset=utf-8');
echo json_encode([
  "success"=>true,
  "force_login"=>true,
  "remember_key"=>true,
  "session_timeout_seconds"=>300,
  "minutes"=>5,
  "show_certificate"=>true,
  "certificate_url"=>"http://191.252.210.109/proxy2026.der"
], JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT);
