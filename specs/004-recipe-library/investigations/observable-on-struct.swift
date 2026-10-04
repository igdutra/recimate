// Investigation 2a (spec 004): can @Observable be applied to a struct?
// Run:  swiftc -typecheck -swift-version 6 observable-on-struct.swift
// Expected: error: '@Observable' cannot be applied to struct type 'CardViewData'
import Observation

@Observable struct CardViewData { var title = "" }
