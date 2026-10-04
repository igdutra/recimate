//
//  RRecipeListService.swift
//  ReciMate
//
//  Created by Ivo on 04/10/26.
//

import Foundation

protocol RecipeListService: Sendable {
    func loadRecipes() async throws -> [RecipePreview]
}
