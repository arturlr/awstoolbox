###
# Visual Studio should publish a MSDEPLOY package to d:\phoursPkg dir
param (
  [Parameter(Mandatory=$true)][string]$stage,
  [string]$bucketname = "bucket"
)

if ($stage.ToLower() -eq "test" -or $stage.ToLower() -eq "prod") {
    $s3dir = "app-$stage".ToLower()
    $currentpath = (Get-Item -Path ".\" -Verbose).FullName
    Remove-Item "$currentpath\*.zip"
    $timer = (Get-Date -Format yyy-MMM-dd-hhmm)
    $filename = "phourspkg-$timer.zip"
    $zipfile = $currentpath + "\" + $filename
    $awskey = "AKIXXXXXXXXXXXXXXXXX"
    $awssecret = "dUXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

    Set-AWSCredentials -AccessKey $awskey -SecretKey $awssecret
    if (Test-Path $zipfile) {
      Remove-Item $zipfile
    }
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory("d:\phour-package", $zipfile)
    Set-DefaultAWSRegion us-east-1
    Write-S3Object -bucketname $bucketname -key $s3dir/$filename -File $zipfile
}
else {
   Write-Host "Stage can only be test or prod"
   exit 1
}
