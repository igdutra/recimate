//
//  RRecipeListService.swift
//  ReciMate
//
//  Created by Ivo on 04/10/26.
//

import Foundation

protocol RecipeListService: Sendable {
    /// The recipe collection, narrowed by the query. `.empty` returns every recipe.
    func loadRecipes(matching query: RecipeSearchQuery) async throws -> [RecipePreview]
}
