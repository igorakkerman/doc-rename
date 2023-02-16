[CmdletBinding()]
Param()

Get-ChildItem -filter *.pdf | Where-Object { $_.LastWriteTime -ge "2022-10-01" } | ForEach-Object {
    Clear-Variable -name ("statement*", "pay*")

    $filename = $_.Name
    Write-Verbose "Processing file '$filename'."

    $textContent = pdftotext -raw -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "Barclays Bank Ireland PLC") {
        Write-Verbose "No Barclays statement. Skipping ${filename}"
        Return
    }

    if ( ${textContent} -cmatch "(?s).*Kontoauszug vom (\d+)\. ([A-Za-zä]+) (\d{4}).*") {
    
        $statementDay = "{0:00}" -f [int]$matches[1]
        $statementMonthText = $matches[2]
        $statementYear = $matches[3]

        $statementMonth = switch ($statementMonthText) {
            "Januar" { "01" }
            "Februar" { "02" }
            "März" { "03" }
            "April" { "04" }
            "Mai" { "05" }
            "Juni" { "06" }
            "Juli" { "07" }
            "August" { "08" }
            "September" { "09" }
            "Oktober" { "10" }
            "November" { "11" }
            "Dezember" { "12" }
            Default { "ERROR" }
        }

        $statementDate = ${statementYear} + "-" + ${statementMonth} + "-" + ${statementDay}
    }
    
    if (${textContent} -cmatch "(?s).*Gesamt \(EUR\) ([0-9.,]+)\s*([+-])(?: ([0-9.,]+))?.*") {
        $statementAmount = $matches[1]
        $sign = $matches[2]
        $payAmount = $matches[3]
        $payAmountString = if ($payAmount) { " einzahlen ${payAmount}€" } else { "" }
    }

    $newFilename = "${statementDate} 01 Kontoauszug ${sign}${statementAmount}€${payAmountString}.pdf"

    Write-Verbose "Date:   $statementDate"
    Write-Verbose "Amount: $sign$statementAmount"
    Write-Verbose "Pay:    $($payAmount ?? "n/a")"
    Write-Verbose "OLD:    $filename"
    Write-Verbose "NEW:    $newFilename"

    if (-not ${statementDate} -or -not ${statementAmount}) {
        Write-Output "Missing values. Skipping '${filename}'"
        Return
    }

    if (${newFilename} -eq ${filename}) {
        Write-Verbose "Correct name. Skipping ${filename}"
        Return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

