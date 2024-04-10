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

public struct MJModel: ExtensionMacro, MemberMacro {

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
        // TODO: diagnostic do not implement `init(from:)` or `encode(to:))`
        
        let propertyContainer = try ModelMemberPropertyContainer(decl: declaration, context: context)
        let objectClassInArray = try propertyContainer.genObjectClassInArray()
        let replacedKey = try propertyContainer.genReplacedKey()
        let ignored = try propertyContainer.genIgnored()
        return [objectClassInArray, replacedKey, ignored]
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
