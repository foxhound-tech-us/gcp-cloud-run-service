# terraform-module-template

Module description goes here

## Prerequisites

TBD

## Important Notes

TBD

## Usage

### Module

To use the module, please see the example below:

```terraform
## TBD
```

### Terraform

Execution:

```bash
# Initialize Terraform. It’s going to download code for a provider(aws, gcp and azure) that we will use
terraform init

# Validate the syntax
terraform validate

# Terraform Format
terraform fmt

# Terraform Dry-Run. This command will tell what terraform does before making any changes.
#     1: (+ sign): Resource going to be created
#     2: (- sign): Resource going to be deleted
#     3: (~ sign): Resource going to be modified
terraform plan

# Create the resources. To apply the changes, run terraform apply command
terraform apply

# Destroy the resources
terraform destroy
```

## Module Documentation

<!-- BEGIN_TF_DOCS -->

{ .Content }

<!-- END_TF_DOCS -->

## Standard Module Repository Docs

> [!IMPORTANT]  
> This section should be left in each repo to provide the necessary instructions on how to interact with it.

<details>
<summary>Standard Terraform Module Docs</summary>

---

This repository was bootstrapped via Terraform module template. That means it is preconfigured for certain workflows.

This repo includes the following built-in workflows:

- Linting of:
  - YAML
  - Github Actions
  - Terraform HCL
- Checkov to check for baseline compliance of HCL code
- Dependabot for Github Actions
- Semantic Versioning of releases
  - PRs are checked to ensure their name matches Conventional Commit style
- Run Terraform Test on PRs and Releases
- Push Module to HCP/TFE after Release

### Github PR Rules

You should configure the repository to require certain checks to avoid merging in non-compliant code. Assuming the names of checks have not been changed, the following things should be added:

- Checkov / Run Checkov
- Lint / TFLint
- Lint / GitHub Action Lint
- Lint / YAML Lint
- Lint / Terraform Format
- Pre-release / Semantic Title
- Pre-release / Terraform Test
- Pre-release / Terraform Docs

### Semantic Versioning

> [!IMPORTANT]  
> **You must use `squash and merge` for PRs in order for this workflow to function properly. You cannot use merge commits, you must use the name of the PR as the commit message.**

In order to promote changes to this repository, you must understand Conventional Commit style commit messages. These types of commit messages allow code reviewers to influence the versioning of the package in an accessible way.

_Conventional Commit messages **must** be made upon merging in a PR, which in turn will influence the next version number of the release._

| Commit Prefix | Commit Message                   | SemVer Output                           |
| ------------- | -------------------------------- | --------------------------------------- |
| `docs`        | `docs: update readme`            | Increment SemVer **patch** version by 1 |
| `fix`         | `fix: add output property`       | Increment SemVer **patch** version by 1 |
| `ci`          | `ci: updated ci scripts`         | Increment SemVer **patch** version by 1 |
| `feat`        | `feat: add CMEK to resource`     | Increment SemVer **minor** version by 1 |
| `major`       | `major: rework module structure` | Increment SemVer **major** version by 1 |

- [More information about Conventional Commits can be found here.](https://www.conventionalcommits.org/en/v1.0.0/#summary)
- [PR names are checked with the following Github Action](https://github.com/amannn/action-semantic-pull-request)
- The [detailed SemVer specification can be found here](https://semver.org/), but simply following the rules above is sufficient to produce proper module versioning. It is not necessary to use SemVer commits during the normal development cycle, it is only necessary during merges.

### Push Terraform Module Action

> You _must_ configure the Github Action correctly in order to push modules to HCP/TFE, or hook-up TFE/HCP tag-based modules. If you are using the Tag-based workflow, you don't need to use a separate action to push modules.

The `.github/workflows/release.yml` file has an action for pushing modules to HCP/TFE. This needs to be altered to match your server, as well as the module.

See documentation for [bruceharrison1984/terraform-push-module](https://github.com/bruceharrison1984/terraform-push-module) on how to configure the action for pushing to TFE/HCP.

Module version numbers are derived from previous versions and Conventional Commit messages.

### Auto-Documentation

Module documentation will automatically be completed upon creating a PR. You do not need to fill out the [Module Documentation](#module-documentation) section by hand.

</details>
