//
//  PTJavaScriptExecutor.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/18/20.
//

import Foundation

public extension PTJavaScriptExecutor {
    /// 同步执行脚本
    /// - Parameter object: 脚本对象
    /// - Returns: 回执
    func evaluate(scriptObject object: JavaScript) -> JavaScriptRecipe {
        atomicEvaluate(object: object)
    }

    /// 异步执行
    /// - Parameters:
    ///   - object: 代码对象
    ///   - queue: 队列
    ///   - completion: 完成回掉
    /// - Returns: void
    func evaluateAsync(scriptObject object: JavaScript,
                       queue: DispatchQueue
                           = DispatchQueue(label: "wiki.qaq.PillowTalk.PTJavaScriptExecutor"),
                       completion: @escaping (JavaScriptRecipe) -> Void)
    {
        queue.async {
            completion(self.atomicEvaluate(object: object))
        }
    }
}
