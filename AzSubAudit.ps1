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

    # Create a custom object to hold the subscription details, owners, and classic administrators
    $subscriptionObject = New-Object PSObject
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription Name" -Value $subscriptionDetails.Name
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription ID" -Value $subscriptionDetails.Id
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription State" -Value $subscriptionDetails.State
    $ownersString = ""
    foreach ($owner in $owners) {
        $ownersString += "$($owner.DisplayName) ($($owner.SignInName)); "
    }
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription Owners" -Value $ownersString
    $classicAdminsString = ""
    foreach ($classicAdmin in $classicAdmins) {
        $classicAdminsString += "$($classicAdmin.DisplayName) ($($classicAdmin.SignInName)); "
    }
    $subscriptionObject | Add-Member -MemberType NoteProperty -Name "Subscription Classic Administrators" -Value $classicAdminsString

    # Add the subscription object to the array
    $subscriptionDetailsArray += $subscriptionObject
}

# Export the subscription details array to a CSV file
$subscriptionDetailsArray | Export-Csv -Path "SubscriptionDetails.csv" -NoTypeInformation

# Display a message indicating the export was successful
Write-Host "Subscription details exported to SubscriptionDetails.csv."
