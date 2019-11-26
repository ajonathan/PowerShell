function Copy-Files 
{
    <# 
        .DESCRIPTION
            Copy all files from a directory of one file to another destination

        .PARAMETER SourceFilePath
            Path to the files that are going to be copied
         
        .PARAMETER DestinationFilePath
            Path to the destination where the files are going to be copied

        .EXAMPLE
            Copy one file from source to destination
            Copy-Files -SourceFilePath "C:\temp\OneFile.doc" -DestinationFilePath "C:\Users\$UserName\AppData\Roaming"

            Copy all files from source to destination
            Copy-Files -SourceFilePath "\\server01\Doc$\NiceFiles" -DestinationFilePath "C:\Temp\Folder"
    #>

    Param
    (
        [Parameter(Mandatory=$True)]
        [String]$SourceFilePath,
        [Parameter(Mandatory=$True)]
        [String]$DestinationFilePath
    )
    Process
    {
        # Count files
        $FilesCount = (Get-ChildItem $SourceFilePath).count
        # If only one file is going to be copied
        If ($NULL -eq $FilesCount)
        {
             Copy-File -SourceFilePath $SourceFilePath -DestinationFilePath $DestinationFilePath
        }
        Else
        {
            # Get every file in a directory
            $files = Get-ChildItem -Recurse $SourceFilePath
            foreach ($file in $files)
            {
                $SourceFilePath = $file.FullName
                Copy-File -SourceFilePath "$SourceFilePath" -DestinationFilePath "$DestinationFilePath"
            }
        }
    }
}

# Copy one file to a destination
Function Copy-File
{
    <# 
        .DESCRIPTION
            Copy one file from a directory of one file to another destination

        .PARAMETER SourceFilePath
            Path to the file that are going to be copied
         
        .PARAMETER DestinationFilePath
            Path to the destination where the file are going to be copied

        .EXAMPLE
            Copy one file from source to destination
            Copy-Files -SourceFilePath "C:\temp\OneFile.doc" -DestinationFilePath "C:\Users\$UserName\AppData\Roaming"

            Copy all files from source to destination
            Copy-Files -SourceFilePath "\\server01\Doc$\NiceFiles" -DestinationFilePath "C:\Temp\Folder"
    #>
    Param
    (
        [Parameter(Mandatory=$True)]
        [String]$SourceFilePath,
        [Parameter(Mandatory=$True)]
        [String]$DestinationFilePath
    )
    Process
    {
        $SourceFilePathArray = $SourceFilePath.Split("\")
        $FileName = $SourceFilePathArray[$SourceFilePathArray.count - 1]
        $SourceFileInfo = Get-Item $SourceFilePath
        # Check if destination file already exist
        If (Test-Path "$DestinationFilePath\$FileName")
        {
            $DestinationFileInfo = Get-Item "$DestinationFilePath\$FileName"
            # Check if destination file is the same version as the new file
            If ($SourceFileInfo.LastWriteTime -ne $DestinationFileInfo.LastWriteTime)
            {
                Copy-Item -Recurse "$SourceFilePath" "$DestinationFilePath" -Force
            }
        }
        Else
        {
            # Check if path exist
            If ((Test-Path $DestinationFilePath) -eq $False)
            {
                # Create directories if not exist
                $Dir = ""
                $DestinationFilePathArray = $DestinationFilePath.Split("\")
                Foreach ($DestinationFilePathArrayS in $DestinationFilePathArray)
                {
                    If ($Dir -ne "")
                    {
                        $Dir = $Dir + "\$DestinationFilePathArrayS"
                    }
                    Else
                    {
                        [String]$Dir = "$DestinationFilePathArrayS"
                    }
                    # Create Directory if not exist
                    If ((Test-Path $Dir) -eq $False)
                    {
                        New-Item -ItemType directory -Path "$Dir"
                    }
                }
            }
            Copy-Item -Recurse "$SourceFilePath" "$DestinationFilePath" -Force
        }
    }
}

