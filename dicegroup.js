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
  "schedule": ["* * * * 0"],
  "updateNotScheduled": false,
  "automerge": false,
  "enabledManagers": [
    "github-actions",
    "custom.regex",
    "conan"
  ],
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": [
        "/^\\.github/.*\\.ya?ml$/",
        "/(^|/)Dockerfile$/"
      ],
      "matchStrings": [
        "conan-version:\\s*[\"']?(?<currentValue>\\d+\\.\\d+\\.\\d+)[\"']?",
        "conan==(?<currentValue>\\d+\\.\\d+\\.\\d+)"
      ],
      "datasourceTemplate": "pypi",
      "depNameTemplate": "conan"
    },
    {
      "customType": "regex",
      "managerFilePatterns": [
        "/^\\.github/.*\\.ya?ml$/"
      ],
      "matchStrings": [
        "cmake-version:\\s*[\"']?(?<currentValue>\\d+\\.\\d+\\.\\d+)[\"']?"
      ],
      "datasourceTemplate": "github-releases",
      "depNameTemplate": "Kitware/CMake",
      "extractVersionTemplate": "^v(?<version>.*)$"
    }
  ],
  "packageRules": [
    {
      "matchManagers": [
        "github-actions"
      ],
      "extractVersion": "^(?<version>v\\d+\\.\\d+\\.\\d+)$"
    },
    {
      "matchManagers": [
        "github-actions"
      ],
      "matchDepNames": [
        "rui314/setup-mold",
        "rlalik/setup-cpp-compiler"
      ],
      "extractVersion": "^(?<version>v\\d+(?:\\.\\d+){0,2})$"
    },
    {
      "matchManagers": [
        "github-actions"
      ],
      "matchUpdateTypes": [
        "minor",
        "patch"
      ],
      "automerge": true
    },
    {
      "matchDepNames": [
        "conan",
        "Kitware/CMake"
      ],
      "matchUpdateTypes": [
        "minor",
        "patch"
      ],
      "automerge": true
    },
    {
      // Normally follows the file-level Sunday-only schedule above. Set
      // FORCE_REUSABLE_WORKFLOWS_BUMP=true on the Renovate run to bypass
      // that and let this one dependency update any day.
      "matchManagers": [
        "github-actions"
      ],
      "matchDepNames": [
        "dice-group/cpp-conan-release-reusable-workflow"
      ],
      ...(process.env.FORCE_REUSABLE_WORKFLOWS_BUMP === "true"
        ? { "schedule": ["at any time"] }
        : {})
    }
  ]
};
