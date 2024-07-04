[CmdletBinding()]
Param()

Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -layout ${filename} - | Out-String

    $transactionDate = if ($textContent -cmatch 'Buchungstag\s+(\d{2})\.(\d{2})\.(\d{4})' ) {
        $day, $month, $year = $matches[1], $matches[2], $matches[3]
        "${year}-${month}-${day}"
    }
    
    $signum, $amount = if ($textContent -cmatch 'Betrag\s+(\+|\-)((?:\d|\.)+,\d{2})') {
        $matches[1], $matches[2]
    }
    
    $note = if ($textContent -cmatch 'Verwendungszweck\s+([^\r\n]+)') {
        if ($matches[1] -ne '-') { $matches[1] } else { '' }
    }
        
    $transaction = if ($textContent -cmatch 'Buchungstext\s+([^\r\n]+)') {
        @{
            'Gutschrift aus Dauerauftrag'       = 'Gutschrift'
            'Gutschrift'                        = 'Gutschrift'
            'Lastschrift'                       = 'Lastschrift'
            'Dauerauftrag / Terminueberweisung' = 'Überweisung'
            'Entgelt'                           = 'Entgelt'
        }[$matches[1]]
    }
    
    if (-not $transactionDate -or -not $signum -or -not $amount -or $note -eq $null -or -not $transaction) {
        Write-Host "Skipping $filename"
        Return
    }    

    Write-Verbose "file: $filename"
    Write-Verbose "transactionDate: $transactionDate"
    Write-Verbose "signum: $signum"
    Write-Verbose "amount: $amount"
    Write-Verbose "note: $note"
    Write-Verbose "transaction: $transaction"

    $newFilename = "${transactionDate} 01 ${transaction} ${note} ${amount}€.pdf"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

