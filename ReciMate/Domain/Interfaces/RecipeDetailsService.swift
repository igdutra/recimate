//
//  RecipeDetailsService.swift
//  ReciMate
//
//  Created by Ivo on 04/10/26.
//

import Foundation

protocol RecipeDetailsService: Sendable {
    func loadRecipe(id: String) async throws -> RecipeDetails
}
