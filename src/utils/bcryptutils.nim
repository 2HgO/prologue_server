import bcrypt
import strutils

proc decodeVersion(src: seq[byte]) : tuple[n: int, minor: byte, major: byte] =
  var major = src[1]
  var (n, minor) = (2, byte(0))
  if src[2] != 0x24:
    minor = src[2]
    n += 1
  return (n, minor, major)

proc decodeCost(src: seq[byte]) : tuple[n: int, cost: int] =
  var cost = cast[string](src[0..1]).parseInt
  return (2, cost)

proc saltFromHash(hashedSecret: seq[byte]) : string =
  var hashedSecret = hashedSecret
  var n = decodeVersion(hashedSecret).n
  hashedSecret = hashedSecret[n+1..^1]
  n = decodeCost(hashedSecret).n
  hashedSecret = hashedSecret[n+1..^1]
  var salt = newSeq[byte](22)
  salt[0..^1] = hashedSecret[0..<22]
  # hashedSecret = hashedSecret[23..high(hashedSecret)]
  # var hash = newSeq[byte](hashedSecret.len)
  # hash[0..^1] = hashedSecret
  cast[string](salt)

proc genSalt*() : string =
  var convolutedSalt = cast[seq[byte]](genSalt(16))
  var n = decodeVersion(convolutedSalt).n
  convolutedSalt = convolutedSalt[n+1..^1]
  n = decodeCost(convolutedSalt).n
  convolutedSalt = convolutedSalt[n+1..^1]
  return cast[string](convolutedSalt)

proc compareHashAndPassword*(hashedPassword: seq[byte], password: seq[byte]) : bool {.inline.} =
  return compare(cast[string](hashedPassword), hash(cast[string](password), saltFromHash(hashedPassword)))
