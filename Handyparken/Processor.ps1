﻿Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext.exe -enc UTF-8 -bom -layout ${filename} - | Out-String

    if ( ${textContent} -cmatch "(?s).*Bestellnummer:\W*([A-Z0-9]+).*") {
        $invoiceNumber = $matches[1]
    }
    if ( ${textContent} -cmatch "(?s).*Gültig ab:\W*([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*") {;
        $invoiceYear = $matches[3]
        $invoiceMonth = $matches[2]
        $invoiceDay = $matches[1]

        $invoiceDate =  ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
    }
    
    if ( ${textContent} -cmatch "(?s).*Betrag:\W*([0-9]+,[0-9][0-9]).*") { 
        $invoiceAmount = $matches[1] 
    }
    
    if ( ${textContent} -cmatch "(?s).*Parkscheinautomat:\W*[0-9]+,\W*([A-Za-zÄÖÜäoüß.]+).*") { 
        $parkingLocation = $matches[1]
    }

    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount} -or -not ${parkingLocation}) {
        Write-Host "Invalid data. Ignoring ${filename}"
        Return
    }

    "`"${invoiceNumber}`";`"${invoiceDay}.${invoiceMonth}`";`"Parken Projektarbeit`";`"${invoiceAmount}`"" | Out-File -Append -FilePath list.csv 

    $index = 0;
    do {
        ${index}++

        $newFilename = "${invoiceDate} 0${index} Rechnung Parken Projektarbeit ${parkingLocation} ${invoiceNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Host "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

