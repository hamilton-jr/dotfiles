import { definePlugin } from "fresh";

export default definePlugin({
  name: "zshrc-support",
  setup(editor) {
    // LSP para shell/zsh
    editor.lsp.registerServer("sh", {
      command: "bash-language-server",
      args: ["start"],
      filetypes: ["sh", "bash", "zsh", "zshrc"]
    });

    // Linter com shellcheck
    editor.commands.register("lint-zsh", async (file) => {
      await editor.runExternalTool("shellcheck", [file.path]);
    });

    // Formatador com shfmt
    editor.commands.register("format-zsh", async (file) => {
      await editor.runExternalTool("shfmt", ["-w", file.path]);
    });
  }
});
