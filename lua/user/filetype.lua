vim.filetype.add({
  filename = {
    ['go.sum'] = 'go',
    ['yarn.lock'] = 'yaml',
    ['.ansible-lint'] = 'yaml',
  },
  pattern = {
    ['.*%.js%.map'] = 'json',
    ['.*%.postman_collection'] = 'json',
    ['.*/playbooks/.*%.yaml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.yml'] = 'yaml.ansible',
    ['.*/roles/.*%.yaml'] = 'yaml.ansible',
    ['.*/roles/.*%.yml'] = 'yaml.ansible',
  },
})
