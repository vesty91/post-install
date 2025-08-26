<#
  DevSoftInstaller-GUI.ps1 (version complète avec JSON pack)
  Interface graphique WPF + téléchargement automatique depuis JSON
#>

param(
    [switch]$Quiet
)

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Configuration
$Config = @{
    OutDir = "C:\DevInstallers"
    LogDir = ".\logs"
    MaxConcurrentDownloads = 3
    AutoExtract = $true  # Décompression automatique des archives
    DeleteArchives = $false  # Supprimer les archives après décompression
}

# Créer les dossiers nécessaires
if (!(Test-Path $Config.OutDir)) {
    New-Item -ItemType Directory -Path $Config.OutDir -Force | Out-Null
}
if (!(Test-Path $Config.LogDir)) {
    New-Item -ItemType Directory -Path $Config.LogDir -Force | Out-Null
}

# Fonction de logging
function Write-Log {
    param($Message, $Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path "$($Config.LogDir)\installer_$(Get-Date -Format 'yyyyMMdd').log" -Value $LogMessage
}

# Fonction de génération de nom de fichier sécurisé
function Get-SafeFileName {
    param($Url, $PackageName)
    
    try {
        # Essayer d'extraire le nom de fichier de l'URL
        $Uri = [System.Uri]::new($Url)
        $PathSegments = $Uri.Segments
        $LastSegment = $PathSegments[-1]
        
        # Nettoyer le nom de fichier
        if ($LastSegment -and $LastSegment.Length -gt 0 -and $LastSegment -ne "/") {
            $FileName = $LastSegment.Split('?')[0]  # Enlever les paramètres de requête
            $FileName = $FileName.Split('#')[0]      # Enlever les fragments
            
            # Vérifier si le nom de fichier est valide
            if ($FileName -and $FileName.Length -gt 0 -and $FileName -ne "/") {
                # Ajouter une extension si nécessaire
                if ($FileName -notmatch '\.(exe|msi|zip|rar|7z|dmg|pkg|deb|rpm|appimage)$') {
                    $FileName = "$FileName.exe"
                }
                return $FileName
            }
        }
        
        # Fallback: utiliser le nom du package
        $SafeName = $PackageName -replace '[<>:"/\\|?*]', '_'
        $SafeName = $SafeName -replace '\s+', '_'
        return "$SafeName.exe"
        
    } catch {
        # En cas d'erreur, utiliser le nom du package
        $SafeName = $PackageName -replace '[<>:"/\\|?*]', '_'
        $SafeName = $SafeName -replace '\s+', '_'
        return "$SafeName.exe"
    }
}

# Fonction de téléchargement avec progression simulée
function Download-FileWithProgress {
    param($Url, $OutFile, $Package)
    
    try {
        # Simuler la progression pendant le téléchargement
        $Package.ProgressValue = 10
        $Package.ProgressText = "10%"
        $PackageListView.Items.Refresh()
        Start-Sleep -Milliseconds 100
        
        $Package.ProgressValue = 25
        $Package.ProgressText = "25%"
        $PackageListView.Items.Refresh()
        Start-Sleep -Milliseconds 100
        
        $Package.ProgressValue = 50
        $Package.ProgressText = "50%"
        $PackageListView.Items.Refresh()
        Start-Sleep -Milliseconds 100
        
        $Package.ProgressValue = 75
        $Package.ProgressText = "75%"
        $PackageListView.Items.Refresh()
        Start-Sleep -Milliseconds 100
        
        # Effectuer le téléchargement réel
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
        
        $Package.ProgressValue = 90
        $Package.ProgressText = "90%"
        $PackageListView.Items.Refresh()
        Start-Sleep -Milliseconds 100
        
        return $true
        
    } catch {
        Write-Log "Erreur lors du téléchargement: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction de décompression automatique des archives
function Extract-Archive {
    param($FilePath, $PackageName)
    
    try {
        $FileInfo = Get-Item $FilePath
        $Extension = $FileInfo.Extension.ToLower()
        $FileName = $FileInfo.BaseName
        $DirPath = $FileInfo.DirectoryName
        $ExtractPath = Join-Path $DirPath $FileName
        
        Write-Log "Décompression automatique de: $($FileInfo.Name)"
        
        switch ($Extension) {
            ".zip" {
                # Utiliser Expand-Archive natif de PowerShell
                Expand-Archive -Path $FilePath -DestinationPath $ExtractPath -Force
                Write-Log "Archive ZIP décompressée vers: $ExtractPath"
            }
            ".7z" {
                # Utiliser 7-Zip si disponible
                $7zPath = Get-Command "7z.exe" -ErrorAction SilentlyContinue
                if ($7zPath) {
                    & "7z.exe" x $FilePath "-o$ExtractPath" -y
                    Write-Log "Archive 7Z décompressée vers: $ExtractPath"
                } else {
                    Write-Log "7-Zip non trouvé, impossible de décompresser: $($FileInfo.Name)" "WARNING"
                    return $false
                }
            }
            ".rar" {
                # Utiliser 7-Zip pour les RAR si disponible
                $7zPath = Get-Command "7z.exe" -ErrorAction SilentlyContinue
                if ($7zPath) {
                    & "7z.exe" x $FilePath "-o$ExtractPath" -y
                    Write-Log "Archive RAR décompressée vers: $ExtractPath"
                } else {
                    Write-Log "7-Zip non trouvé, impossible de décompresser: $($FileInfo.Name)" "WARNING"
                    return $false
                }
            }
            ".tar.gz" {
                # Utiliser 7-Zip pour les TAR.GZ si disponible
                $7zPath = Get-Command "7z.exe" -ErrorAction SilentlyContinue
                if ($7zPath) {
                    & "7z.exe" x $FilePath "-o$ExtractPath" -y
                    Write-Log "Archive TAR.GZ décompressée vers: $ExtractPath"
                } else {
                    Write-Log "7-Zip non trouvé, impossible de décompresser: $($FileInfo.Name)" "WARNING"
                    return $false
                }
            }
            ".tgz" {
                # Utiliser 7-Zip pour les TGZ si disponible
                $7zPath = Get-Command "7z.exe" -ErrorAction SilentlyContinue
                if ($7zPath) {
                    & "7z.exe" x $FilePath "-o$ExtractPath" -y
                    Write-Log "Archive TGZ décompressée vers: $ExtractPath"
                } else {
                    Write-Log "7-Zip non trouvé, impossible de décompresser: $($FileInfo.Name)" "WARNING"
                    return $false
                }
            }
            default {
                Write-Log "Type d'archive non supporté: $Extension" "WARNING"
                return $false
            }
        }
        
        # Supprimer l'archive si configuré
        if ($Config.DeleteArchives) {
            Remove-Item $FilePath -Force
            Write-Log "Archive supprimée: $($FileInfo.Name)"
        }
        
        return $true
        
    } catch {
        Write-Log "Erreur lors de la décompression de $FilePath : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction de chargement du pack JSON
function Load-JsonPack {
    param($FilePath)
    
    try {
        $JsonContent = Get-Content $FilePath -Raw | ConvertFrom-Json
        Write-Log "Pack JSON chargé: $($JsonContent.packages.Count) packages trouvés"
        return $JsonContent
    } catch {
        Write-Log "Erreur lors du chargement du JSON: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Interface WPF
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DevSoftInstaller - Gestionnaire d'Installeurs" 
        Height="600" Width="800"
        WindowStartupLocation="CenterScreen"
        Background="#F0F0F0">
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="DevSoftInstaller" FontSize="24" FontWeight="Bold" 
                       HorizontalAlignment="Center" Margin="0,0,0,10"/>
            <TextBlock Text="Gestionnaire d'installeurs avec support JSON" 
                       FontSize="14" HorizontalAlignment="Center" Foreground="#666"/>
        </StackPanel>
        
        <!-- Main Content -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            
            <!-- Package List -->
            <GroupBox Grid.Column="0" Header="Packages disponibles" Margin="0,0,10,0">
                <ListView x:Name="PackageListView" Height="400">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Catégorie" Width="100" DisplayMemberBinding="{Binding cat}"/>
                            <GridViewColumn Header="Nom" Width="200" DisplayMemberBinding="{Binding name}"/>
                            <GridViewColumn Header="URL" Width="250" DisplayMemberBinding="{Binding url}"/>
                            <GridViewColumn Header="Statut" Width="120">
                                <GridViewColumn.CellTemplate>
                                    <DataTemplate>
                                        <StackPanel Orientation="Horizontal">
                                            <Ellipse Width="12" Height="12" Margin="0,0,8,0">
                                                <Ellipse.Fill>
                                                    <SolidColorBrush Color="{Binding StatusColor}"/>
                                                </Ellipse.Fill>
                                            </Ellipse>
                                            <TextBlock Text="{Binding StatusText}" FontSize="11" FontWeight="Bold"/>
                                        </StackPanel>
                                    </DataTemplate>
                                </GridViewColumn.CellTemplate>
                            </GridViewColumn>
                            <GridViewColumn Header="Progression" Width="150">
                                <GridViewColumn.CellTemplate>
                                    <DataTemplate>
                                        <StackPanel Orientation="Vertical" Margin="2">
                                            <ProgressBar Width="120" Height="12" 
                                                         Value="{Binding ProgressValue}" 
                                                         Maximum="100" 
                                                         Background="#E0E0E0" 
                                                         Foreground="#007ACC"/>
                                            <TextBlock Text="{Binding ProgressText}" 
                                                       FontSize="9" 
                                                       HorizontalAlignment="Center" 
                                                       Foreground="#666"/>
                                        </StackPanel>
                                    </DataTemplate>
                                </GridViewColumn.CellTemplate>
                            </GridViewColumn>
                        </GridView>
                    </ListView.View>
                </ListView>
            </GroupBox>
            
            <!-- Controls -->
            <StackPanel Grid.Column="1" Width="200" VerticalAlignment="Top">
                <Button x:Name="LoadJsonButton" Content="Charger Pack JSON" 
                        Height="40" Margin="0,0,0,10" Background="#007ACC" Foreground="White"/>
                <Button x:Name="DownloadAllButton" Content="Télécharger Tout" 
                        Height="40" Margin="0,0,0,10" Background="#28A745" Foreground="White"/>
                <Button x:Name="OpenFolderButton" Content="Ouvrir Dossier" 
                        Height="40" Margin="0,0,0,10" Background="#6C757D" Foreground="White"/>
                <Button x:Name="ClearLogsButton" Content="Nettoyer Logs" 
                        Height="40" Margin="0,0,0,10" Background="#DC3545" Foreground="White"/>
                <Button x:Name="RefreshButton" Content="🔄 Rafraîchir" 
                        Height="40" Margin="0,0,0,10" Background="#17A2B8" Foreground="White"/>
                
                <Separator Margin="0,20,0,20"/>
                
                <TextBlock Text="Configuration:" FontWeight="Bold" Margin="0,0,0,10"/>
                <TextBlock x:Name="ConfigText" Text="Dossier de sortie: C:\DevInstallers" 
                           TextWrapping="Wrap" FontSize="12"/>
                
                <CheckBox x:Name="AutoExtractCheckBox" Content="Décompression automatique" 
                          IsChecked="True" Margin="0,10,0,5"/>
                <CheckBox x:Name="DeleteArchivesCheckBox" Content="Supprimer archives après décompression" 
                          IsChecked="False" Margin="0,0,0,10"/>
                
                <Separator Margin="0,10,0,10"/>
                
                <TextBlock Text="Statistiques:" FontWeight="Bold" Margin="0,0,0,10"/>
                <TextBlock x:Name="StatsText" Text="Aucun pack chargé" 
                           TextWrapping="Wrap" FontSize="11" Foreground="#666"/>
                
                <Separator Margin="0,20,0,20"/>
                
                <TextBlock Text="Progression Globale:" FontWeight="Bold" Margin="0,0,0,5"/>
                <ProgressBar x:Name="GlobalProgress" Height="20" Margin="0,0,0,5"/>
                <TextBlock x:Name="GlobalProgressText" Text="0 / 0 packages" 
                           HorizontalAlignment="Center" FontSize="10" Foreground="#666"/>
                
                <Separator Margin="0,10,0,10"/>
                
                <TextBlock x:Name="StatusText" Text="Prêt" HorizontalAlignment="Center"/>
            </StackPanel>
        </Grid>
        
        <!-- Footer -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,20,0,0">
            <TextBlock Text="Logs: " VerticalAlignment="Center"/>
            <TextBlock x:Name="LogPathText" Text=".\logs\" VerticalAlignment="Center" 
                       Foreground="#007ACC" TextDecorations="Underline" Cursor="Hand"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Charger l'interface
$Reader = [System.Xml.XmlNodeReader]::New([xml]$Xaml)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Récupérer les contrôles
$PackageListView = $Window.FindName("PackageListView")
$LoadJsonButton = $Window.FindName("LoadJsonButton")
$DownloadAllButton = $Window.FindName("DownloadAllButton")
$OpenFolderButton = $Window.FindName("OpenFolderButton")
$ClearLogsButton = $Window.FindName("ClearLogsButton")
$RefreshButton = $Window.FindName("RefreshButton")
$GlobalProgress = $Window.FindName("GlobalProgress")
$GlobalProgressText = $Window.FindName("GlobalProgressText")
$StatusText = $Window.FindName("StatusText")
$ConfigText = $Window.FindName("ConfigText")
$StatsText = $Window.FindName("StatsText")
$LogPathText = $Window.FindName("LogPathText")
$AutoExtractCheckBox = $Window.FindName("AutoExtractCheckBox")
$DeleteArchivesCheckBox = $Window.FindName("DeleteArchivesCheckBox")

# Variables globales
$Global:Packages = @()

# Fonction pour rafraîchir l'état des packages
function Update-PackageStatus {
    if ($Global:Packages.Count -gt 0) {
        $DownloadedCount = 0
        $PendingCount = 0
        $ErrorCount = 0
        $TotalSize = 0
        
        foreach ($Package in $Global:Packages) {
            if ($Package.OutFile) {
                $FileExists = Test-Path $Package.OutFile
                $FileSize = if ($FileExists) { (Get-Item $Package.OutFile).Length } else { 0 }
                
                if ($FileExists -and $FileSize -gt 0) {
                    $Package.status = "Téléchargé"
                    $Package.StatusColor = "Green"
                    $Package.StatusText = "✓ Téléchargé"
                    $Package.FileExists = $true
                    $Package.FileSize = $FileSize
                    $DownloadedCount++
                    $TotalSize += $FileSize
                } else {
                    $Package.status = "En attente"
                    $Package.StatusColor = "Orange"
                    $Package.StatusText = "⏳ En attente"
                    $Package.FileExists = $false
                    $Package.FileSize = 0
                    $PendingCount++
                }
            }
        }
        
        # Mettre à jour les statistiques
        $StatsText.Text = "Téléchargés: $DownloadedCount`nEn attente: $PendingCount`nTaille totale: $([math]::Round($TotalSize/1MB, 2)) MB"
        
        $PackageListView.Items.Refresh()
    }
}

# Événements des boutons
$LoadJsonButton.Add_Click({
    $FileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $FileDialog.Filter = "Fichiers JSON (*.json)|*.json|Tous les fichiers (*.*)|*.*"
    $FileDialog.Title = "Sélectionner le pack JSON"
    
    if ($FileDialog.ShowDialog()) {
        $JsonPack = Load-JsonPack $FileDialog.FileName
        if ($JsonPack) {
            $Global:Packages = $JsonPack.packages | ForEach-Object {
                # Vérifier si le fichier existe déjà
                $FileName = Get-SafeFileName -Url $_.url -PackageName $_.name
                $OutFile = Join-Path $Config.OutDir $FileName
                $FileExists = Test-Path $OutFile
                $FileSize = if ($FileExists) { (Get-Item $OutFile).Length } else { 0 }
                
                # Déterminer le statut
                if ($FileExists -and $FileSize -gt 0) {
                    $Status = "Téléchargé"
                    $StatusColor = "Green"
                    $PackageStatusText = "✓ Téléchargé"
                } else {
                    $Status = "En attente"
                    $StatusColor = "Orange"
                    $PackageStatusText = "⏳ En attente"
                }
                
                $_ | Add-Member -NotePropertyName "status" -NotePropertyValue $Status -PassThru |
                Add-Member -NotePropertyName "StatusColor" -NotePropertyValue $StatusColor -PassThru |
                Add-Member -NotePropertyName "StatusText" -NotePropertyValue $PackageStatusText -PassThru |
                Add-Member -NotePropertyName "FileExists" -NotePropertyValue $FileExists -PassThru |
                Add-Member -NotePropertyName "FileSize" -NotePropertyValue $FileSize -PassThru |
                Add-Member -NotePropertyName "OutFile" -NotePropertyValue $OutFile -PassThru |
                Add-Member -NotePropertyName "ProgressValue" -NotePropertyValue 0 -PassThru |
                Add-Member -NotePropertyName "ProgressText" -NotePropertyValue "0%" -PassThru
            }
            
            $PackageListView.ItemsSource = $Global:Packages
            $StatusText.Text = "Pack JSON chargé: $($Global:Packages.Count) packages trouvés"
            Write-Log "Pack JSON chargé: $($FileDialog.FileName)"
        }
    }
})

$DownloadAllButton.Add_Click({
    if ($Global:Packages.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Veuillez d'abord charger un pack JSON", "Information")
        return
    }
    
    $EnabledPackages = $Global:Packages | Where-Object { $_.enabled -eq $true }
    if ($EnabledPackages.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun package activé dans le pack JSON", "Information")
        return
    }
    
    $StatusText.Text = "Démarrage des téléchargements..."
    $GlobalProgress.Maximum = $EnabledPackages.Count
    $GlobalProgress.Value = 0
    $GlobalProgressText.Text = "0 / $($EnabledPackages.Count) packages"
    
    # Téléchargement synchrone simple
    $SuccessCount = 0
    $ErrorCount = 0
    
    foreach ($Package in $EnabledPackages) {
        try {
            $FileName = Get-SafeFileName -Url $Package.url -PackageName $Package.name
            $OutFile = Join-Path $Config.OutDir $FileName
            
            $StatusText.Text = "Téléchargement de $($Package.name)..."
            $GlobalProgress.Value++
            $GlobalProgressText.Text = "$($GlobalProgress.Value) / $($EnabledPackages.Count) packages"
            
            # Initialiser la progression
            $Package.ProgressValue = 0
            $Package.ProgressText = "0%"
            $PackageListView.Items.Refresh()
            
            # Téléchargement avec barre de progression
            if (Download-FileWithProgress -Url $Package.url -OutFile $OutFile -Package $Package) {
                # Mettre à jour la progression à 100%
                $Package.ProgressValue = 100
                $Package.ProgressText = "100%"
                $PackageListView.Items.Refresh()
            } else {
                throw "Échec du téléchargement"
            }
            
            # Vérifier le fichier téléchargé
            $FileSize = (Get-Item $OutFile).Length
            if ($FileSize -gt 0) {
                $Package.status = "Téléchargé"
                $Package.StatusColor = "Green"
                $Package.StatusText = "✓ Téléchargé"
                $Package.FileExists = $true
                $Package.FileSize = $FileSize
                $Package.OutFile = $OutFile
                $SuccessCount++
                Write-Log "Téléchargement réussi: $($Package.name)"
                
                # Décompression automatique si activée
                if ($Config.AutoExtract) {
                    $Extension = (Get-Item $OutFile).Extension.ToLower()
                    if ($Extension -match '\.(zip|7z|rar|tar\.gz|tgz)$') {
                        $StatusText.Text = "Décompression automatique de $($Package.name)..."
                        Write-Log "Démarrage de la décompression automatique pour: $($Package.name)"
                        
                        if (Extract-Archive -FilePath $OutFile -PackageName $Package.name) {
                            $Package.StatusText = "✓ Téléchargé + Décompressé"
                            Write-Log "Décompression réussie pour: $($Package.name)"
                        } else {
                            $Package.StatusText = "✓ Téléchargé (Décompression échouée)"
                            Write-Log "Décompression échouée pour: $($Package.name)" "WARNING"
                        }
                    }
                }
            } else {
                $Package.status = "Erreur"
                $Package.StatusColor = "Red"
                $Package.StatusText = "❌ Erreur"
                $ErrorCount++
                Write-Log "Fichier vide téléchargé: $($Package.name)" "ERROR"
            }
            
        } catch {
            $Package.status = "Erreur"
            $Package.StatusColor = "Red"
            $Package.StatusText = "❌ Erreur"
            $ErrorCount++
            Write-Log "Erreur lors du téléchargement de $($Package.name): $($_.Exception.Message)" "ERROR"
        }
        
        $PackageListView.Items.Refresh()
    }
    
    $GlobalProgress.Value = $GlobalProgress.Maximum
    $StatusText.Text = "Téléchargements terminés"
    
    $Message = "Téléchargements terminés !`n`nSuccès: $SuccessCount`nErreurs: $ErrorCount"
    [System.Windows.MessageBox]::Show($Message, "Résultats")
    
    # Mettre à jour les statistiques
    Update-PackageStatus
})

$OpenFolderButton.Add_Click({
    if (Test-Path $Config.OutDir) {
        Start-Process "explorer.exe" -ArgumentList $Config.OutDir
    } else {
        [System.Windows.MessageBox]::Show("Le dossier de sortie n'existe pas encore", "Information")
    }
})

$ClearLogsButton.Add_Click({
    try {
        Get-ChildItem $Config.LogDir -Filter "*.log" | Remove-Item -Force
        Write-Log "Logs nettoyés"
        [System.Windows.MessageBox]::Show("Logs nettoyés avec succès", "Information")
    } catch {
        Write-Log "Erreur lors du nettoyage des logs: $($_.Exception.Message)" "ERROR"
        [System.Windows.MessageBox]::Show("Erreur lors du nettoyage des logs", "Erreur")
    }
})

$RefreshButton.Add_Click({
    Update-PackageStatus
    $StatusText.Text = "État des packages rafraîchi"
    Write-Log "État des packages rafraîchi"
})

# Événements de configuration
$AutoExtractCheckBox.Add_Checked({
    $Config.AutoExtract = $true
    Write-Log "Décompression automatique activée"
})

$AutoExtractCheckBox.Add_Unchecked({
    $Config.AutoExtract = $false
    Write-Log "Décompression automatique désactivée"
})

$DeleteArchivesCheckBox.Add_Checked({
    $Config.DeleteArchives = $true
    Write-Log "Suppression des archives activée"
})

$DeleteArchivesCheckBox.Add_Unchecked({
    $Config.DeleteArchives = $false
    Write-Log "Suppression des archives désactivée"
})

$LogPathText.Add_MouseLeftButtonDown({
    if (Test-Path $Config.LogDir) {
        Start-Process "explorer.exe" -ArgumentList $Config.LogDir
    }
})

# Mise à jour de l'interface
$ConfigText.Text = "Dossier de sortie: $($Config.OutDir)`nDossier de logs: $($Config.LogDir)`nDécompression auto: $($Config.AutoExtract)`nSuppression archives: $($Config.DeleteArchives)"
$StatusText.Text = "Prêt - Chargez un pack JSON"

# Mode silencieux
if ($Quiet) {
    Write-Log "Mode silencieux activé"
    $JsonPack = Load-JsonPack ".\dev_installers_pack.json"
    if ($JsonPack) {
        $Global:Packages = $JsonPack.packages | Where-Object { $_.enabled -eq $true }
        Write-Log "Pack JSON chargé automatiquement: $($Global:Packages.Count) packages"
        
        foreach ($Package in $Global:Packages) {
            $FileName = Get-SafeFileName -Url $Package.url -PackageName $Package.name
            $OutFile = Join-Path $Config.OutDir $FileName
            Write-Log "Téléchargement de $($Package.name) vers $OutFile"
            
            try {
                Invoke-WebRequest -Uri $Package.url -OutFile $OutFile
                Write-Log "Téléchargement terminé: $OutFile"
                
                # Décompression automatique si activée
                if ($Config.AutoExtract) {
                    $Extension = (Get-Item $OutFile).Extension.ToLower()
                    if ($Extension -match '\.(zip|7z|rar|tar\.gz|tgz)$') {
                        Write-Log "Démarrage de la décompression automatique pour: $($Package.name)"
                        if (Extract-Archive -FilePath $OutFile -PackageName $Package.name) {
                            Write-Log "Décompression réussie pour: $($Package.name)"
                        } else {
                            Write-Log "Décompression échouée pour: $($Package.name)" "WARNING"
                        }
                    }
                }
            } catch {
                Write-Log "Erreur lors du téléchargement de $($Package.name): $($_.Exception.Message)" "ERROR"
            }
        }
        
        Write-Log "Traitement en mode silencieux terminé"
        exit 0
    }
}

# Afficher la fenêtre
Write-Log "Interface DevSoftInstaller démarrée"
$Window.ShowDialog()
Write-Log "Interface DevSoftInstaller fermée"
