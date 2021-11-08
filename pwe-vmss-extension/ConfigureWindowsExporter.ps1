Configuration WindowsExporter
{
  $PWEPackageLocalPath = 'C:\Windows\Temp\windows_exporter.msi'
  $PWEVersion = '0.16.0'

  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName xPSDesiredStateConfiguration

  Node localhost {

    xRemoteFile PWEPackage {
      Uri = "https://github.com/prometheus-community/windows_exporter/releases/download/v" + $PWEVersion + "/windows_exporter-" + $PWEVersion + "-amd64.msi"
      DestinationPath = $PWEPackageLocalPath
    }

    Package PWE {
      Ensure = "Present"
      Path  = $PWEPackageLocalPath
      Name = 'windows_exporter'
      ProductId = 'D6F05276-350B-4E3B-A608-19D8B00A8396'
      Arguments = 'LISTEN_PORT=9100 ENABLED_COLLECTORS=cpu,cs,container,logical_disk,memory,net,os,service,system,tcp'
      DependsOn = '[xRemoteFile]PWEPackage'
    }

  }

}
