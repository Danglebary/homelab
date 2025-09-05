{ config, lib, pkgs, ... }:

{
  # Dev user for personal development and hobby projects
  users.users.dev = {
    isNormalUser = true;
    description = "Development User";
    uid = 1002;
    extraGroups = [
      # No groups - complete isolation from system services
    ];
    packages = with pkgs; [
      # Programming Languages
      go                    # Go language
      bun                   # JavaScript/TypeScript runtime and package manager
      elixir               # Elixir language
      rustc                # Rust compiler
      cargo                # Rust package manager
      zig                  # Zig language
      
      # Development Tools
      neovim               # Modern Vim-based editor
      git                  # Version control
      curl                 # HTTP client
      jq                   # JSON processor
      tree                 # Directory structure viewer
      htop                 # System monitor
      just                 # Command runner
      
      # Additional utilities
      wget                 # File downloader
      ripgrep              # Fast grep alternative
      fd                   # Fast find alternative
    ];
    shell = pkgs.bash;     # Default shell
  };
}