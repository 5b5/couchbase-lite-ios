//
//  Where.swift
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 3/20/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

import Foundation


public protocol Where: QueryProtocol, GroupByRouter, OrderByRouter, LimitRouter {
    
}

/// Where class represents the WHERE clause of the query statement.
class QueryWhere: BaseQuery, Where {
    
    /// Create and chain an ORDER BY component for specifying the orderings of the query result.
    ///
    /// - Parameter orderings: The ordering objects.
    /// - Returns: The OrderBy object.
    public func orderBy(_ orderings: OrderingProtocol...) -> OrderBy {
        return QueryOrderBy(query: self, impl: QueryOrdering.toImpl(orderings: orderings))
    }
    
    
    /// Create and chain a GROUP BY component to group the query result.
    ///
    /// - Parameter expressions: The expression objects.
    /// - Returns: The GroupBy object.
    public func groupBy(_ expressions: ExpressionProtocol...) -> GroupBy {
        return QueryGroupBy(query: self, impl: QueryExpression.toImpl(expressions: expressions))
    }
    
    
    /// Create and chain a LIMIT component to limit the number query results.
    ///
    /// - Parameter limit: The limit Expression object or liternal value.
    /// - Returns: The Limit object.
    public func limit(_ limit: ExpressionProtocol) -> Limit {
        return self.limit(limit, offset: nil)
    }
    
    
    /// Create and chain a LIMIT component to skip the returned results for the given offset
    /// position and to limit the number of results to not more than the given limit value.
    ///
    /// - Parameters:
    ///   - limit: The limit Expression object or liternal value.
    ///   - offset: The offset Expression object or liternal value.
    /// - Returns: The Limit object.
    public func limit(_ limit: ExpressionProtocol, offset: ExpressionProtocol?) -> Limit {
        return QueryLimit(query: self, limit: limit, offset: offset)
    }
    
    
    /// An internal constructor.
    init(query: BaseQuery, impl: CBLQueryExpression) {
        super.init()
        
        self.copy(query)
        self.whereImpl = impl
    }
    
}
