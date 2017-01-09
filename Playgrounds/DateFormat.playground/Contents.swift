import Foundation
import JoshLib


let date = Date()

print(date.format(as: .iso8601))
print(date.format(as: .littleEndian))
print(date.format(as: .sortable))
print(date.format(as: .short))
print(date.format(as: .medium))
print(date.format(as: .full))

let greatBritainLocale = Locale(identifier: "en_GB")


print(date.format(as: .short, with: greatBritainLocale))
