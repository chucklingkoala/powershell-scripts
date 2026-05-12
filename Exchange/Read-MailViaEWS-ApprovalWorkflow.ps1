# Description: Polls a mailbox for approval emails matching a subject pattern, moves them to Yes/No
#              folders, and records the result to SQL Server. Useful for email-based approval workflows.
# Requirements: EWS Managed API DLL, SQL Server with an appropriate table or stored procedure
param(
    [string]$MailboxAddress = 'approvals@domain.local',
    [string]$EWSDllPath     = 'C:\EWS\Microsoft.Exchange.WebServices.dll',
    [string]$SearchSubject  = 'Approval required',
    [string]$YesFolder      = '/Inbox/Approved',
    [string]$NoFolder       = '/Inbox/Declined',
    [string]$SQLServer      = 'sqlserver.domain.local',
    [string]$SQLDatabase    = 'Approvals',
    [string]$SQLTable       = 'EmailApprovals',
    [bool]$WriteToSQL       = $true
)

[void][Reflection.Assembly]::LoadFile($EWSDllPath)

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$service.UseDefaultCredentials = $true
$service.AutodiscoverUrl($MailboxAddress, { $true })

$SQLConn = New-Object System.Data.SqlClient.SqlConnection
$SQLConn.ConnectionString = "Server=$SQLServer;Database=$SQLDatabase;Integrated Security=True;Connect Timeout=0"

$propSet = New-Object Microsoft.Exchange.WebServices.Data.PropertySet(
    [Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties
)
$propSet.RequestedBodyType = [Microsoft.Exchange.WebServices.Data.BodyType]::Text

$ibInbox   = New-Object Microsoft.Exchange.WebServices.Data.FolderId(
    [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox, $MailboxAddress
)
$ItemView  = New-Object Microsoft.Exchange.WebServices.Data.ItemView(100)

function Get-EWSFolder {
    param($Service, $MailboxAddress, [string]$FolderPath)
    $RootId = New-Object Microsoft.Exchange.WebServices.Data.FolderId(
        [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot, $MailboxAddress
    )
    $Current = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($Service, $RootId)
    foreach ($Part in ($FolderPath.Split('/') | Where-Object { $_ })) {
        $View   = New-Object Microsoft.Exchange.WebServices.Data.FolderView(1)
        $Filter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo(
            [Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName, $Part
        )
        $Found = $Service.FindFolders($Current.Id, $Filter, $View)
        if ($Found.TotalCount -gt 0) { $Current = $Found.Folders[0] } else { return $null }
    }
    return $Current
}

do {
    $fiItems = $service.FindItems($ibInbox, $SearchSubject, $ItemView)
    $ItemView.Offset += $fiItems.Items.Count

    foreach ($Item in $fiItems.Items) {
        $Item.Load($propSet)
        $Response    = $Item.Body.Text.Substring(0, [Math]::Min(10, $Item.Body.Text.Length)).Trim()
        $EmailFrom   = $Item.From.Address
        $RcvDate     = $Item.DateTimeReceived.ToString('yyyy-MM-dd HH:mm:ss')

        $TargetPath  = if ($Response -match '^(Yes|Approve)') { $YesFolder } else { $NoFolder }
        $TargetFolder = Get-EWSFolder -Service $service -MailboxAddress $MailboxAddress -FolderPath $TargetPath

        if ($WriteToSQL -and $TargetFolder) {
            $SQLConn.Open()
            $Cmd = $SQLConn.CreateCommand()
            $Cmd.CommandText = "INSERT INTO $SQLTable (ReceivedDate, SenderAddress, Response) VALUES ('$RcvDate', '$EmailFrom', '$Response')"
            $Cmd.ExecuteNonQuery() | Out-Null
            $SQLConn.Close()
        }

        $Item.IsRead = $true
        $Item.Update([Microsoft.Exchange.WebServices.Data.ConflictResolutionMode]::AlwaysOverwrite)
        if ($TargetFolder) { [void]$Item.Move($TargetFolder.Id) }
    }
} while ($fiItems.MoreAvailable)
