{ fetchFromGitHub, fetchurl }:

{
  ffmpeg = fetchurl {
    url = "https://github.com/KytyPS5/ext-ffmpeg-core/releases/download/9ac4cfd195f1/ffmpeg-linux-x64.zip";
    hash = "sha256-9GWa0J5vK5ns8CJ8pW/ku7NFcs3Y2F/4U4T3S6OPI+8=";
  };
  opus = fetchFromGitHub {
    owner = "xiph";
    repo = "opus";
    rev = "ddbe48383984d56acd9e1ab6a090c54ca6b735a6";
    hash = "sha256-M1G7ypcfs7nJmXgkyoG96jT/CkgN5BOzy+DGO4LVCvA=";
  };
  openxr = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "OpenXR-SDK";
    rev = "f2448a8797c85814aa892efc1ab8707900fbcc78";
    hash = "sha256-glcHMArDabXbrxO4CY2QeTJFTeUTQH4v1O03LuhML7E=";
  };
  xbyak = fetchFromGitHub {
    owner = "herumi";
    repo = "xbyak";
    rev = "44a72f369268f7d552650891b296693e91db86bb";
    hash = "sha256-S4arAwbhTGsUhDFfy5fTGyDvCm0/x/LKiiPTAuRM8Yk=";
  };
  zydis = fetchFromGitHub {
    owner = "zyantific";
    repo = "zydis";
    rev = "120e0e705f8e3b507dc49377ac2879979f0d545c";
    fetchSubmodules = true;
    hash = "sha256-bjQCaYRA94CGBsxG+UOuDDyLrH3k2ERJbn0+7ITGLeU=";
  };
  zstd = fetchFromGitHub {
    owner = "facebook";
    repo = "zstd";
    rev = "f8745da6ff1ad1e7bab384bd1f9d742439278e99";
    hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
  };
  zarchive = fetchFromGitHub {
    owner = "Exzap";
    repo = "ZArchive";
    rev = "d2c717730092c7bf8cbb033b12fd4001b7c4d932";
    hash = "sha256-hX637O/mVLTzmG0a9swJu9w+3o26VHo+K/9RhMuf1lI=";
  };
}
