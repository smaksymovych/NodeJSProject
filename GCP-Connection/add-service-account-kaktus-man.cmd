###  https://gist.github.com/palewire/12c4b2b974ef735d22da7493cf7f4d37


## creates a service account with Google
set PROJECT_ID=kaktus-cicd
set SERVICE_ACCOUNT=kaktus-service-account

gcloud iam service-accounts create %SERVICE_ACCOUNT% --project %PROJECT_ID%


## Enable Google's IAM API for use.
gcloud services enable iamcredentials.googleapis.com --project %PROJECT_ID%

# OUT:
# Operation "operations/acat.p2-1044927291290-7a0d4488-761a-4146-83f4-fec831ab119d" finished successfully.


## Create a workload identity pool that will manage that will manage the GitHub Action's roles in Google Cloud's permission system.
set WORKLOAD_IDENTITY_POOL=kaktus-pool

gcloud iam workload-identity-pools create %WORKLOAD_IDENTITY_POOL% --project=%PROJECT_ID% --location="global" --display-name=%WORKLOAD_IDENTITY_POOL%

# OUT:
# Created workload identity pool [kaktus-pool]



## Get the unique identifier of that pool
gcloud iam workload-identity-pools describe %WORKLOAD_IDENTITY_POOL% --project=%PROJECT_ID% --location="global" --format="value(name)"

#OUT: projects/1044927291290/locations/global/workloadIdentityPools/kaktus-pool



## Export the returned value to a new variable.

set WORKLOAD_IDENTITY_POOL_ID=projects/1044927291290/locations/global/workloadIdentityPools/kaktus-pool



## Create a provider within the pool for GitHub to access

set WORKLOAD_PROVIDER=kaktus-provider

gcloud iam workload-identity-pools providers create-oidc %WORKLOAD_PROVIDER% ^
--project=%PROJECT_ID% ^
--location="global" ^
--workload-identity-pool=%WORKLOAD_IDENTITY_POOL% ^
--display-name=%WORKLOAD_PROVIDER% ^
--attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" ^
--issuer-uri="https://token.actions.githubusercontent.com"

# OUT:
# Created workload identity pool provider [kaktus-provider].


## Allow a GitHub Action based in your repository to login to the service account via the provider.
set REPO=smaksymovych/NodeJSProject

gcloud iam service-accounts add-iam-policy-binding "%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" ^
--project=%PROJECT_ID% ^
--role="roles/iam.workloadIdentityUser" ^
--member="principalSet://iam.googleapis.com/%WORKLOAD_IDENTITY_POOL_ID%/attribute.repository/%REPO%"

# OUT:
# Updated IAM policy for serviceAccount [kaktus-service-account@kaktus-cicd.iam.gserviceaccount.com].
# bindings:
# - members:
#   - principalSet://iam.googleapis.com/projects/1044927291290/locations/global/workloadIdentityPools/kaktus-pool/attribute.repository/smaksymovych/NodeJSProject
#   role: roles/iam.workloadIdentityUser
# etag: BwXt6v0Pcqc=
# version: 1



##Ask Google to return the identifier of that provider.
gcloud iam workload-identity-pools providers describe %WORKLOAD_PROVIDER% ^
--project=%PROJECT_ID% ^
--location="global" ^
--workload-identity-pool=%WORKLOAD_IDENTITY_POOL% ^
--format="value(name)"

# OUT:
# projects/1044927291290/locations/global/workloadIdentityPools/kaktus-pool/providers/kaktus-provider


## Make sure that the service account we created at the start has permission to muck around with Google Artifact Registry.
gcloud projects add-iam-policy-binding %PROJECT_ID% ^
--member="serviceAccount:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" ^
--role="roles/artifactregistry.admin"

# OUT:
# Updated IAM policy for project [kaktus-cicd].
# bindings:
# - members:
#   - serviceAccount:kaktus-service-account@kaktus-cicd.iam.gserviceaccount.com
#   role: roles/artifactregistry.admin
# - members:
#   - user:maxsvg@gmail.com
#   role: roles/owner
# etag: BwXt6ww2IYk=
# version: 1


## To verify that worked, you can ask Google print out the permissions assigned to the service account.
gcloud projects get-iam-policy %PROJECT_ID% ^
--flatten="bindings[].members" ^
--format="table(bindings.role)" ^
--filter="bindings.members:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com"

# OUT:
# ROLE
# roles/artifactregistry.admin
#