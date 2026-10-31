{ fetchFromGitHub, fetchurl }:

let
  # Noto Sans 2.015, the commit CMake downloads at configure time.
  notoSans = path: hash: fetchurl {
    url = "https://raw.githubusercontent.com/notofonts/notofonts.github.io/42af67ccd12bc0e31ed85384bf73e39248265374/fonts/${path}";
    inherit hash;
  };
in
{
  notoSansLicense = notoSans "LICENSE" "sha256-8glbCL7QiyOm/iYRL81nmivuPwAu7wd+sF0hXtEFG9g=";
  notoSansRegular = notoSans "NotoSans/hinted/ttf/NotoSans-Regular.ttf" "sha256-R4xVjqcWAzzWDANDj2KN+nVpTc9rX21QWi8F/StPOCM=";
  notoSansBold = notoSans "NotoSans/hinted/ttf/NotoSans-Bold.ttf" "sha256-HfB1o4D8fLiYrPZMH3s7TdeA3jyqhgF4v5Kd41gXqRM=";
  notoSansItalic = notoSans "NotoSans/hinted/ttf/NotoSans-Italic.ttf" "sha256-Rn4/ie7KQQi7hxCiueDPIoGsVtWwYJIRqDd20FBe7LU=";
  notoSansBoldItalic = notoSans "NotoSans/hinted/ttf/NotoSans-BoldItalic.ttf" "sha256-G2AqnWNTvkLJHfCXpIV7afomlvJnA9ejO1ShXYfCYiw=";
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
