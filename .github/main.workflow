workflow "Generate documentation on push to master" {
  on = "push"
  resolves = ["Debug info", "Publish docs"]
}

action "Debug info" {
  uses = "actions/bin/debug@master"
}

action "Only on master branch" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "Generate docs" {
  needs = ["Only on master branch"]
  uses = "lee-dohm/generate-elixir-docs@master"
  env = {
    MIX_ENV = "test"
    TAG_VERSION_WITH_HASH = "true"
  }
}

action "Publish docs" {
  needs = ["Generate docs"]
  uses = "peaceiris/actions-gh-pages@v1.0.1"
  secrets = ["ACTIONS_DEPLOY_KEY"]
  env = {
    PUBLISH_DIR = "./doc"
    PUBLISH_BRANCH = "gh-pages"
  }
}
