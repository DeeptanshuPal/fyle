//
//  PDFHelper.swift
//  fyle
//
//  Created by Sana Sreeraj on 12/11/24.
//

import UIKit
import PDFKit

struct PDFHelper {
    static func saveImagesAsPDF(images: [UIImage], pdfName: String) -> URL? {
        let pdfFilePath = getDocumentsDirectory().appendingPathComponent("\(pdfName).pdf")
        
        UIGraphicsBeginPDFContextToFile(pdfFilePath.path, CGRect.zero, nil)
        
        for image in images {
            let pdfPageBounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            UIGraphicsBeginPDFPageWithInfo(pdfPageBounds, nil)
            image.draw(in: pdfPageBounds)
        }
        
        UIGraphicsEndPDFContext()
        print("PDF created at: \(pdfFilePath)")
        
        return pdfFilePath
    }

    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

