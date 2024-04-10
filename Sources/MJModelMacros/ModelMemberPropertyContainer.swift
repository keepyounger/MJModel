import SwiftSyntax
import SwiftSyntaxMacros

private struct ModelMemberProperty {
    var name: String
    var type: String
    var typeInArray: String = ""
    var normalKeys: [String] = []
    var isIgnored: Bool = false

    var codingKeys: [String] {
        let raw = ["\"\(name)\""]
        if normalKeys.isEmpty {
            return raw
        }
        return raw + normalKeys
    }
}

struct ModelMemberPropertyContainer {
    
    let context: MacroExpansionContext
    fileprivate let decl: DeclGroupSyntax
    fileprivate var memberProperties: [ModelMemberProperty] = []

    init(decl: DeclGroupSyntax, context: some MacroExpansionContext) throws {
        self.decl = decl
        self.context = context
        memberProperties = try fetchModelMemberProperties()
    }
    
    func genObjectClassInArray() throws -> DeclSyntax {
        
        var body: [String] = []
        for member in memberProperties where !member.typeInArray.isEmpty {
            let element = """
            "\(member.name)": \(member.typeInArray).classForCoder()
            """
            body.append(element)
        }
        
        if body.isEmpty {
            body.append(":")
        }
        
        let decoder: DeclSyntax = """
        static override func mj_objectClassInArray() -> [AnyHashable : Any]! {
            return [\(raw: body.joined(separator: ", "))]
        }
        """
        
        return decoder
    }
    
    func genReplacedKey() throws -> DeclSyntax {
        var body: [String] = []
        for member in memberProperties where !member.normalKeys.isEmpty {
            let element = """
            "\(member.name)": [\(member.codingKeys.joined(separator: ", "))]
            """
            body.append(element)
        }
        
        if body.isEmpty {
            body.append(":")
        }
        
        let decoder: DeclSyntax = """
        static override func mj_replacedKeyFromPropertyName() -> [AnyHashable : Any]! {
            return [\(raw: body.joined(separator: ", "))]
        }
        """
        
        return decoder
    }
    
    func genIgnored() throws -> DeclSyntax {
        var body: [String] = []
        for member in memberProperties where member.isIgnored {
            let element = """
            "\(member.name)"
            """
            body.append(element)
        }
        let decoder: DeclSyntax = """
        static override func mj_ignoredPropertyNames() -> [Any]! {
            return [\(raw: body.joined(separator: ", "))]
        }
        """
        
        return decoder
    }
}

private extension ModelMemberPropertyContainer {
    func fetchModelMemberProperties() throws -> [ModelMemberProperty] {
        let memberList = decl.memberBlock.members
        let memberProperties = try memberList.flatMap { member -> [ModelMemberProperty] in
            guard let variable = member.decl.as(VariableDeclSyntax.self), variable.isStoredProperty else {
                return []
            }
            let patterns = variable.bindings.map(\.pattern)
            let names = patterns.compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
            return try names.map { name -> ModelMemberProperty in
                guard let type = variable.inferType else {
                    throw ASTError("please declare property type: \(name)")
                }

                var mp = ModelMemberProperty(name: name, type: type)
                mp.typeInArray = variable.typeInArray ?? ""
                let attributes = variable.attributes

                // MJModelKey
                if let customKeyMacro = attributes.first(where: { element in
                    element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "MJModelKey"
                }) {
                    mp.normalKeys = customKeyMacro.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.compactMap { $0.expression.description } ?? []
                }
                
                // MJModelIgnore
                if let customKeyMacro = attributes.first(where: { element in
                    element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "MJModelIgnore"
                }) {
                    mp.isIgnored = true
                }
                
                return mp
            }
        }
        return memberProperties
    }
}
