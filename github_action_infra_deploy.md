# GitHub Action Deployment - Infra

You can deploy infra and dashboard using GitHub action, but first you need to setup credentials and secrets. Using Cloud Shell or Azure CLI, login to Azure, set the Azure context and execute the following commands to generate the required credentials:

Azure CLI:

```bash
# Replace {service-principal-name} and {subscription-id} with your
# Azure subscription id and any name for your service principal.
az ad sp create-for-rbac \
  --name "{service-principal-name}" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}" \
  --sdk-auth
```

This will generate the following JSON output ( You need this info for next step):

```json
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  (...)
}
```

## Adding Secrets to GitHub repository

Add the JSON output as a [repository secret](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository) with the name `AZURE_CREDENTIALS` in your GitHub repository:

![GitHub Secrets](/docs/images/AzureCredentialsGH.png)

To do so, execute the following steps:

1. On GitHub, navigate to the main page of the repository.
2. Under your repository name, click on the **Settings** tab.
3. In the left sidebar, click **Secrets**.
4. Click **New repository secret**.
5. Type the name `AZURE_CREDENTIALS` for your secret in the Name input box.
6. Enter the JSON output from above as value for your secret.
7. Click **Add secret**.

## Update Parameters for IaC template

In order to deploy the Infrastructure as Code (IaC) templates to the desired Azure subscription, you will need to modify some parameters in the forked repository. Therefore, **this step should not be skipped for neither Azure DevOps/GitHub options**. There are two files that require updates:

- `.github/workflows/infra-deploy.yml` and
- `infra/params.dev.json`.

Update these files in a separate branch and then merge via Pull Request to trigger the initial deployment.

### Configure `infra-deploy.yml`

In this file you need to update the environment variables section. Just click on [.github/workflows/infra-deploy.yml](/.github/workflows/infra-deploy.yml) and edit the following section:

```yaml
env:
  AZURE_SUBSCRIPTION_ID: "7c1d967f-37f1-4047-bef7-05af9aa80fe2" # Update to your subscription id
  AZURE_LOCATION: "southeastasia" # Update to location you want to deploy to
```

The following table explains each of the parameters:

| Parameter                 | Description                                                                                                                                         | Sample value                                                          |
| :------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- |
| **AZURE_SUBSCRIPTION_ID** | Specifies the subscription ID of the Data Landing Zone where all the resources will be deployed                                                     | <div style="width: 36ch">`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`</div> |
| **AZURE_LOCATION**        | Specifies the region where you want the resources to be deployed. Please check [Supported Regions](/docs/EnterpriseScaleAnalytics-Prerequisites.md) | `southeastasia`                                                       |

### Configure `params.dev.json`

In this file you need to update the variable values. Just click on [infra/params.dev.json](/infra/params.dev.json) and edit the values. An explanation of the values is given in the table below:

| Parameter        | Description                                                                                                      | Sample value           |
| :--------------- | :--------------------------------------------------------------------------------------------------------------- | :--------------------- |
| location         | Specifies the location for all resources.                                                                        | `southeastasia`        |
| environment      | Specifies the environment of the deployment.                                                                     | `dev`, `tst` or `prd`  |
| prefix           | Specifies the prefix for all resources created in this deployment.                                               | `ssatt`                |
| primaryRegion    | Specifies the primary region for Cosmos DB.                                                                      | `northeurope`          |
| secondaryRegion  | Specifies the secondary region for Cosmos DB.                                                                    | `westeurope`           |
| maxThroughput    | Specifies the max throughput you want to limit database to.                                                      | `4000`                 |
| partitionKey     | Specifies the partition key to be used for Gremlin database.                                                     | `accountId`            |
| databaseName     | Specifies name for cosmos database.                                                                              | `database01`           |
| graphName        | Specifies name for Gremlin collection.                                                                           | `graph01`              |
| clientIp         | Specifies the address space of the public subnet that is used for accessing Synapse workspace. (Change this ..!) | `0.0.0.0`              |
| sqlAdminPassword | Default password to use. (Change this ..! )                                                                      | `**ChangeMeNow1234!**` |

## Enable Workflow Actions

Enable workflow actions by navigating to Actions tab.

## Merge these changes back to the `main` branch of your repo

After following the instructions and updating the parameters and variables in your repository in a separate branch and opening the pull request, you can merge the pull request back into the `main` branch of your repository by clicking on **Merge pull request**. By doing this, you trigger the deployment workflow.

## Follow the workflow deployment

**Congratulations!** You have successfully executed all steps to deploy the template into your environment through GitHub Actions.

Now, you can navigate to the **Actions** tab of the main page of the repository, where you will see a workflow with the name `Deploy infra` running. Click on it to see how it deploys the environment.

>[Previous](/README.md)
>[Next (Deploy Dashboard)](/github_action_dashboard_deploy.md)