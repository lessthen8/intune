# Check for dependencies and install them if they are not found
$dependencies = @("Az.Accounts", "Az.Consumption")
foreach ($dependency in $dependencies) {
    if (-not (Get-Module -Name $dependency -ListAvailable)) {
        Write-Host "Installing $dependency module..."
        Install-Module -Name $dependency -Scope CurrentUser -Force
    }
}

# Connect to Azure
Connect-AzAccount

# Get all subscriptions in the tenant
$subscriptions = Get-AzSubscription

# Create an array to hold the subscription details
$subscriptionDetailsArray = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Select the current subscription
    Set-AzContext -Subscription $subscription.Id

    # Get the subscription details
    $subscriptionDetails = Get-AzSubscription

    # Get the subscription owners and classic administrators
    $owners = Get-AzRoleAssignment -Scope "/subscriptions/$($subscription.Id)" -RoleDefinitionName "Owner"
    $classicAdmins = Get-AzureRmRoleAssignment -Scope "/subscriptions/$($subscription.Id)" -RoleDefinitionName "Classic Administrator"

    # Get the cost in the past 30 days
    $startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
    $endDate = (Get-Date).ToString("yyyy-MM-dd")
    $cost = Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $endDate -BillingPeriodName "default" | Measure-Object -Property PretaxCost -Sum | Select-Object -ExpandProperty Sum

    # Create a custom object to hold the subscription details, owners, classic administrators, and cost in the past 30 days
    $subscriptionObject = New-Object PSObject
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription Name" -Value $subscriptionDetails.Name
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription ID" -Value $subscriptionDetails.Id
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription State" -Value $subscriptionDetails.State
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription Owners" -Value ($owners | ForEach-Object { "$($_.DisplayName) ($($_.SignInName))" })
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription Classic Administrators" -Value ($classicAdmins | ForEach-Object { "$($_.DisplayName) ($($_.SignInName))" })
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Cost in past 30 days" -Value $cost

    # Add the subscription object to the array
    $subscriptionDetailsArray += $subscriptionObject
}

# Export the subscription details array to a CSV file
$subscriptionDetailsArray | Export-Csv -Path "SubscriptionDetails.csv" -NoTypeInformation

# Display a message indicating the export was successful
Write-Host "Subscription details exported to SubscriptionDetails.csv."
