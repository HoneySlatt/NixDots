{ lib, ... }:

let
  ollamaModels = [
    "qwen3-vl-8b-vision:latest"
    "qwen3-vl:8b"
    "deepseek-r1-14b-math:latest"
    "gpt-oss-20b-think:latest"
    "qwen36-27b-research:latest"
    "qwen3-coder-30b-agent:latest"
    "qwen3-14b-prof-code:latest"
    "qwen3-14b-daily:latest"
    "deepseek-r1:14b"
    "qwen3-coder:30b"
    "qwen3:14b"
    "qwen3.6:27b"
    "gpt-oss:20b"
  ];
in
{
  programs.opencode = {
    enable = true;
    # Sessions can never be published as public share links
    settings.share = "disabled";
    settings.provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options.baseURL = "http://localhost:11434/v1";
      models = lib.genAttrs ollamaModels (name: { inherit name; });
    };
  };
}
