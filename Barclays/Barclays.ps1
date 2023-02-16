Get-ChildItem -filter *.pdf | Where-Object {$_.LastWriteTime -ge "2022-10-01"} | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -raw -enc UTF-8 -bom -q ${filename} - | Out-String

    # if (${textContent} -NotMatch "Barclay") {
    #     Write-Host "No Barclays statement. Skipping ${filename}"
    #     Return
    # }

    if ( ${textContent} -cmatch "(?s).*Kontoübersicht vom (\d+)\. ([A-Za-zä]+) (\d{4}).*") {
    
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
    
    $statementAmount = ${textContent} -replace "(?s).*Neuer Saldo [^\n]+ ([0-9.,]+)(\+?)-?\r\n.*", '$2$1'
    if ( ${textContent} -cmatch "(?s).*Gesamt \(EUR\) [^\n]+ ([0-9.,]+).*" ) {
        $payAmount = $matches[1]
        $payString = " einzahlen ${payAmount}€"
    }
    else {
        $payString = ""
    }
    $newFilename = "${statementDate} 01 Kontoübersicht ${statementAmount}€${payString}.pdf"

    # Write-Host "Date:   $statementDate"
    # Write-Host "Amount: $statementAmount"
    # Write-Host "Pay:    $payAmount"
    # Write-Host "OLD:    $filename"
    # Write-Host "NEW:    $newFilename"

    if (-not ${statementDate} -or -not ${statementAmount}) {
        Write-Host "Missing values. Skipping ${filename}"
        Return
    }

    if (${newFilename} -eq ${filename}) {
        Write-Host "Correct name. Skipping ${filename}"
        Return
    }

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

