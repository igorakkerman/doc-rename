Get-ChildItem -filter *.pdf | Where-Object { $_.LastWriteTime -ge "2020-04-01" } | ForEach-Object -Parallel {
    $filename = $_.Name
    
    $textContent = pdftotext.exe -raw -enc UTF-8 -q ${filename} - | Out-String

    if (${textContent} -NotMatch "SHARE NOW") {
        Write-Verbose "Ignoring ${filename}"
        Return
    }

    if ( ${textContent} -cmatch "(?s).*\r\n([0-9]+)\r\nRechnungsnr.*") {
        $invoiceNumber = $matches[1]
    }
    if ( ${textContent} -cmatch "(?s)Leistungszeitraum von:\s*([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*") {;
        $invoiceYear = $matches[3]
        $invoiceMonth = $matches[2]
        $invoiceDay = $matches[1]

        $invoiceDate =  ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
    }
    
    if ( ${textContent} -cmatch "Gesamtbetrag.* ([0-9]+,[0-9][0-9])") { 
        $invoiceAmount = $matches[1] 
    }
   
    Write-Verbose "Date:   ${invoiceDate}"
    Write-Verbose "Amount: ${invoiceAmount}"
    Write-Verbose "Number: ${invoiceNumber}"

    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid data. Ignoring ${filename}"
        Return
    }

#     "`"${invoiceNumber}`";`"${invoiceDay}.${invoiceMonth}`";`"ShareNow`";`"${invoiceAmount}`"" | Out-File -Append -FilePath list.csv 

    $index = 0;
    do {
        ${index}++

        $newFilename = "${invoiceDate} 0${index} Rechnung SHARE NOW ${invoiceNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Output "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

