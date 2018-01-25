//
//  FromRouter.swift
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 3/20/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

import Foundation


/// FromRouter for creating and chaning a query FROM clause.
public protocol FromRouter {
    
    /// Create and chain a FROM clause component to specify a data source of the query.
    ///
    /// - Parameter dataSource: The DataSource object.
    /// - Returns: The From object that represent the FROM clause of the query.
    func from(_ dataSource: DataSourceProtocol) -> From
    
}


