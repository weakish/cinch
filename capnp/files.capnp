@0x9afcc4d6f94840b3;

struct File {
  # ID is XXHash 64 int digest.
  id @0 :UInt64;
  name @1 :Text;
  size @2 :UInt64;
  mtime @3 :Float64;
  digests @4 : List(FileDigest);
  paths @5 :List(FilePath);

  struct FileDigest {
    digest @0 :Data;
    algorithm @1 :Algorithm;

    enum Algorithm {
      # Widely used.
      # security < 64 bits (collisions found)
      md5 @0;
      # security < 80 bits
      # (theoretical attack in 261 operations)
      sha1 @1;
      # SHA-2 family.
      # security < 112 bits
      sha224 @2;
      # security < 128 bits
      sha256 @3;
      # security < 192 bits
      sha384 @4;
      # security < 256 bits
      sha512 @5;
      # All the above algorithms are `hashlib.algorithms_guaranteed`
      # in Python 2.9+, and also available in Python 2.7+.
    }
  }

  struct FilePath {
    # Host name, device name, or cloud disk provider's name.
    hostname @0 :Text;
    # Without '/' at the end.
    directory @1 :Text;
    basename @2 :Text;
  }
}

struct Tree {
  files @0 :List(File);
}
