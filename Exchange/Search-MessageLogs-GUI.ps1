# Description: GUI tool for searching Exchange message tracking logs by sender, recipient, subject,
#              date range, and event ID. Results can be exported to CSV or emailed.
# Requirements: Exchange Management Shell
# Author: Nicolas PRIGENT (www.get-cmd.com) — enhanced from original gallery script
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

function GenerateForm {
    [reflection.assembly]::loadwithpartialname('System.Drawing')    | Out-Null
    [reflection.assembly]::loadwithpartialname('System.Windows.Forms') | Out-Null

    $formTrackLog          = New-Object System.Windows.Forms.Form
    $labEventID            = New-Object System.Windows.Forms.Label
    $comboBoxEventID       = New-Object System.Windows.Forms.ComboBox
    $labEndDate            = New-Object System.Windows.Forms.Label
    $labStartDate          = New-Object System.Windows.Forms.Label
    $labFrom               = New-Object System.Windows.Forms.Label
    $dgResults             = New-Object System.Windows.Forms.DataGrid
    $dateTimePickerEnd     = New-Object System.Windows.Forms.DateTimePicker
    $dateTimePickerStart   = New-Object System.Windows.Forms.DateTimePicker
    $txtBoxRecipients      = New-Object System.Windows.Forms.TextBox
    $txtBoxSenders         = New-Object System.Windows.Forms.TextBox
    $buttonGo              = New-Object System.Windows.Forms.Button
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    $labTo                 = New-Object System.Windows.Forms.Label
    $labSubject            = New-Object System.Windows.Forms.Label
    $txtBoxSubject         = New-Object System.Windows.Forms.TextBox
    $txtBoxMail            = New-Object System.Windows.Forms.TextBox
    $txtBoxCSV             = New-Object System.Windows.Forms.TextBox
    $chkBoxCSV             = New-Object System.Windows.Forms.CheckBox
    $chkBoxMail            = New-Object System.Windows.Forms.CheckBox
    $txtBoxFromMail        = New-Object System.Windows.Forms.TextBox
    $txtBoxToMail          = New-Object System.Windows.Forms.TextBox

    $processData = {
        $array  = New-Object System.Collections.ArrayList
        $date3  = [System.DateTime](Get-Date -Date $dateTimePickerStart.Value -UFormat '%m/%d/%Y 00:00:01')
        $date4  = [System.DateTime](Get-Date -Date $dateTimePickerEnd.Value   -UFormat '%m/%d/%Y 23:59:59')
        $Sort   = 'TimeStamp'

        $ValidIDs = 'BADMAIL','DEFER','DELIVER','SEND','DSN','FAIL','POISONMESSAGE','RECEIVE','REDIRECT','RESOLVE','SUBMIT','TRANSFER','EXPAND'
        $EventID  = if ($ChoiceEventID -in $ValidIDs) { $ChoiceEventID } else { '' }

        $Params = @{ Start = $date3; End = $date4; ResultSize = 'Unlimited' }
        if ($EventID)                      { $Params.EventID        = $EventID }
        if ($txtBoxSenders.Text)           { $Params.Sender         = $txtBoxSenders.Text }
        if ($txtBoxRecipients.Text)        { $Params.Recipients     = $txtBoxRecipients.Text }
        if ($txtBoxSubject.Text)           { $Params.MessageSubject = $txtBoxSubject.Text }

        $ausgabe = Get-MessageTrackingLog @Params |
            Select-Object Timestamp, Sender,
                @{ Name='Recipients'; Expression={ [string]::join(';', $_.Recipients) } },
                MessageSubject, EventID, ServerHostname |
            Sort-Object $Sort

        if ($ausgabe) {
            $array.AddRange($ausgabe)
            $dgResults.DataSource = $array
            $array | Export-Csv 'MessageTrackingGUI.log' -NoTypeInformation
            if ($chkBoxCSV.Checked)  { $array | Export-Csv $txtBoxCSV.Text -NoTypeInformation }
            if ($chkBoxMail.Checked) {
                Send-MailMessage -To $txtBoxToMail.Text -From $txtBoxFromMail.Text `
                    -Subject "Exchange Message Tracking $(Get-Date -Format 'HH:mm-MM.dd.yyyy')" `
                    -Body 'Attached is the message tracking log.' `
                    -Attachments 'MessageTrackingGUI.log' -BodyAsHtml `
                    -SmtpServer $txtBoxMail.Text
            }
            $formTrackLog.Refresh()
        } else {
            Write-Host 'No results found.' -ForegroundColor White -BackgroundColor Red
        }
    }

    $handler_comboBoxEventID_SelectedIndexChanged = {
        $Global:ChoiceEventID = $comboBoxEventID.SelectedItem.ToString()
    }
    $OnLoadForm_StateCorrection = { $formTrackLog.WindowState = $InitialFormWindowState }

    $formTrackLog.ClientSize = '1000,550'
    $formTrackLog.Text       = 'Message Tracking Log Search'

    # --- Controls layout ---
    $labFrom.Text = 'From:';      $labFrom.Location = '3,5';     $labFrom.Size = '54,20';     $formTrackLog.Controls.Add($labFrom)
    $labTo.Text   = 'To:';       $labTo.Location   = '3,32';    $labTo.Size   = '54,20';     $formTrackLog.Controls.Add($labTo)
    $labSubject.Text = 'Subject:'; $labSubject.Location = '3,67'; $labSubject.Size = '54,20'; $formTrackLog.Controls.Add($labSubject)
    $labStartDate.Text = 'Start'; $labStartDate.Location = '300,5';  $labStartDate.Size = '54,20'; $formTrackLog.Controls.Add($labStartDate)
    $labEndDate.Text   = 'End';   $labEndDate.Location   = '300,33'; $labEndDate.Size   = '54,20'; $formTrackLog.Controls.Add($labEndDate)
    $labEventID.Text   = 'Event ID:'; $labEventID.Location = '570,5'; $labEventID.Size = '60,23'; $formTrackLog.Controls.Add($labEventID)

    $txtBoxSenders.Location    = '40,3';   $txtBoxSenders.Size    = '250,20'; $formTrackLog.Controls.Add($txtBoxSenders)
    $txtBoxRecipients.Location = '40,30';  $txtBoxRecipients.Size = '250,20'; $formTrackLog.Controls.Add($txtBoxRecipients)
    $txtBoxSubject.Location    = '65,65';  $txtBoxSubject.Size    = '495,20'; $formTrackLog.Controls.Add($txtBoxSubject)
    $dateTimePickerStart.Location = '360,3';  $dateTimePickerStart.Size = '200,20'; $formTrackLog.Controls.Add($dateTimePickerStart)
    $dateTimePickerEnd.Location   = '360,33'; $dateTimePickerEnd.Size   = '200,20'; $formTrackLog.Controls.Add($dateTimePickerEnd)

    foreach ($id in @('','SEND','DELIVER','RECEIVE','FAIL','DSN','RESOLVE','EXPAND','REDIRECT','TRANSFER','SUBMIT','POISONMESSAGE','DEFER')) {
        $comboBoxEventID.Items.Add($id) | Out-Null
    }
    $comboBoxEventID.Location = '630,3'; $comboBoxEventID.Size = '121,21'
    $comboBoxEventID.add_SelectedIndexChanged($handler_comboBoxEventID_SelectedIndexChanged)
    $formTrackLog.Controls.Add($comboBoxEventID)

    $buttonGo.Text     = '>>> Run <<<'; $buttonGo.Location = '755,3'; $buttonGo.Size = '240,25'
    $buttonGo.add_Click($processData)
    $formTrackLog.Controls.Add($buttonGo)

    $chkBoxMail.Text = 'Send by mail'; $chkBoxMail.Location = '570,34'; $chkBoxMail.Size = '90,24'; $formTrackLog.Controls.Add($chkBoxMail)
    $chkBoxCSV.Text  = 'Export CSV';   $chkBoxCSV.Location  = '570,64'; $chkBoxCSV.Size  = '84,24'; $formTrackLog.Controls.Add($chkBoxCSV)
    $txtBoxMail.Text = 'SMTP Server';  $txtBoxMail.Location = '660,34'; $txtBoxMail.Size = '110,20'; $formTrackLog.Controls.Add($txtBoxMail)
    $txtBoxFromMail.Text = 'From';     $txtBoxFromMail.Location = '775,34'; $txtBoxFromMail.Size = '110,20'; $formTrackLog.Controls.Add($txtBoxFromMail)
    $txtBoxToMail.Text   = 'To';       $txtBoxToMail.Location   = '890,34'; $txtBoxToMail.Size   = '110,20'; $formTrackLog.Controls.Add($txtBoxToMail)
    $txtBoxCSV.Text = 'Path to csv';   $txtBoxCSV.Location = '660,65'; $txtBoxCSV.Size = '250,20'; $formTrackLog.Controls.Add($txtBoxCSV)

    $dgResults.AllowSorting       = $true
    $dgResults.Anchor             = 15
    $dgResults.Location           = '9,108'
    $dgResults.Size               = '990,500'
    $dgResults.PreferredColumnWidth = 200
    $dgResults.ReadOnly           = $true
    $dgResults.RowHeadersVisible  = $false
    $formTrackLog.Controls.Add($dgResults)

    $InitialFormWindowState = $formTrackLog.WindowState
    $formTrackLog.add_Load($OnLoadForm_StateCorrection)
    $formTrackLog.ShowDialog() | Out-Null
}

GenerateForm
