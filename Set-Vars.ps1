Write-Host "Signing into tenant..."
az login --tenant 66be6fbb-690d-4140-badf-30e376f34f5a

Write-Host "Retrieving keyvault secrets as env vars..."
$ncUser = (az keyvault secret show --vault-name ohiakvprod --name namecheap-username) | ConvertFrom-Json
$ncApiUser = (az keyvault secret show --vault-name ohiakvprod --name namecheap-api-user) | ConvertFrom-Json
$ncApiKey = (az keyvault secret show --vault-name ohiakvprod --name namecheap-api-key) | ConvertFrom-Json

$env:NAMECHEAP_USER_NAME = $ncUser.value
$env:NAMECHEAP_API_USER = $ncApiUser.value
$env:NAMECHEAP_API_KEY = $ncApiKey.value

Write-Host "Retireving Cloudflare secrets..."
$cfApiKey= (az keyvault secret show --vault-name ohiakvprod --name cloudflare-apiKey) | ConvertFrom-Json
$cfEmail= (az keyvault secret show --vault-name ohiakvprod --name cloudflare-email) | ConvertFrom-Json
$cfTfToken = (az keyvault secret show --vault-name ohiakvprod --name cloudflare-tf-token) | ConvertFrom-Json

$env:CLOUDLFARE_API_KEY = $cfApiKey.value
$env:CLOUDFLARE_EMAIL = $cfEmail.value
$env:CLOUDFLARE_API_TOKEN = $cfTfToken.value

Write-Host "Getting kube cluster credentials..."
az aks get-credentials --resource-group pcloud_ohia_prod --name ohia

Write-Host "Done! :D"