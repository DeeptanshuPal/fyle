//
//  PDFHelper.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import UIKit
import PDFKit

class PDFHelper {
    
    // Function to save an array of images as a single PDF
    func saveImagesAsPDF(images: [UIImage]) -> URL {
        let pdfDocument = PDFDocument()
        
        for image in images {
            let pdfPage = PDFPage(image: image)!
            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }
        
        // Save the generated PDF to the document directory
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsURL.appendingPathComponent("file.pdf")
        
        pdfDocument.write(to: pdfURL)
        
        return pdfURL
    }
}
