// Investigation 2c (spec 004): does Equatable change when an @Observable property notifies?
// Run:  swiftc -O -swift-version 5 observation-equatable.swift -o /tmp/observation-equatable && /tmp/observation-equatable
import Observation

struct EquatableData: Equatable { var title: String }
struct PlainData { var title: String }          // not Equatable

@Observable final class EquatableModel { var data = EquatableData(title: "A") }
@Observable final class PlainModel { var data = PlainData(title: "A") }

final class FiredFlag: @unchecked Sendable { var value = false }

func fired(_ read: () -> Void, after change: () -> Void) -> Bool {
    let flag = FiredFlag()
    withObservationTracking({ read() }, onChange: { flag.value = true })
    change()
    return flag.value
}

let equatableModel = EquatableModel()
let plainModel = PlainModel()
print("Equatable value, assigned an EQUAL value:   ", fired({ _ = equatableModel.data }, after: { equatableModel.data = EquatableData(title: "A") }) ? "FIRED" : "did not fire")
print("Equatable value, assigned a DIFFERENT value:", fired({ _ = equatableModel.data }, after: { equatableModel.data = EquatableData(title: "B") }) ? "FIRED" : "did not fire")
print("Non-Equatable value, assigned an EQUAL value:   ", fired({ _ = plainModel.data }, after: { plainModel.data = PlainData(title: "A") }) ? "FIRED" : "did not fire")
print("Non-Equatable value, assigned a DIFFERENT value:", fired({ _ = plainModel.data }, after: { plainModel.data = PlainData(title: "B") }) ? "FIRED" : "did not fire")
