import SwiftSyntax

extension VariableDeclSyntax {
    /// Determine whether this variable has the syntax of a stored property.
    ///
    /// This syntactic check cannot account for semantic adjustments due to,
    /// e.g., accessor macros or property wrappers.
    var isStoredProperty: Bool {
        if modifiers.compactMap({ $0.as(DeclModifierSyntax.self) }).contains(where: { $0.name.text == "static" }) {
            return false
        }
        if bindings.count < 1 {
            return false
        }
        let binding = bindings.last!
        switch binding.accessorBlock?.accessors {
        case .none:
            return true
        case let .accessors(o):
            for accessor in o {
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // Observers can occur on a stored property.
                    break
                default:
                    // Other accessors make it a computed property.
                    return false
                }
            }
            return true
        case .getter:
            return false
        }
    }

    var inferType: String? {
        var type = bindings.compactMap(\.typeAnnotation).first?.type.description
        // try infer type
        if type == nil, let initExpr = bindings.compactMap(\.initializer).first?.value {
            if initExpr.is(StringLiteralExprSyntax.self) {
                type = "String"
            } else if initExpr.is(IntegerLiteralExprSyntax.self) {
                type = "Int"
            } else if initExpr.is(FloatLiteralExprSyntax.self) {
                type = "Double"
            } else if initExpr.is(BooleanLiteralExprSyntax.self) {
                type = "Bool"
            }
        }
        return type
    }
      
    var typeInArray: String? {
        if let array = bindings.compactMap(\.typeAnnotation).first?.type.as(ArrayTypeSyntax.self) {
            if array.element.is(ArrayTypeSyntax.self),
               array.element.is(DictionaryTypeSyntax.self)
            {
                return nil
            }
            let a: UInt8
            let type = array.element.description
            if ["Bool","Int","Int8","Int16","Int32","Int64","UInt","UInt8","UInt16","UInt32","UInt64","Float","Double","String","TimeInterval"].contains(type)
            {
                return nil
            }
            return type
        }
        return nil
    }

    var isOptionalType: Bool {
        if bindings.compactMap(\.typeAnnotation).first?.type.is(OptionalTypeSyntax.self) == true {
            return true
        }
        if bindings.compactMap(\.initializer).first?.value.as(DeclReferenceExprSyntax.self)?.description.hasPrefix("Optional<") == true {
            return true
        }
        if bindings.compactMap(\.initializer).first?.value.as(DeclReferenceExprSyntax.self)?.description.hasPrefix("Optional(") == true {
            return true
        }
        return false
    }
}
