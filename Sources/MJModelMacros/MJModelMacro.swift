import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MJModelKey: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        return []
    }
}

public struct MJModelIgnore: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        return []
    }
}

public struct MJModel: ExtensionMacro, MemberMacro, MemberAttributeMacro {

    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        var inheritedTypes: InheritedTypeListSyntax?
        if let declaration = declaration.as(ClassDeclSyntax.self) {
            inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        } else {
            throw ASTError("use @MJModel in `class` inherited NSObject")
        }
        if let inheritedTypes = inheritedTypes, !inheritedTypes.contains(where: { inherited in inherited.type.trimmedDescription == "NSObject" })
        {
            throw ASTError("use @MJModel in `class` inherited NSObject")
        }
        return []
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        var decls: [DeclSyntax] = []
        let propertyContainer = try ModelMemberPropertyContainer(decl: declaration, context: context)
        if let objectClassInArray = try propertyContainer.genObjectClassInArray() {
            decls.append(objectClassInArray)
        }
        if let replacedKey = try propertyContainer.genReplacedKey() {
            decls.append(replacedKey)
        }
        if let ignored = try propertyContainer.genIgnored() {
            decls.append(ignored)
        }
        return decls
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
        return ["@objc"]
    }
    
}

@main
struct MJModelPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MJModel.self,
        MJModelKey.self,
        MJModelIgnore.self
    ]
}
