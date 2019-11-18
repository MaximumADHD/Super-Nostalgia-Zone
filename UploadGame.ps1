$confirmation = Read-Host "Are you sure you want to update Super Nostalgia Zone? (y/n)"

if ($confirmation -eq 'y') 
{
    echo "Grabbing cookie..."
    
    $regKey = "HKCU:\Software\Roblox\RobloxStudioBrowser\roblox.com"
    $regVal = Get-ItemPropertyValue -Path $regKey -Name ".ROBLOSECURITY"
    $cookie = [regex]::Match($regVal, "COOK::<([^>]*)>") | % { $_.Groups[1].Value }
    
    echo "Uploading core..."
    rojo upload --asset_id 1011800466 --cookie $cookie core.project.json
    
    echo "Uploading shared..."
    rojo upload --asset_id 1027421176 --cookie $cookie shared.project.json
    
    echo "Finished!"
}