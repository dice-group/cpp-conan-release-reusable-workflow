module.exports = {
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":disableDependencyDashboard"
  ],
  "onboarding": false,
  "requireConfig": "ignored",
  "vulnerabilityAlerts": {
    "enabled": false
  },
  "gitAuthor": "Adrian Macal <adrian@tentris.io>",
  "assignees": [
    "adrian-tentris"
  ],
  "prHourlyLimit": 0,
  "rebaseWhen": "behind-base-branch",
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": [
        "/(^|/)Dockerfile$/",
        "/\\.ya?ml$/"
      ],
      "matchStrings": [
        "# renovate: datasource=(?<datasource>\\S+) depName=(?<depName>\\S+)(?: extractVersion=(?<extractVersion>\\S+))?\\s*\\n\\s*(?:ARG\\s+)?\\w+\\s*[:=]\\s*(?:[^\\s:@]+:)?(?<currentValue>[^\\s@]+)(?:@(?<currentDigest>sha256:[a-f0-9]+))?"
      ]
    }
  ]
};
