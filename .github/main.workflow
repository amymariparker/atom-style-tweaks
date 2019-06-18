workflow "Generate documentation on push to master" {
  on = "push"
  resolves = ["Publish docs"]
}

action "debug" {
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
  needs = ["debug", "Generate docs"]
  uses = "peaceiris/actions-gh-pages@v1.0.1"
  secrets = ["ACTIONS_DEPLOY_KEY"]
  env = {
    PUBLISH_DIR = "./doc"
    PUBLISH_BRANCH = "gh-pages"
  }
}
