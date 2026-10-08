{ pkgs, ... }:

{
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      OLLAMA_KV_CACHE_TYPE     = "q8_0";
      OLLAMA_NUM_PARALLEL      = "1";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_KEEP_ALIVE        = "30m";
      OLLAMA_NUM_BATCH         = "512";
    };
    package = pkgs.ollama-rocm;
  };
}
