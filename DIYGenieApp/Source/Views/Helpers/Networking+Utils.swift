//
//  Networking+Utils.swift
//  DIYGenieApp
//

import Foundation

extension Error {
    /// True when this error is just a cancelled URLSession task (NSURLError -999).
    var isURLCancelled: Bool {
        let ns = self as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }
}

