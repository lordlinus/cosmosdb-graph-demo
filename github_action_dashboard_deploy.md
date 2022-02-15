# GitHub Action Deployment - Dashboard

You can deploy infra and dashboard using GitHub action, but first you need to setup credentials and secrets. Using Cloud Shell or Azure CLI, login to Azure, set the Azure context and execute the following commands to generate the required credentials:
NOTE: you can re-use the credentials from infra deployment step

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

## Update Parameters for dashboard

In order to deploy the dashboard to the desired Azure subscription, you will need to modify some parameters in the forked repository. Therefore, **this step should not be skipped for neither Azure DevOps/GitHub options**. There is one file that require updates:

- `.github/workflows/dashboard-deploy.yml`

Update this file in a separate branch and then merge via Pull Request to trigger the initial deployment.

### Configure `dashboard-deploy.yml`

In this file you need to update the environment variables section. Just click on [.github/workflows/dashboard-deploy.yml](/.github/workflows/dashboard-deploy.yml) and edit the following section:

```yaml
env:
  RESOURCE_GROUP: "ssatt-dev-rg" # Replace with your resource group name
  COSMOS_DB_NAME: "database01" # Replace with your Cosmos DB name
  COSMOS_GRAPH_COLLECTION: "graph01" # Replace with your Cosmos DB graph collection name
  SEARCH_SERVICE_NAME: "ebcbin5oofjcs" # Replace with your Search Service name
  AZURE_CONTAINER_REGISTRY: "ebcbin5oofjcs" # Replace with your Azure Container Registry name
  SEARCH_INDEX: "cosmosdb-index" # Replace with your Search Service index name
```

The following table explains each of the parameters:

| Parameter          | Description                                                                                                                                         | Sample value                                                          |
| :----------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- |
| **RESOURCE_GROUP** | Specifies the resource group name where cosmos, search are deployed. It is assumed that all the required resources are deplyed in a single resource group for demo                                                     | <div style="width: 36ch">`ssatt-dev-rg`</div> |
| **COSMOS_ACCOUNT_NAME** | Name of the Cosmos account | `ebcbin5oofjcs`                                                       |
| **COSMOS_DB_NAME** | Name of the Cosmos Database name | `database01`                                                       |
| **COSMOS_GRAPH_COLLECTION** | Name of the Cosmos Gremlin name | `graph01`        
| **SEARCH_SERVICE_NAME** | Name of the Azure Cognitive search | `ebcbin5oofjcs`
| **SEARCH_INDEX** | Name of the Cosmos search index in search service | `cosmosdb-index`        
| **AZURE_CONTAINER_REGISTRY** | Name of the container registry | `ebcbin5oofjcs`        

## Enable Workflow Actions

Enable workflow actions by navigating to Actions tab.

## Merge these changes back to the `main` branch of your repo

After following the instructions and updating the parameters and variables in your repository in a separate branch and opening the pull request, you can merge the pull request back into the `main` branch of your repository by clicking on **Merge pull request**. By doing this, you trigger the deployment workflow.

## Follow the workflow deployment

**Congratulations!** You have successfully executed all steps to deploy the dashboard into your environment through GitHub Actions.

Now, you can navigate to the **Actions** tab of the main page of the repository, where you will see a workflow with the name `Deploy dashboard` running. Click on it to see how it deploys the environment.

>[Previous](/README.md)
>[Next (Deploy Infra)](/github_action_infra_deploy.md)
