{
  programs.zed-editor.userDebug = [
    {
      label = "Rust: launch binary";
      adapter = "lldb-dap";
      request = "launch";
      program = "{0}";
    }
    {
      label = "Go: launch file";
      adapter = "Go (Delve)";
      request = "launch";
      mode = "debug";
      program = "{0}";
    }
    {
      label = "Go: launch package";
      adapter = "Go (Delve)";
      request = "launch";
      mode = "debug";
      program = "{0}";
    }
    {
      label = "Go: attach";
      adapter = "Go (Delve)";
      request = "attach";
      mode = "local";
      processId = "{0}";
    }
    {
      label = "Python: launch file";
      adapter = "debugpy";
      request = "launch";
      program = "{0}";
    }
    {
      label = "C: launch binary";
      adapter = "lldb-dap";
      request = "launch";
      program = "{0}";
    }
    {
      label = "C++: launch binary";
      adapter = "lldb-dap";
      request = "launch";
      program = "{0}";
    }
  ];
}
