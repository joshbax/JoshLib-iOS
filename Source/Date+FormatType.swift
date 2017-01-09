import Foundation

public enum DateFormatType {
    case iso8601
    case littleEndian
    case sortable
    case short
    case medium
    case full
    
    var formatString : String {
        switch self {
        case .iso8601: return "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        case .littleEndian: return "dd-MM-yyyy"
        case .sortable: return "yyyyMMddHHmmssSSS"
        case .short: return "M/d/yy"
        case .medium: return "MMM d, yyyy"
        case .full: return "EEEE, MMMM d, yyyy"
        }
    }
    
    var dateFormatterStyle : DateFormatter.Style? {
        switch self {
        case .full: return DateFormatter.Style.full
        case .medium: return DateFormatter.Style.medium
        case .short: return DateFormatter.Style.short
        case .sortable: fallthrough
        case .littleEndian: fallthrough
        case .iso8601:
            return nil
        }
    }
}

extension Date {
    
    public func format(as formatType: DateFormatType, with locale: Locale = Locale(identifier: "en_US_POSIX")) -> String {
        let dateFormatter = DateFormatter()
        if let formatStyle = formatType.dateFormatterStyle {
            dateFormatter.dateStyle = formatStyle
        } else {
            dateFormatter.dateFormat = formatType.formatString
        }
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
    
}

