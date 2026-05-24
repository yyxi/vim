local M = {}

-- Centralize repo-local filetype policy here.
--
-- Keep this file limited to:
-- 1. Neovim filetype detection overrides.
-- 2. Tree-sitter language aliases for those filetypes.
--
-- Add a rule here when this repository needs a stable local decision about how a
-- file should be classified or which parser language it should use.
--
-- Do not put plugin setup, runtimepath changes, parser installation logic, or
-- unrelated editor behavior here.

function M.filetype_add_spec()
  return {
    extension = {
      mbt = 'moonbit',
      mbti = 'moonbit',
      moonbit = 'moonbit',
      tfvars = 'terraform',
      tfstate = 'json',
    },
    filename = {
      ['moon.pkg'] = 'moonbit',
      ['gitconfig'] = 'gitconfig',
      ['.ansible-lint'] = 'yaml',
      ['fish_history'] = 'yaml',
      ['yarn.lock'] = 'yaml',
      ['.prettierignore'] = 'gitignore',
      ['.eslintignore'] = 'gitignore',
      ['api-extractor.json'] = 'jsonc',
    },
    pattern = {
      ['.*%.js%.map'] = 'json',
      ['.*%.postman_collection'] = 'json',
      ['.*/playbooks/.*%.yaml'] = 'yaml.ansible',
      ['.*/playbooks/.*%.yml'] = 'yaml.ansible',
      ['.*/roles/.*%.yaml'] = 'yaml.ansible',
      ['.*/roles/.*%.yml'] = 'yaml.ansible',
      ['.*/host_vars/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/group_vars/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/group_vars/.*/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/playbook.*%.ya?ml'] = 'yaml.ansible',
      ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/roles/.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/roles/.*/handlers/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
      ['.*/meta/.*%.ya?ml'] = 'yaml.ansible',
    },
  }
end

function M.treesitter_language_aliases()
  return {
    git_config = { 'gitconfig' },
    git_rebase = { 'gitrebase' },
    javascript = { 'javascriptreact', 'jsx', 'js' },
    json = { 'jsonc' },
    ssh_config = { 'sshconfig' },
    tsx = { 'typescriptreact', 'typescript.tsx' },
    yaml = { 'yaml.ansible' },
  }
end

return M
