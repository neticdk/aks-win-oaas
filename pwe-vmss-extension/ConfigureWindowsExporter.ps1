Configuration WindowsExporter
{
  $PWEPackageLocalPath = 'C:\PrometheusWindowsWxporter\windows_exporter.msi'
  $PWEVersion = '0.16.0'

  Import-DscResource -ModuleName xPSDesiredStateConfiguration

  Node localhost {

    xRemoteFile PWEPackage {
      Uri = "https://github.com/prometheus-community/windows_exporter/releases/download/v" + PWEVersion + "/windows_exporter-" + PWEVersion + "-amd64.msi"
      DestinationPath = $PWEPackageLocalPath
    }

    Package OMS {
      Ensure = "Present"
      Path  = $PWEPackageLocalPath
      Name = 'Prometheus Windows Exporter'
      ProductId = '36e88452-7df1-4054-99ae-e34d62e7147d'
      Arguments = 'LISTEN_PORT=9100 ENABLED_COLLECTORS=cpu,cs,container,logical_disk,memory,net,os,service,system,tcp'
      DependsOn = '[xRemoteFile]PWEPackage'
    }

  }

}
