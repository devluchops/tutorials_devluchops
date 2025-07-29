# Helm Commands

Helm is a package manager for Kubernetes that helps you deploy and manage applications easily. This guide provides a list of commonly used Helm commands:

## Table of Contents
- [Installing Helm](#installing-helm)
- [Adding a Helm Repository](#adding-a-helm-repository)
- [Searching for Charts](#searching-for-charts)
- [Installing a Chart](#installing-a-chart)
- [Listing Deployed Releases](#listing-deployed-releases)
- [Upgrading a Release](#upgrading-a-release)
- [Rolling Back a Release](#rolling-back-a-release)
- [Deleting a Release](#deleting-a-release)
- [Viewing Release History](#viewing-release-history)
- [Inspecting a Chart](#inspecting-a-chart)
- [Creating a Chart](#creating-a-chart)
- [Packaging a Chart](#packaging-a-chart)
- [Additional Resources](#additional-resources)

## Installing Helm

To install Helm, follow the Helm installation guide for your operating system:

- [Helm Installation Guide](https://helm.sh/docs/intro/install/)

## Adding a Helm Repository

To add a Helm repository, use the following command:

```bash
helm repo add repo_name repo_url
```

For example, to add the official Helm stable charts repository:

```bash
helm repo add stable https://charts.helm.sh/stable
```

## Searching for Charts

To search for available charts in a repository, use the following command:

```bash
helm search repo repo_name
```

For example, to search for charts in the stable repository:

```bash
helm search repo stable
```

## Installing a Chart

To install a chart from a repository, use the following command:

```bash
helm install release_name chart_name
```

For example, to install a chart named "myapp" from the stable repository:

```bash
helm install myapp stable/myapp
```

## Listing Deployed Releases

To list the releases deployed in your cluster, use the following command:

```bash
helm list
```

## Upgrading a Release

To upgrade a deployed release, use the following command:

```bash
helm upgrade release_name chart_name
```

For example, to upgrade a release named "myapp" with a new version of the chart:

```bash
helm upgrade myapp stable/myapp
```

## Rolling Back a Release

To roll back a release to a previous version, use the following command:

```bash
helm rollback release_name revision_number
```

For example, to roll back the release "myapp" to revision 2:

```bash
helm rollback myapp 2
```

## Deleting a Release

To delete a deployed release, use the following command:

```bash
helm uninstall release_name
```

For example, to delete a release named "myapp":

```bash
helm uninstall myapp
```

## Viewing Release History

To view the release history, including revisions, use the following command:

```bash
helm history release_name
```

For example, to view the history of a release named "myapp":

```bash
helm history myapp
```

## Inspecting a Chart

To inspect the details of a chart without installing it, use the following command:

```bash
helm show chart chart_name
```

For example, to inspect the details of a chart named "myapp":

```bash
helm show chart stable/myapp
```

## Creating a Chart

To create a new chart structure, use the following command:

```bash
helm create chart_name
```

For example, to create a