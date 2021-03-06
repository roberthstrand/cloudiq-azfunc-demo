# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

Connect-CloudiQ

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.

# CheckNumSubscriptions.ps1
# Minimize overspending by removing subscriptions
# that are not in use.

Import-Module -Name ($PSScriptRoot + "\AzureAD.Standard.Preview\0.1.599.7\AzureAD.Standard.Preview.psd1") -Force -ErrorAction Stop

Connect-AzAccount -Tenant $Env:tenantid -ApplicationId $Env:

. ($PSScriptRoot + "\ServicePlanSku.ps1")

$tenant = Get-AzureADTenantDetail | Select-Object -ExpandProperty ObjectId

$CIQSubs = Get-CloudiQSubscription | Where-Object { $_.Product -ne 'CSP Demo Services' } | Select-Object Product, SubscriptionId, Quantity

$CIQSubs | ForEach-Object {
    # Get the correct SKU for the subscription.
    $Sku = Get-Sku |
    Where-Object -Property Name -eq $_.Product |
    Select-Object -ExpandProperty Sku
    # Get the consumed units from Azure AD
    # with the ObjectId, combination of
    # tenant and product GUID.
    $consumedUnits = Get-AzureADSubscribedSku -ObjectId ($tenant + "_" + $Sku) |
    Select-Object -ExpandProperty ConsumedUnits

    [PSCustomObject]@{
        Product         = $_.Product
        SKU             = $Sku
        SubscribedUnits = $_.Quantity
        ConsumedUnits   = $consumedUnits
    }
    # If consumed units is less then subscribed units, set the quantity of licenses to what is consumed
    if ($consumedUnits -lt $SubscribedUnits) {
        Set-CloudiQSubscription -SubscriptionId $SubscriptionId -Quantity $Consumed
    }
}


# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
