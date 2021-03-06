from os import getEnv

let
  DB_NAME* = getEnv("DB_NAME", "test-db")
  DB_URL* = getEnv("DB_URL", "mongodb://127.0.0.1:27017")
  APP_PORT* = getEnv("APP_PORT", "55059")
  APP_ENV* = getEnv("APP_ENV", "playground")
  JWT_KEY* = getEnv("JWT_KEY", """-----BEGIN RSA PRIVATE KEY-----
MIICWgIBAAKBgGRE/g1aRPcXAwEaAlLRPZywnB4xo4Ib1bJTUNSbMKAhrqcteeOc
WkX9b/ItPwnYOoCabvJViiGrEAOc2DX2fXcbkJjQ0Rwb5zpWwcX54zTa+kccu4Ib
JwDxvIdqCtzO8o9Y+hMY7C9DW+zTX1koe2fwokkkpnDpoFitSKFebmfrAgMBAAEC
gYASNnXu9vaP6x4glRjW8iq+y1WQJnQMrgGi4n9MHuQ2MegHdbsuHLhI/j/XPWC1
6RC3S1Xbrq3ob6n4/gRHyP4A6ees39UDR31EWvONlNLGSTHjnsA4t5cuPyBllwgb
2uS2D835KO7y561HwadXTsM6Or0kYDtJFV4gvbDQvWkgAQJBALQAgx7CYEO1muA7
QMy+aHD3uUevwiYjpKNflFRbelbh7yBeF3qlAeEsKBElEGFik2uHcwORbQvgjWq4
zPXrHosCQQCOmpsKGl2j4YpMCGa3dWt38RL60A/2DC5oMt6ftoxiCADP65448T7K
GLodbgxucLkJa18hxw0kedAqyVNqBWghAkASDwcYm+mqgVrDak5q/CNgSgolngV9
bBAFb/5ipDbW5p3mAmqanFle7N4sMiq9inU90X4BeqKVEXc+oMG3XlpXAkBlN722
BRLUAIE+CHSH4TMfliBHoCjEFs9VrE2yBUtNRar16aKLfkh3/+cSfosaVK4xzmFe
wz9D1aZ4yB+J0D6hAkBKAlQI2yyav5OYj461KfPAAYOC/7cmjg6TlirExcGQF6Ik
ZJI4xw2/JfxjGE3iMQpjH5VF5G6ybBN8Fg580jRF
-----END RSA PRIVATE KEY-----""")
  JWT_PUB* = getEnv("JWT_PUB", """-----BEGIN PUBLIC KEY-----
MIGeMA0GCSqGSIb3DQEBAQUAA4GMADCBiAKBgGRE/g1aRPcXAwEaAlLRPZywnB4x
o4Ib1bJTUNSbMKAhrqcteeOcWkX9b/ItPwnYOoCabvJViiGrEAOc2DX2fXcbkJjQ
0Rwb5zpWwcX54zTa+kccu4IbJwDxvIdqCtzO8o9Y+hMY7C9DW+zTX1koe2fwokkk
pnDpoFitSKFebmfrAgMBAAE=
-----END PUBLIC KEY-----""")
