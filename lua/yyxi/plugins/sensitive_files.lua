local M = {}

local sensitive_files = require('yyxi.utilities.sensitive_files')

function M.configure()
  sensitive_files.setup({
    '.env',
    '.env.*',
    '*.env',
    '*.env.*',
    '.npmrc',
    '*/.npmrc',
    '*/.config/gh/hosts.yml',
    '*/.aws/credentials',
    '*/.aws/config',
    '*/.ssh/*',
    '/etc/ssh/*',
    '*/.docker/config.json',
    '*/.oci/config',
    '*.tfvars',
    '*.tfvars.json',
    '*/.envrc',
    '*/.config/gcloud/*',
    '*/.azure/*',
    '*/.cargo/credentials',
    '*/.cargo/credentials.toml',
    '*/.netrc',
    '*/.git-credentials',
    '1password-credentials.json',
    '*/.pi/auth.json',
    '*/.pi/auth-*.json',
    '*/.codex/auth.json',
    '*/.codex/auth-*.json',
    '*/.claude/.credentials.json',
    '*/.config/claude-code/auth.json',
    '*.pem',
    '*.key',
    '*.p12',
    '*.jks',
  })
end

return M
