local assert = require('luassert')
local sensitive_files = require('yyxi.utilities.sensitive_files')

local patterns = {
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
}

local function assert_matches(path) assert.is_true(sensitive_files.matches_path(path, patterns)) end

local function assert_does_not_match(path)
  assert.is_false(sensitive_files.matches_path(path, patterns))
end

describe('yyxi.utilities.sensitive_files', function()
  it(
    'deduplicates backupskip patterns without changing their meaning',
    function()
      assert.same(
        patterns,
        sensitive_files.backupskip_patterns(vim.list_extend(vim.deepcopy(patterns), { '.env' }))
      )
    end
  )

  it('matches env families', function()
    assert_matches('/tmp/.env')
    assert_matches('/tmp/.env.local')
    assert_matches('/tmp/app.env')
    assert_matches('/tmp/app.env.local')
    assert_does_not_match('/tmp/environment')
  end)

  it('matches basename and extension based secrets', function()
    assert_matches('/tmp/.npmrc')
    assert_matches('/home/example/project/prod.tfvars')
    assert_matches('/home/example/project/prod.tfvars.json')
    assert_matches('/home/example/secrets/1password-credentials.json')
    assert_matches('/home/example/certs/client.pem')
    assert_matches('/home/example/keys/signing.key')
    assert_matches('/home/example/keys/keystore.p12')
    assert_matches('/home/example/keys/truststore.jks')

    assert_does_not_match('/tmp/project.npmrc')
    assert_does_not_match('/tmp/hosts.yml')
    assert_does_not_match('/tmp/credentials')
    assert_does_not_match('/tmp/config')
  end)

  it('matches directory-scoped secret files', function()
    assert_matches('/tmp/project/.npmrc')
    assert_matches('/home/example/.config/gh/hosts.yml')
    assert_matches('/home/example/.aws/credentials')
    assert_matches('/home/example/.aws/config')
    assert_matches('/home/example/.ssh/config')
    assert_matches('/home/example/.ssh/id_ed25519')
    assert_matches('/etc/ssh/ssh_config')
    assert_matches('/home/example/.docker/config.json')
    assert_matches('/home/example/.oci/config')
    assert_matches('/home/example/project/.envrc')
    assert_matches('/home/example/.config/gcloud/application_default_credentials.json')
    assert_matches('/home/example/.azure/accessTokens.json')
    assert_matches('/home/example/.cargo/credentials')
    assert_matches('/home/example/.cargo/credentials.toml')
    assert_matches('/home/example/.netrc')
    assert_matches('/home/example/.git-credentials')
    assert_matches('/home/example/.pi/auth.json')
    assert_matches('/home/example/.pi/auth-prod.json')
    assert_matches('/home/example/.codex/auth.json')
    assert_matches('/home/example/.codex/auth-prod.json')
    assert_matches('/home/example/.claude/.credentials.json')
    assert_matches('/home/example/.config/claude-code/auth.json')

    assert_does_not_match('/tmp/ssh-config')
    assert_does_not_match('/tmp/etc/ssh/ssh_config')
  end)
end)
